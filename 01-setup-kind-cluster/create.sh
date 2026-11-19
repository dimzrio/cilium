#!/usr/bin/env bash
# create-cluster.sh — create a kind cluster (1 control-plane + 2 workers) with the
# default CNI disabled, then install Cilium as the CNI.
# Usage: ./create.sh [cluster-name] [cilium-version] [k8s-version] [--keep]
#
# Requires ROOTFUL Docker: kind nodes must mount bpffs (/sys/fs/bpf), which
# rootless Docker cannot do (this machine runs rootful only).
#
# A same-named cluster is deleted and recreated automatically, so a plain
# `./create.sh` always yields a clean cluster. Pass --keep to abort instead of
# deleting an existing cluster.
set -euo pipefail

# --- Parse args (positional + optional flags) ---
ARGS=(); KEEP=0
for a in "$@"; do
  case "$a" in
    --keep) KEEP=1 ;;          # abort if a same-named cluster already exists
    --recreate|-f) ;;          # accepted for backward compat; recreate is default
    *) ARGS+=("$a") ;;
  esac
done
NAME="${ARGS[0]:-cilium-lab}"
CILIUM_VERSION="${ARGS[1]:-${CILIUM_VERSION:-1.20.5}}"
K8S_VERSION="${ARGS[2]:-v1.37.0}"

# Resolve to the script's directory so relative paths work from any CWD
cd "$(dirname "$0")"

# --- Docker: Cilium needs the rootful daemon (real bpffs mounts) ---
# Clear any stale DOCKER_HOST (e.g. an old shell still pointing at the removed
# rootless socket) and force the rootful 'default' context.
unset DOCKER_HOST
export DOCKER_CONTEXT=default

if docker info 2>/dev/null | grep -qi 'rootless'; then
  echo "ERROR: active Docker daemon is rootless — Cilium cannot mount bpffs."
  echo "Use rootful: sudo systemctl start docker && docker context use default"
  exit 1
fi

# --- Recreate by default: delete any existing same-named cluster ---
if kind get clusters 2>/dev/null | grep -qx "${NAME}"; then
  if [[ "${KEEP}" == "1" ]]; then
    echo "ERROR: cluster '${NAME}' already exists (--keep)."
    echo "Delete it first, or drop --keep to recreate automatically."
    exit 1
  fi
  echo "Cluster '${NAME}' already exists — deleting to recreate cleanly..."
  kind delete cluster --name "${NAME}"
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
