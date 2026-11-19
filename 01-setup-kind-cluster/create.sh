#!/usr/bin/env bash
# create-cluster.sh — create a kind cluster (1 control-plane + 2 workers) with the
# default CNI disabled, then install Cilium as the CNI.
# Usage: bash create.sh [cluster-name] [cilium-version] [k8s-version]
#
# Requires ROOTFUL Docker. kind node containers need real privileges to mount
# bpffs (/sys/fs/bpf). Under rootless Docker, Cilium's mount-bpf-fs init
# container fails with "mount: /sys/fs/bpf: permission denied".
set -euo pipefail

NAME="${1:-cilium-lab}"
CILIUM_VERSION="${2:-${CILIUM_VERSION:-1.20.5}}"
K8S_VERSION="${3:-v1.37.0}"

# Resolve to the script's directory so relative paths work from any CWD
cd "$(dirname "$0")"

# --- Guard: refuse to run on rootless Docker ---
if docker info 2>/dev/null | grep -qi 'rootless'; then
  echo "ERROR: rootless Docker detected."
  echo "kind + Cilium requires rootful Docker (rootless cannot mount bpffs)."
  echo "Fix: docker context use default && sudo systemctl start docker"
  exit 1
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
