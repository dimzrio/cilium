# cilium

Kubernetes networking labs built around **Cilium**. A hands-on lab repo for
testing CNI, network policy, Hubble observability, service mesh integration,
and multi-cluster topologies on local and cloud Kubernetes clusters.

The labs assume you already have a Kubernetes cluster (local or cloud) and a
working `kubectl`. Each lab is self-contained so you can run them in any order.

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

## Lab map

| Lab | Topic | Prerequisites |
|-----|-------|---------------|
| `lab-00` | Environment setup | Docker, `mise`, `kind`, `kubectl`, `cilium-cli` |
| `lab-01` | Install Cilium (Helm) | A Kubernetes cluster |
| `lab-02` | NetworkPolicy & L3/L4 | Cilium with BPF or native-routing |
| `lab-03` | Hubble (observability) | Cilium with Hubble enabled |
| `lab-04` | Multi-cluster / cluster mesh | 2+ Cilium clusters |
| `lab-05` | Service mesh + eBPF | Cilium with Istio or Tetrate |

---

## How the labs are organized

```
cilium/
├── README.md
├── .gitignore
├── docs/architecture.md      # Cilium dataplane reference
├── labs/lab-00/ … lab-05/    # 6 self-contained labs
├── config/helm-values/       # helm values per setup
├── scripts/setup.sh          # create clusters + install Cilium
└── scripts/teardown.sh       # tear down labs
```

---

## Learning path

### 1. Build the environment (`lab-00` → `lab-01`)
Bootstrap `mise`, `kind`, and a multi-node cluster, then install Cilium.

### 2. Understand policy (`lab-02`)
Learn endpoint-based NetworkPolicy: L3/L4, L7, and egress rules.

### 3. Observe (`lab-03`)
Enable Hubble and trace traffic between Pods.

### 4. Scale out (`lab-04`)
Peer two Cilium clusters with clustermesh.

### 5. Compose (`lab-05`)
Run a service mesh on top of Cilium.

---

## Prerequisites (each lab)

- `kubectl` ≥ 1.28
- `kind` ≥ 0.20
- `cilium-cli` (CLI for Cilium)
- A Kubernetes cluster (local `kind` or cloud)

---

## References

- Cilium docs: https://docs.cilium.io
- Install guide: https://docs.cilium.io/en/stable/getting-started/kubernetes/install/
- NetworkPolicy: https://docs.cilium.io/en/stable/concepts/network/policy/
- Hubble: https://docs.cilium.io/en/stable/observability/hubble/
- Cluster mesh: https://docs.cilium.io/en/stable/operations/clustermesh/
