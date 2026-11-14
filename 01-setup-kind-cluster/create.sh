#!/usr/bin/env bash
# create-cluster.sh — create a kind cluster: 1 control-plane + 2 workers,
# disable default CNI, and install Cilium.
# Usage: bash create.sh [cluster-name]
set -euo pipefail

NAME="${1:-cilium-lab}"

# Resolve to the script's directory so relative paths work from any CWD
cd "$(dirname "$0")"

echo "[1/4] Creating kind cluster '${NAME}' (1 control-plane + 2 workers)..."
kind create cluster \
  --name "${NAME}" \
  --config config/kind-cluster.yaml \
  --image kindest/node:${K8S_VERSION:-"1.34.0"}

echo "[2/4] Waiting for all nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "[3/4] Installing Cilium (Helm)..."
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium \
  --namespace kube-system \
  --version 0.16.0 \
  --values config/cilium-values.yaml

echo "[4/4] Waiting for Cilium to be ready..."
kubectl -n kube-system rollout status ds/cilium --timeout=300s
cilium status --namespace kube-system

echo "Done."
