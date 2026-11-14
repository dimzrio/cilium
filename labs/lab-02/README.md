# lab-02 — NetworkPolicy & L3/L4

Install a policy engine and write rules that govern traffic between Pods.

## Prereq

- Lab 01 done: Cilium installed and healthy.

## Step 1 — confirm NetworkPolicy is enforced

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: netpol-demo
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: netpol-demo
  labels:
    app: client
spec:
  containers:
    - name: client
      image: busybox
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: server
  namespace: netpol-demo
  labels:
    app: server
spec:
  containers:
    - name: server
      image: nginx:alpine
      ports:
        - containerPort: 80
EOF
```

## Step 2 — deny all ingress by default

```bash
kubectl apply -f - <<'EOF'
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: netpol-demo
spec:
  endpointSelector:
    matchLabels:
      app: server
  egress:
    - toEntities:
        - kube-apiserver
  ingress:
    - fromEntities:
        - kube-apiserver
EOF
```

## Step 3 — allow ingress from the client

```bash
kubectl apply -f - <<'EOF'
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-client
  namespace: netpol-demo
spec:
  endpointSelector:
    matchLabels:
      app: server
  egress:
    - toEntities:
        - kube-apiserver
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: client
EOF
```

## Step 4 — verify

```bash
kubectl -n netpol-demo exec deploy/client -- wget -qO- http://server.netpol-demo.svc.cluster.local
# should return the nginx default page

kubectl -n netpol-demo exec deploy/client -- wget -qO- http://other-service
# blocked by policy
```

## Additional exercises

- Egress policy: restrict server's outbound connections.
- L3/L4 policy: match on IP/CIDR and port.
- L7 policy: match on HTTP method/URI (requires Cilium Enterprise or the
  free open-source L7 policy with the correct krets).

## Notes

- Cilium policies are applied at the *endpoint* (Pod). They are not namespace
  selectors; use `endpointSelector` + labels.
- Always test with `cilium status` and `cilium hubble observe` before and after.

## References

- https://docs.cilium.io/en/stable/concepts/network/policy/
- https://docs.cilium.io/en/stable/operations/troubleshooting/
