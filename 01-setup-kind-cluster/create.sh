#!/usr/bin/env bash
# create-cluster.sh — create a kind cluster (1 control-plane + 2 workers) with the
# default CNI disabled, then install Cilium as the CNI.
# Usage: bash create.sh [cluster-name] [cilium-version] [k8s-version] [--recreate]
#
# Requires ROOTFUL Docker. kind node containers need real privileges to mount
# bpffs (/sys/fs/bpf). Under rootless Docker, Cilium's mount-bpf-fs init
# container fails with "mount: /sys/fs/bpf: permission denied".
#
# If a cluster with the same name already exists, the script aborts unless
# --recreate is passed (which deletes it first). Re-running over an existing
# cluster leaves orphaned Cilium containers holding a shared bpffs mount, which
# makes the new agent's mount-bpf-fs fail with EPERM -> Init:CrashLoopBackOff.
set -euo pipefail

# --- Parse args (positional + optional --recreate) ---
ARGS=(); RECREATE=0
for a in "$@"; do
  case "$a" in
    --recreate|-f) RECREATE=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
NAME="${ARGS[0]:-cilium-lab}"
CILIUM_VERSION="${ARGS[1]:-${CILIUM_VERSION:-1.20.5}}"
K8S_VERSION="${ARGS[2]:-v1.37.0}"

# Resolve to the script's directory so relative paths work from any CWD
cd "$(dirname "$0")"

# --- Cilium requires ROOTFUL Docker ---
# A shell that sources ~/.bashrc may export DOCKER_HOST pointing at the rootless
# socket ($XDG_RUNTIME_DIR/docker.sock), which cannot mount bpffs. DOCKER_HOST
# overrides `docker context`, so we must unset it and force the default context.
if [[ -n "${DOCKER_HOST:-}" ]]; then
  echo "Ignoring DOCKER_HOST=${DOCKER_HOST} (forcing rootful 'default' context)."
fi
unset DOCKER_HOST
export DOCKER_CONTEXT=default

if docker info 2>/dev/null | grep -qi 'rootless'; then
  echo "ERROR: the Docker daemon is rootless — Cilium cannot mount bpffs."
  echo "Start/use the rootful daemon:"
  echo "  sudo systemctl start docker && docker context use default"
  exit 1
fi

# --- Guard: never run 'kind create' over an existing cluster ---
if kind get clusters 2>/dev/null | grep -qx "${NAME}"; then
  if [[ "${RECREATE}" == "1" ]]; then
    echo "Existing cluster '${NAME}' found — recreating (--recreate)..."
    kind delete cluster --name "${NAME}"
  else
    echo "ERROR: kind cluster '${NAME}' already exists."
    echo "Re-running over it leaves orphaned Cilium containers and a stale"
    echo "shared bpffs mount, which breaks the new agent (mount-bpf-fs EPERM)."
    echo "Recreate cleanly with:"
    echo "  bash $0 ${NAME} ${CILIUM_VERSION} ${K8S_VERSION} --recreate"
    exit 1
  fi
fi

echo "[1/5] Creating kind cluster '${NAME}' (1 control-plane + 2 workers)..."
kind create cluster \
  --name "${NAME}" \
  --config config/kind-cluster.yaml \
  --image "kindest/node:${K8S_VERSION}"

echo "[2/5] Installing Cilium (Helm) v${CILIUM_VERSION}..."
API_SERVER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${NAME}-control-plane")
API_SERVER_PORT=6443
echo "  API server: ${API_SERVER_IP}:${API_SERVER_PORT}"

helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium \
  --namespace kube-system \
  --version "${CILIUM_VERSION}" \
  --set image.pullPolicy=IfNotPresent \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost="${API_SERVER_IP}" \
  --set k8sServicePort="${API_SERVER_PORT}"

echo "[3/5] Waiting for Cilium DaemonSet to roll out..."
kubectl -n kube-system rollout status ds/cilium --timeout=600s

echo "[4/5] Applying LB IP pools (CiliumLoadBalancerIPPool CRDs)..."
kubectl apply -f config/cilium-lb-ip-pools.yaml

echo "[5/5] Verifying Cilium status..."
cilium status --namespace kube-system

echo "Done."
