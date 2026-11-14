# Cilium dataplane reference

This document is the quick reference for the Cilium dataplane as used in the
labs. It is not a substitute for the official docs (see
https://docs.cilium.io).

## Dataplanes

Cilium supports three dataplane modes:

| Mode | When to use | eBPF required |
|---|---|---|
| `bpf` (native) | Default on Linux kernel 5.x+ on bare metal / VMs | Yes |
| `ipvlan` / `urlocalnat` | Older kernels or specific CNI constraints | No (but recommended) |
| `azure-vnet` | Azure CNI hybrid | No |
| `kdd` (Kubernetes CRDs) | Legacy / managed clusters where eBPF is not allowed | No |

## Key concepts

- **Identity-based policy**: policies are applied per-Kubernetes workload
  (Pods are mapped to Cilium identities).
- **CIPN / overlay**: default overlay is VXLAN; `TunnelProtocol` can switch to
  Geneve or none (L2-adjacent).
- **Hubble**: eBPF-based networking and security observability (flow logs,
  L7 visibility).
- **BGP control plane**: for multi-cluster and on-prem routing.
- **Service mesh**: Cilium integrates with Istio, Linkerd, Consul, etc.

## Useful Cilium commands

```bash
# status
cilium status --namespace kube-system

# hubble
cilium hubble enable --namespace kube-system
cilium hubble status --namespace kube-system
cilium hubble observe --namespace kube-system > hubble.log

# podCIDR / nodeCIDR inspect
cilium node list --namespace kube-system

# metrics endpoint
kubectl -n kube-system port-forward svc/cilium-clusterpeerings 9876:9876

# tracing (requires Hubble)
cilium hubble trace --namespace kube-system
```

## Docs

- https://docs.cilium.io
- https://docs.cilium.io/en/stable/concepts/network/policy/
- https://docs.cilium.io/en/stable/getting-started/bpf/
