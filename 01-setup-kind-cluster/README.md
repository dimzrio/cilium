# 01 — Set up kind cluster (1 control-plane + 2 workers)

Creates a local `kind` Kubernetes cluster with one control-plane and two
workers, disables the default CNI, installs Cilium as the CNI, and applies an
LB IP pool.

## Files

| File | Purpose |
|---|---|
| `config/kind-cluster.yaml` | kind manifest: 1 control-plane + 2 workers, `disableDefaultCNI: true`, `kubeProxyMode: none` |
| `config/cilium-lb-ip-pools.yaml` | `CiliumLoadBalancerIPPool` CRD (`cluster-lb-pool`, `172.17.0.0/24`) |
| `create.sh` | One-command bootstrap: create cluster → install Cilium → apply LB pools → verify |
| `README.md` | This file |

## Prerequisites

- **Rootful Docker.** kind nodes must mount `bpffs` (`/sys/fs/bpf`). Rootless
  Docker cannot, and Cilium's `mount-bpf-fs` init container fails with
  `mount: /sys/fs/bpf: permission denied`. Confirm with `docker context show`.
- `mise` with `kind`, `kubectl`, `helm`, `cilium-cli` installed (see repo `.mise.toml`).

## Usage

```bash
# 1. Install tooling (project-level)
eval "$(mise activate bash)"
mise install

# 2. Create the cluster + install Cilium + LB pool, then verify
bash 01-setup-kind-cluster/create.sh cilium-lab
```

### Customizing

```bash
# usage: create.sh [cluster-name] [cilium-version] [k8s-image-version]
bash 01-setup-kind-cluster/create.sh cilium-lab 1.20.5 v1.37.0
```

## Verify

```bash
kubectl get nodes
# NAME                       STATUS   ROLES           VERSION
# cilium-lab-control-plane   Ready    control-plane   v1.37.0
# cilium-lab-worker          Ready    <none>          v1.37.0
# cilium-lab-worker2         Ready    <none>          v1.37.0

cilium status --namespace kube-system
# Cilium: OK  Operator: OK  Envoy DaemonSet: OK
```

## Tear down

```bash
kind delete cluster --name cilium-lab
```

## Notes

- Nodes stay `NotReady` until Cilium is installed — expected when the default
  CNI is disabled. The script installs Cilium right after cluster creation.
- The `cilium-envoy` startup probe may fail briefly while envoy initialises; it
  turns ready once the agent pushes its config. This is transient.
- `create.sh` default is Cilium `1.20.5` on Kubernetes `v1.37.0`.
