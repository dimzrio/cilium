# lab-04 — multi-cluster

Run two Cilium clusters and link them with the cluster mesh. This lab covers
the cluster peerings feature, which allows direct Pod-to-Pod routing across
clusters.

## Step 0 — prerequisites

- Lab 01 done on two clusters
- `cilium` CLI
- The two clusters must be reachable from each other (by IP or DNS)

## Step 1 — create a cluster peer

```bash
# On cluster A
cilium clustermesh peer create https://<cluster-B-apiserver>:6443 \
  --name cluster-b
```

## Step 2 — verify peer status

```bash
cilium clustermesh status
```

## Step 3 — verify cross-cluster connectivity

From a Pod in cluster A, reach a Pod in cluster B by their service or pod IP
(if IP routing is configured with BGP).

```bash
# Check cluster peer status
cilium clustermesh get-peers
```

## Notes

- Requires Cilium >= 1.12 for cluster mesh (the `--name` peer flag).
- For routing across clusters, you'll also need BGP peering or a gateway
  between the clusters. This lab covers the peer setup only; routing requires
  additional config (`clusterPeering` + BGP).

## References

- https://docs.cilium.io/en/latest/getting-started/multi-cluster/
- https://docs.cilium.io/en/stable/operations/clustermesh/
