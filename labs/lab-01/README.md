# lab-01 — install Cilium

Install the Cilium CNI into a Kubernetes cluster you control. This lab covers
the two most common approaches:

1. **Helm** (recommended for labs and CI)
2. **cilium CLI** (simpler for quick starts)

## Approach A: Helm

```bash
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium --namespace kube-system \
  --version 0.16.0 \
  --values config/helm-values/base-values.yaml
```

Verify:

```bash
cilium status --namespace kube-system
kubectl -n kube-system rollout status ds/cilium
```

## Approach B: cilium CLI

```bash
cilium install --version 0.16.0 --namespace kube-system
```

## Confirmations you should check

- `cilium status` reports `ok: true`
- `kubectl -n kube-system get pods -l k8s-app=cilium` shows `Ready`
- `cilium node list` shows your nodes
- Pods can reach each other across nodes

## Teardown

```bash
helm -n kube-system uninstall cilium
# or
cilium uninstall --namespace kube-system
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `cilium status` = `not ready` | CRDs not installed / wrong version | `cilium install --version X` installs CRDs |
| `pods` stuck `ContainerCreating` | iptables/nftables conflict | Set `kubeProxyReplacement: strict` and `ipam: clusterPool` |
| `cilium node list` shows no nodes | `clusterPoolIPv4PodCIDR` mismatch | Match the node CIDR with `nodeCIDR` |

## References

- Helm chart: https://github.com/cilium/cilium/tree/master/pkg/k8s/apis/cilium/helm
- Install guide: https://docs.cilium.io/en/stable/getting-started/kubernetes/install/
