# cilium

Kubernetes networking labs built around **Cilium**. A hands-on lab repo for
testing CNI, network policy, Hubble observability, service mesh integration,
and multi-cluster topologies on local Kubernetes clusters.

The first lab (`01-setup-kind-cluster`) boots a [kind](https://kind.sigs.k8s.io)
cluster with the default CNI disabled and installs Cilium as the CNI.

## Toolchain

All tool versions are pinned at the **project level** via `.mise.toml` in the
repo root — never set globally.

```bash
# once per shell
eval "$(mise activate bash)"

# in the repo
mise install        # kind, kubectl, cilium-cli, docker-cli, helm
```

Pinned versions: `kind 0.33.0`, `kubectl 1.37.2`, `cilium-cli 0.20.3`,
`docker-cli 29.9.3`, `helm 4.3.2`.

## Prerequisites

- **Rootful Docker.** kind node containers must mount `bpffs` (`/sys/fs/bpf`),
  which rootless Docker cannot do. Cilium's `mount-bpf-fs` init container will
  fail with `mount: /sys/fs/bpf: permission denied` under rootless Docker.
  Ensure the active context is rootful: `docker context use default`.
- `mise` installed (`curl https://mise.run | sh`).

## Quick start

```bash
# 1. Clone the repo
git clone git@github.com:dimzrio/cilium.git
cd cilium

# 2. Install project tools from .mise.toml
eval "$(mise activate bash)"
mise install

# 3. Create the cluster + install Cilium + LB pools, then verify
#    (re-running deletes any existing 'cilium-lab' and rebuilds it)
bash 01-setup-kind-cluster/create.sh
```

`create.sh` runs five steps:

1. Create a kind cluster (1 control-plane + 2 workers, `disableDefaultCNI: true`,
   `kubeProxyMode: none`).
2. Install Cilium via Helm (`ipam.mode=kubernetes`, `kubeProxyReplacement=true`,
   `k8sServiceHost`/`k8sServicePort` set to the control-plane IP).
3. Wait for the Cilium DaemonSet to roll out.
4. Apply the `CiliumLoadBalancerIPPool` CRD (`172.17.0.0/24`).
5. Print `cilium status`.

### Customizing

```bash
# usage: create.sh [cluster-name] [cilium-version] [k8s-image-version] [--keep]
# default: an existing same-named cluster is deleted and recreated;
#          pass --keep to abort instead of deleting.
bash 01-setup-kind-cluster/create.sh cilium-lab 1.20.5 v1.37.0
```

## Verify

```bash
kubectl get nodes                                   # all Ready
kubectl -n kube-system get pods -l k8s-app=cilium    # 3/3 Running
cilium status --namespace kube-system                # Cilium: OK, Operator: OK
kubectl get ciliumloadbalancerippool                 # cluster-lb-pool, 256 IPs
```

## Notes

- Nodes stay `NotReady` until Cilium is installed — that is expected when the
  default CNI is disabled.
- The `cilium-envoy` startup probe may fail briefly while envoy initialises; it
  turns ready once the agent pushes its config. This is transient.
- Tear down with `kind delete cluster --name cilium-lab`.

## References

- Cilium docs: https://docs.cilium.io
- Install with kind: https://docs.cilium.io/en/stable/installation/kind/
- kube-proxy replacement: https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/
- LB IPAM: https://docs.cilium.io/en/stable/network/lb-ipam/
- Hubble: https://docs.cilium.io/en/stable/observability/hubble/
