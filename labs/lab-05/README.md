# lab-05 — service mesh + eBPF

Cilium integrates with service meshes. This lab installs a minimal mesh on
top of Cilium and validates it.

## Approach: Istio with Cilium (recommended initial setup)

Istio can run with Cilium as the CNI. The mesh sidecars (Envoy) are deployed
in the `istio-system` namespace; Cilium provides the CNI and eBPF-based
networking. Note that when Cilium is the CNI, you will generally disable
`kube-proxy` (Cilium handles L4 load balancing) — set
`kubeProxyReplacement: strict` in Cilium's helm values.

## Step 0 — Cilium configuraton

In your Cilium helm values (from Lab 01):

```yaml
kubeProxyReplacement: strict
```

## Step 1 — install Istiod

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

helm install istio-base istio/istio-base --namespace istio-system
helm install istiod istio/istiod --namespace istio-system
helm install istio-init istio/install-kube \
  --namespace istio-system \
  --set global.istiod.enableHelmRevisionAnnotations=false
```

## Step 2 — install a test service

```bash
kubectl create ns myservice
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: myservice
spec:
  selector:
    app: backend
  ports:
    - port: 8080
EOF

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: myservice
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: nginx:alpine
          ports:
            - containerPort: 8080
EOF
```

## Step 3 — verify

```bash
kubectl -n istio-system get pods
kubectl -n myservice get pods
```

## Troubleshooting

- `kubeProxyReplacement: strict` requires Cilium >= 1.11; older versions may
  need `strictDHCP` or other flags.
- If Envoy sidecars fail to start, verify the node's kernel supports the
  features Cilium needs (see the Cilium compat matrix).

## References

- https://docs.cilium.io/en/stable/security/service-mesh/
- https://istio.io/latest/docs/ops/deployment/
