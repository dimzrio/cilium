# lab-03 — Hubble

Hubble is the eBPF-based observability layer for Cilium. It provides flow logs,
L7 visibility, tracing, and the Hubble UI.

## Step 0 — verify you have a healthy Cilium

```bash
cilium status --namespace kube-system
```

## Step 1 — enable Hubble

```bash
cilium hubble enable --namespace kube-system
```

## Step 2 — verify Hubble

```bash
cilium hubble status --namespace kube-system
```

Expected: `ok: true` and `Server listening` on `localhost:4244`.

## Step 3 — view flows

```bash
# watch flow events in real time
cilium hubble observe --namespace kube-system

# or save to a file
cilium hubble observe --namespace kube-system > hubble.log
```

## Step 4 — set up the UI

```bash
# port forward
kubectl -n kube-system port-forward svc/hubble-ui 8080:80

# open http://localhost:8080
```

## Step 5 — tracing

```bash
# start a trace, then:
cilium hubble trace --namespace kube-system
```

## Notes

- Hubble requires `hubble.relay.enabled` and `hubble.ui.enabled` in the helm
  values for chart >= 0.12.
- Flow fields: `from.Entity`, `to.Entity`, `from.Workload`, `to.Workload`,
  `L7[http]`. See `pcap` for raw packets.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `hubble observe` returns nothing | Check `hubble.relay` pods are Running; Hubble must be enabled on node |
| UI shows `no data` | `hubble observe` in a different namespace to confirm flows exist |

## References

- https://docs.cilium.io/en/stable/observability/hubble/
- https://docs.cilium.io/en/stable/observability/hubble/helm-chart/
