#!/usr/bin/env bash
# teardown.sh — clean up lab artifacts.
# Usage: bash teardown.sh <cluster-name>
set -euo pipefail

NAME="${1:-cilium-lab}"

echo "[1/2] Removing Cilium..."
helm -n kube-system uninstall cilium || true
cilium uninstall --namespace kube-system || true

echo "[2/4] Removing kind cluster '${NAME}'..."
kind delete cluster --name "${NAME}"

echo "[3/4] Cleaning helm release files..."
helm env >/dev/null 2>&1 || true

echo "[4/4] Done. Verify with: kubectl get nodes"
