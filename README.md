# NexusFlow: Production-Grade EKS Infrastructure with GitOps & Service Mesh

[![Terraform](https://img.shields.io/badge/terraform-v1.5+-blue)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.29-blue)](https://kubernetes.io/)
[![Istio](https://img.shields.io/badge/istio-1.20-blue)](https://istio.io/)
[![ArgoCD](https://img.shields.io/badge/argocd-stable-blue)](https://argoproj.github.io/argo-cd/)

## 📋 Project Overview

A **production-aligned, fully automated Kubernetes infrastructure** deployed on AWS EKS demonstrating modern DevOps practices:

- ✅ **Infrastructure as Code** (Terraform) for repeatable, version-controlled deployments
- ✅ **GitOps** (ArgoCD) for declarative sync, audit trails, and self-healing
- ✅ **Service Mesh** (Istio) for mTLS, canary deployments, and traffic management
- ✅ **Complete Observability** (Prometheus, Grafana, Jaeger, Fluent Bit)
- ✅ **Autoscaling** (HPA) based on real-time metrics
- ✅ **Cost Optimized** (~$150/month with SPOT instances)

> **Cluster name:** `eventyx-eks` · **Region:** `ap-south-1`

## 🎯 What This Demonstrates

| Area | Skills Demonstrated |
|------|-------------------|
| **Cloud Architecture** | VPC design, subnets, NAT gateways, IAM OIDC, security groups |
| **Kubernetes** | Deployments, services, namespaces, RBAC, autoscaling, sidecar injection |
| **Infrastructure as Code** | Terraform modules, state management, reproducible deployments |
| **GitOps & CI/CD** | ArgoCD, declarative sync, self-healing, Git-driven operations |
| **Service Mesh** | Istio sidecar architecture, mTLS, traffic splitting, canary releases |
| **Observability** | Metrics (Prometheus), visualization (Grafana), tracing (Jaeger), logs (Fluent Bit) |
| **SRE Practices** | Monitoring, alerting, incident response, cost optimization |

---

## 🚀 Quick Start

### Prerequisites
- AWS Account (billing alerts configured)
- Ubuntu/WSL2 with: AWS CLI, Terraform, kubectl, Helm, Istio CLI
- `ap-south-1` region configured

### Deploy
```bash
git clone https://github.com/NGC-337-2/nexusflow.git
cd nexusflow

# One-click (Terraform + kubectl + ArgoCD app)
./scripts/deploy.sh

# ...or manually
cd terraform
terraform init
terraform apply
aws eks update-kubeconfig --name eventyx-eks --region ap-south-1
kubectl get nodes   # Should show 2 Ready nodes
```

**⏱️ Cluster creation takes 15-20 minutes.**

Full step-by-step for every phase (add-ons, ArgoCD, Istio, observability) is in **[docs/setup.md](docs/setup.md)**.

---

## 🗂️ Repository Layout

```
nexusflow/
├── README.md
├── terraform/              # Phase 2: VPC + EKS (IaC)
├── apps/podinfo/           # Phase 4: GitOps demo app (Kustomize base + dev overlay)
├── argocd/                 # Phase 4/5: ArgoCD Application definitions
├── helm-charts/myapp/      # Phase 5: Helm chart + dev/staging/prod values
├── istio/                  # Phase 6: Gateway, canary, mTLS, routing
├── observability/          # Phase 7: Prometheus rules, Grafana/Fluent Bit values
├── scripts/                # Phase 8: deploy / validate / cleanup
├── docs/                   # Phase 9: architecture, setup, troubleshooting, cost
└── .github/workflows/      # Phase 9: CI (tf validate, helm lint, kubeval, scans)
```

---

## 📈 Key Features

### 1️⃣ Infrastructure as Code (Terraform)
Single `terraform apply` creates a VPC with public/private subnets across 3 AZs and an EKS cluster with SPOT managed node groups and least-privilege IRSA.
Key files: `terraform/{main,vpc,eks}.tf`.

### 2️⃣ GitOps with ArgoCD
Applications are defined in Git as the source of truth. ArgoCD continuously syncs the cluster, reverts manual drift, and keeps a full audit trail. `prune: true` + `selfHeal: true` revert unauthorized changes within one ~3-minute sync cycle.
Key files: `argocd/app-podinfo.yaml`, `argocd/app-myapp.yaml`, `helm-charts/myapp/`.

### 3️⃣ Service Mesh with Istio
Envoy sidecars are injected transparently. Mesh-wide **STRICT mTLS** encrypts all pod-to-pod traffic, and a **90/10 weighted canary** (VirtualService/DestinationRule subsets) with outlier-detection circuit breaking contains blast radius — zero application code changes.
Key files: `istio/istio-gateway.yaml`, `istio/canary-deployment.yaml`, `istio/mtls-policy.yaml`, `istio/advanced-routing.yaml`.

### 4️⃣ Complete Observability
Prometheus (metrics) + Grafana (dashboards) + Jaeger (tracing) + Fluent Bit (logs). **8 custom `PrometheusRule` alerts across 3 groups** (error-rate, latency, resource-saturation).
Key files: `observability/prometheus-rules.yaml`, `observability/values-prometheus.yaml`, `observability/fluent-bit-values.yaml`.

### 5️⃣ Autoscaling (HPA)
Horizontal Pod Autoscaler scales `myapp` on CPU utilization (via Metrics Server), adding replicas under load and scaling back down when idle.

---

## 💰 Cost Analysis

| Component | Cost | Notes |
|-----------|------|-------|
| EKS Control Plane | $72 | Fixed per cluster |
| 2x t3.medium SPOT | $29 | 60-70% cheaper than on-demand |
| NAT Gateway | $32 | Single NAT for all AZs |
| 2x NLB | $9 | Istio ingress + myapp service |
| Data Transfer | $10 | Inter-AZ |
| **Total** | **~$152** | **Daily: ~$5** |

See **[docs/cost-analysis.md](docs/cost-analysis.md)** for optimization strategies.

---

## 🔐 Security Features
- **mTLS:** All service-to-service traffic encrypted (STRICT)
- **IRSA:** Fine-grained IAM via service accounts
- **Private Subnets:** Nodes have no direct internet ingress
- **CI security scanning:** Checkov + Trivy on every push

---

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | Component breakdown, design decisions |
| [Setup Guide](docs/setup.md) | Phase-by-phase deployment steps |
| [Troubleshooting](docs/troubleshooting.md) | Common issues & fixes |
| [Cost Analysis](docs/cost-analysis.md) | Budget breakdown & optimization |

---

## 🧪 Validation

```bash
./scripts/validate.sh
```
Checks nodes, ArgoCD apps, Istio mTLS, Prometheus rules, and that the Helm chart lints and the Kustomize overlay builds.

---

## 🛠️ Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Cloud | AWS EKS | 1.29 |
| IaC | Terraform | 1.5+ |
| GitOps | ArgoCD | Stable |
| Package Manager | Helm | 3.x |
| Service Mesh | Istio | 1.20 |
| Monitoring | Prometheus / Grafana | Latest |
| Tracing | Jaeger | Latest |
| Logs | Fluent Bit | Latest |

---

## 📝 License

MIT License — use this for your portfolio.
