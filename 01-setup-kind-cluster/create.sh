#!/usr/bin/env bash
# usage: ./create.sh [name] [cilium-version] [k8s-version]
# kind cluster (1 control-plane + 2 workers) with Cilium as the CNI.
# Needs rootful Docker. An existing cluster of the same name is recreated.
set -euo pipefail

NAME="${1:-cilium-lab}"
CILIUM_VERSION="${2:-1.20.5}"
K8S_VERSION="${3:-v1.37.0}"

cd "$(dirname "$0")"

unset DOCKER_HOST   # ignore a stale rootless pointer left in old shells
if docker info 2>/dev/null | grep -qi rootless; then
  echo "ERROR: rootless Docker; Cilium needs rootful."; exit 1
fi

if kind get clusters 2>/dev/null | grep -qx "$NAME"; then
  kind delete cluster --name "$NAME"
fi

kind create cluster --name "$NAME" --config config/kind-cluster.yaml --image "kindest/node:$K8S_VERSION"

IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$NAME-control-plane")
helm repo add cilium https://helm.cilium.io/ >/dev/null
helm repo update >/dev/null
helm install cilium cilium/cilium -n kube-system --version "$CILIUM_VERSION" \
  -f config/helm-values.yaml --set k8sServiceHost="$IP"

kubectl -n kube-system rollout status ds/cilium --timeout=600s
kubectl apply -f config/cilium-lb-ip-pools.yaml
cilium status -n kube-system
