# cilium

Kubernetes networking labs built around **Cilium**. A hands-on lab repo for
testing CNI, network policy, Hubble observability, service mesh integration,
and multi-cluster topologies on local and cloud Kubernetes clusters.

The labs assume you already have a Kubernetes cluster (local or cloud) and a
working `kubectl`. Each lab is self-contained so you can run them in any order.

## Toolchain

All tool versions are pinned at the **project level** via `.mise.toml` in the
repo root — never set globally.

```bash
# in a shell, once:
eval "$(mise activate bash)"

# in the repo, per-project:
mise install        # installs kind, kubectl, cilium-cli, docker-cli, helm
```

- `mise` reads `.mise.toml` from the project root and resolves versions per
  project (no `-g` flag needed).
- To pin an exact version later: `mise use kind@0.33.0` (writes into `.mise.toml`).

---

## Quick start

```bash
# 1. Install mise (one-time, global)
curl https://mise.run | sh
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# 2. Clone this repo
git clone git@github.com:dimzrio/cilium.git
cd cilium

# 3. Install project tools from .mise.toml
mise install

# 4. Create a kind cluster
kind create cluster --name cilium-lab

# 5. Install Cilium (Helm)
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system \
  --version 0.16.0 \
  --values config/helm-values/base-values.yaml

# 6. Verify
cilium status --namespace kube-system
kubectl -n kube-system rollout status ds/cilium
```

---

## References

- Cilium docs: https://docs.cilium.io
- Install guide: https://docs.cilium.io/en/stable/getting-started/kubernetes/install/
- NetworkPolicy: https://docs.cilium.io/en/stable/concepts/network/policy/
- Hubble: https://docs.cilium.io/en/stable/observability/hubble/
- Cluster mesh: https://docs.cilium.io/en/stable/operations/clustermesh/
