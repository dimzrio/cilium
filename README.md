# cilium-labs

Kubernetes networking labs built around **Cilium**. A hands-on lab repo for
testing CNI, network policy, Hubble observability, service mesh integration,
and multi-cluster topologies on local and cloud Kubernetes clusters.

Scope: the labs assume you already have a Kubernetes cluster (local or cloud)
and a working `kubectl`. Each lab is self-contained so you can run them in any
order.

---

## Repositories in this workspace

| Repo | Purpose |
|---|---|
| `dotfiles` | Your whole Linux workstation config; bootstrap via `SETUP.md` on a fresh Ubuntu 24.04 |
| `cilium-labs` | Kubernetes networking labs with Cilium |

---

## Quick start

```bash
# 1. Prerequisites
sudo apt-get update && sudo apt-get install -y curl git
curl https://mise.run | sh
eval "$(mise activate bash)"
mise use -g cilium-cli kubectl kind docker
mise install

# 2. Install kind + start a control-plane cluster
kind create cluster --name cilium-lab

# 3. Install Cilium
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system \
  --version 0.16.0 \
  --values config/helm-values/default-values.yaml

# 4. Verify
cilium status --namespace kube-system
kubectl get pods -n kube-system -l k8s-app=cilium
```

---

## Lab map

| Lab | Topic | Prerequisites |
|---|---|---|
| `lab-00` | Environment setup | Docker, `mise`, `kind`, `kubectl`, `cilium-cli` |
| `lab-01` | Install Cilium (Helm) | A Kubernetes cluster |
| `lab-02` | NetworkPolicy & L3/L4 policies | Cilium with BPF or native-routing |
| `lab-03` | Hubble (observability) | Cilium with Hubble enabled |
| `lab-04` | Multi-cluster / cluster mesh | 2+ Cilium clusters |
| `lab-05` | Service mesh + eBPF | Cilium with Istio or Tetrate |

---

## How the labs are organized

```
cilium-labs/
├── README.md                    # this file
├── docs/
│   └── architecture.md          # Cilium dataplane reference
├── labs/
│   ├── lab-00/                  # environment bootstrap
│   ├── lab-01/                  # install Cilium (several methods)
│   ├── lab-02/                  # network policy (L3/L4, L7, egress)
│   ├── lab-03/                  # Hubble monitoring
│   ├── lab-04/                  # multi-cluster
│   └── lab-05/                  # service mesh
├── config/
│   └── helm-values/             # helm values files per setup
├── scripts/
│   ├── setup.sh                 # create clusters + install Cilium
│   └── teardown.sh              # tear down labs
└── artifacts/                   # generated outputs (ignore in git)
```

---

## First lab

`labs/lab-00/` walks you through bootstrapping the environment. Follow it before
anything else.
