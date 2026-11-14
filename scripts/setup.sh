#!/usr/bin/env bash
# setup.sh — create clusters, install Cilium, and leave the environment ready.
# Usage: bash setup.sh <cluster-name>
set -euo pipefail

NAME="${1:-cilium-lab}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "[1/4] Creating kind cluster '${NAME}'..."
cat <<EOF > /tmp/kind-cluster-${NAME}.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /var/run/docker.sock
        containerPath: /var/run/docker.sock
EOF
kind create cluster --name "${NAME}" --config /tmp/kind-cluster-${NAME}.yaml
rm -f /tmp/kind-cluster-${NAME}.yaml

echo "[2/4] Installing Cilium via Helm..."
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium \
  --namespace kube-system \
  --version 0.16.0 \
  --values config/helm-values/base-values.yaml

echo "[3/4] Waiting for Cilium to be ready..."
kubectl -n kube-system rollout status ds/cilium --timeout=300s

echo "[4/4] Verifying..."
cilium status --namespace kube-system
kubectl get nodes -o wide
