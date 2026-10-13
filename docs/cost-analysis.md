# Cost Analysis & Optimization

## Monthly Cost Breakdown (Running 24/7)

| Component | Price | Duration | Total |
|-----------|-------|----------|-------|
| EKS Control Plane | $0.10/hour | 730h/month | **$73** |
| t3.medium Node #1 (SPOT) | ~$0.008/hour | 730h/month | **$6** |
| t3.medium Node #2 (SPOT) | ~$0.008/hour | 730h/month | **$6** |
| NAT Gateway | $0.045/hour | 730h/month | **$33** |
| NLB (Istio Ingress) | $0.006/hour | 730h/month | **$4** |
| NLB (myapp Service) | $0.006/hour | 730h/month | **$4** |
| Data Transfer (inter-AZ) | ~$0.01/GB | ~1000GB | **$10** |
| **TOTAL (24/7)** | | | **~$136/month** |

## Cost Optimization Strategies

### 1. Scale Down When Not Testing
```bash
kubectl scale deploy --all --replicas=0 -n myapp-prod
kubectl scale deploy --all --replicas=0 -n monitoring
# Estimated monthly: $73 (EKS only) + $15 (NAT/LB) = $88
```

### 2. Use Fargate Instead of EC2 (pay per pod)
```
2 pods x 0.5 vCPU x 730h x $0.04048 = ~$30/month  (saves ~$12 vs EC2 nodes)
```

### 3. Reserved Instances (production only)
1-year commitment ≈ 33% discount: t3.medium ~$13.45/mo each vs $20 on-demand.

### 4. Delete Non-Essential Services
Remove Jaeger / Grafana / Fluent Bit when not needed (~$5-10/mo). Keep EKS + nodes + ArgoCD.

### 5. Auto-Scale Nodes
Min 1 / Max 5 → cost varies $70-150/month with usage.

## Scenarios

| Scenario | Usage | Est. monthly | Daily |
|----------|-------|--------------|-------|
| Development | 8h/day, 5 days/wk | ~$100 | ~$1.36 |
| Production | 24/7 | ~$136 | ~$4.53 |
| Testing only | 2h/day | ~$90 | ~$3 |

## Cost Reduction Checklist
- [x] SPOT instances enabled (60-70% node savings)
- [x] Single NAT Gateway (vs one per AZ)
- [x] Prometheus retention 24h
- [ ] Auto-scaling tuned for idle scale-down
- [ ] No unused EBS volumes / security groups
- [ ] CloudWatch logs retention < 7 days

## How to Monitor Costs
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```
Also: AWS Billing → Budgets + Cost Anomaly Detection (alert on >10% deviation).

## Conclusion
Cost-optimized for learning but production-shaped: ~$100/mo dev, ~$150/mo prod, both with HA, autoscaling, and full observability.
