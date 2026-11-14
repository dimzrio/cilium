# cilium

Kubernetes networking labs built around **Cilium**. A hands-on lab repo for
testing CNI, network policy, Hubble observability, service mesh integration,
and multi-cluster topologies on local and cloud Kubernetes clusters.

The labs assume you already have a Kubernetes cluster (local or cloud) and a
working `kubectl`. Each lab is self-contained so you can run them in any order.

## Toolchain

Tools are pinned at the **project level** via `.mise.toml` (not global):

```bash
eval "$(mise activate bash)"   # source once in a shell
mise install                   # install pinned tools
```

See [.mise.toml](.mise.toml) for the pinned tool list.

---

## Quick start

```bash
# 1. Install tooling (via mise)
curl https://mise.run | sh
eval "$(mise activate bash)"
mise use -g cilium-cli kubectl kind docker
mise install

# 2. Create a kind cluster
kind create cluster --name cilium-lab

# 3. Install Cilium (Helm)
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system \
  --version 0.16.0 \
  --values config/helm-values/base-values.yaml

# 4. Verify
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
