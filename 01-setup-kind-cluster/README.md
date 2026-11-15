# 01 — Set up kind cluster (1 control-plane + 2 workers)

Creates a local `kind` Kubernetes cluster with one control-plane and two
workers, ready for the Cilium labs.

## Files

| File | Purpose |
|---|---|
| `config/helm-values.yaml` | Cilium helm values (kubeProxyReplacement, cluster pool, routing, operator, LB IPAM, L2, Gateway API) |
| `config/kind-cluster.yaml` | kind manifest: 1 control-plane + 2 workers, disableDefaultCNI, K8s 1.34.0 |
| `config/cilium-lb-ip-pools.yaml` | CiliumLoadBalancerIPPool CRDs for 3 clusters |
| `create.sh` | One-command cluster bootstrap + Cilium install + LB IP pools |
| `README.md` | This file |

## Prerequisites

- `mise` with `kind` + `kubectl` installed (see `.mise.toml`)
- `docker` daemon running

## Usage

```bash
# 1. Install tooling (project-level)
eval "$(mise activate bash)"
mise install        # kind, kubectl

# 2. Create the cluster (1 control-plane + 2 workers)
bash 01-setup-kind-cluster/create.sh cilium-lab
```

## Verify

```bash
kubectl get nodes -o wide
# NAME           STATUS   ROLES           AGE   VERSION
# cilium-lab     Ready    control-plane   10s   v1.31.0
# cilium-lab-workers-1   Ready    <none>       10s   v1.31.0
# cilium-lab-workers-2   Ready    <none>       10s   v1.31.0
```

## Tear down

```bash
kind delete cluster --name cilium-lab
```

## Notes

- `networking.disableDefaultCNI: true` in `kind-cluster.yaml` removes flannel.
  Cilium is installed as the CNI (see `create.sh` step 3/4).
- `1.31.0` is the Kubernetes version pinned in `kind-cluster.yaml`.
  Bump at setup time if a lab requires a different version.
- Cilium 0.16+ requires Kubernetes 1.27+; `1.31.0` is a safe choice.
- Workers are bare nodes; Cilium will schedule onto them once installed.
