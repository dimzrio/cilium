# lab-00 — environment bootstrap

Set up the tooling and a throwaway Kubernetes cluster so the remaining labs can
run.

## Prerequisites

On the host:

- Linux (Ubuntu 24.04 tested) or macOS
- `curl`, `git`, `sudo`
- 4 GB+ free RAM, 20 GB+ free disk
- Internet access to `k3s.io`, `kind.sigs.k8s.io`, and the helm repos below

## Step 0 — tooling

Use `mise` (see your dotfiles `SETUP.md`) to install and pin:

```bash
mise use -g cilium-cli@latest
mise use -g kind@latest
mise use -g kubectl@latest
mise use -g docker@latest
mise install
```

Verify:

```bash
cilium version
kind version
kubectl version --client
```

## Step 1 — create a kind cluster

```bash
cat <<'EOF' > kind-cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /var/run/docker.sock
        containerPath: /var/run/docker.sock
  - role: worker
EOF

kind create cluster --name cilium-lab --config kind-cluster.yaml
```

## Step 2 — register the node with Cilium's own IP

```bash
# Get the node's internal IP as seen by the CNI
NODE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-cilium-lab-control-plane)

# Patch the node's podCIDR if needed
kubectl get node kind-cilium-lab-control-plane -o jsonpath='{.spec.podCIDR}' || true
```

## Step 3 — install Cilium (init)

Skip to Lab 01 for the actual install.

## Check

```bash
kubectl get nodes
cilium status --namespace kube-system
```

## References

- https://kind.sigs.k8s.io
- https://docs.cilium.io/en/stable/getting-started/kubernetes/kind/
