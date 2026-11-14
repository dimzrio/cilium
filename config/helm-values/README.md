# Base Cilium helm values for labs

This folder holds inline helm values for the lab setups. Copy what you need
into your local helm install command.

## Choosing a values file

| File | Purpose |
|---|---|
| `base-values.yaml` | Minimal, no Hubble, no LB |
| `hubble-values.yaml` | Adds Hubble + relay + UI |
| `multicluster-values.yaml` | Adds cluster mesh support |

## Quick reference

```bash
helm install cilium cilium/cilium --namespace kube-system \
  --version 0.16.0 \
  --values config/helm-values/base-values.yaml
```

## Notes

- `kubeProxyReplacement: strict` replaces kube-proxy with Cilium's eBPF L4 LB.
- Hubble requires `hubble.relay.enabled: true` on the Cilium nodes.
- Cluster mesh requires `clustermesh.apiextensions.crds` installed + peer config.
