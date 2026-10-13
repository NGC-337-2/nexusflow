# Architecture

## High-level

```
┌─────────────────────────────────────────────────────────────┐
│ AWS Region (ap-south-1)                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ VPC (10.0.0.0/16)                                      │   │
│  │  ┌────────────────┐        ┌────────────────────┐     │   │
│  │  │ Public Subnets │        │ Private Subnets     │     │   │
│  │  │ 10.0.101-103/24│        │ 10.0.1-3/24         │     │   │
│  │  │  ┌──────────┐  │        │  ┌──────────────┐   │     │   │
│  │  │  │   NAT    │◄─┼────────┼─►│  EKS Nodes    │   │     │   │
│  │  │  │ Gateway  │  │        │  │ t3.medium SPOT│   │     │   │
│  │  │  └──────────┘  │        │  └──────────────┘   │     │   │
│  │  │  ┌──────────┐  │        │  ┌──────────────┐   │     │   │
│  │  │  │   IGW    │  │        │  │ EKS Control   │   │     │   │
│  │  │  └──────────┘  │        │  │ Plane (AWS)   │   │     │   │
│  │  └────────────────┘        └────────────────────┘     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

WITHIN EKS CLUSTER:
┌─────────────────────────────────────────────────────────────┐
│  ArgoCD (GitOps)   Istio (mesh)      Monitoring               │
│  argocd-server     istiod / ingress  prometheus / grafana     │
│                                      jaeger / fluent-bit      │
│  Applications (each pod = app + Envoy sidecar):               │
│    myapp-pod x N,  bookinfo (productpage/reviews v1-v3/...)    │
└─────────────────────────────────────────────────────────────┘
```

## Components & design decisions

| Component | Choice | Why |
|-----------|--------|-----|
| Networking | 3-AZ VPC, 1 NAT gateway | HA across AZs; single NAT to cut cost (~$32/mo vs ~$96 for 3) |
| Compute | EKS managed node group, SPOT, `t3.medium`, 1–3 nodes | 60–70% cheaper than on-demand; autoscaling headroom |
| Identity | IRSA (`enable_irsa = true`) | Pod-level least-privilege IAM instead of node-wide roles |
| Delivery | ArgoCD with `prune` + `selfHeal` | Git is the source of truth; drift reverts automatically |
| Packaging | Helm chart + per-env values | One template, three environments (dev/staging/prod) |
| Mesh | Istio, STRICT mTLS, 90/10 canary | Encryption + safe progressive delivery with no app changes |
| Observability | kube-prometheus-stack + Jaeger + Fluent Bit | Metrics, traces, and logs to cut MTTR |

## Request & delivery flows

- **Ingress:** Client → AWS NLB → Istio ingress gateway → VirtualService → service → pod (Envoy sidecar).
- **GitOps:** `git push` → ArgoCD detects change (≤3 min) → syncs cluster → self-heals drift.
- **Canary:** `reviews` VirtualService sends 90% to `v1`, 10% to `v3`; DestinationRule outlier detection ejects a host after 5 consecutive 5xx.
- **Autoscaling:** Metrics Server → HPA scales `myapp` on CPU utilization.
