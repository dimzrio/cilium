#!/usr/bin/env bash
# create-cluster.sh — create a kind cluster: 1 control-plane + 2 workers.
# Usage: bash create.sh [cluster-name]
set -euo pipefail

NAME="${1:-cilium-lab}"

echo "[1/3] Creating kind cluster '${NAME}'..."
kind create cluster \
  --name "${NAME}" \
  --config 01-setup-kind-cluster/kind-cluster.yaml \
  --image kindest/node:${K8S_VERSION:-"1.31.0"}

echo "[2/3] Waiting for control-plane to be ready..."
kubectl get nodes --no-headers -o wide | while read -r line; do
  kubectl get node "$(echo "$line" | awk '{print $1}')" 2>/dev/null || true
done

# Wait for all nodes to be Ready
echo "Waiting for all nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "[3/3] Cluster status:"
kind get clusters
kubectl get nodes -o wide

echo "Done."
