# Setup Guide

Phase-by-phase deployment. Cluster name `eventyx-eks`, region `ap-south-1`.

## Phase 1 — Tools
Install: AWS CLI v2, kubectl, Helm 3, Terraform ≥1.5, istioctl, eksctl. Then `aws configure` and verify `aws sts get-caller-identity`.

## Phase 2 — Provision EKS (Terraform)
```bash
cd terraform
terraform init
terraform validate
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
aws eks update-kubeconfig --name eventyx-eks --region ap-south-1
kubectl get nodes          # 2 Ready nodes
```
If the apply fails with KMS/CloudWatch permission errors, attach the required IAM permissions to your user/role (see [troubleshooting](troubleshooting.md)).

## Phase 3 — Core add-ons
```bash
# AWS Load Balancer Controller (IAM policy in terraform/iam_policy.json)
helm repo add eks https://aws.github.io/eks-charts && helm repo update
eksctl create iamserviceaccount --cluster=eventyx-eks --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve --region=ap-south-1
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=eventyx-eks --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Metrics Server (needed for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# ExternalDNS (optional; IAM policy in terraform/external-dns-policy.json)
```

## Phase 4 — GitOps with ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Register this repo's apps
kubectl apply -f argocd/app-podinfo.yaml
kubectl get application -n argocd           # podinfo Synced & Healthy
```

## Phase 5 — Helm microservice
```bash
helm lint helm-charts/myapp
helm template myapp helm-charts/myapp -f helm-charts/myapp/values-prod.yaml
kubectl apply -f argocd/app-myapp.yaml      # ArgoCD deploys the chart (values-prod.yaml)
```

## Phase 6 — Istio service mesh
```bash
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
kubectl apply -f istio/istio-gateway.yaml
kubectl apply -f istio/canary-deployment.yaml
kubectl apply -f istio/mtls-policy.yaml
kubectl apply -f istio/advanced-routing.yaml
```

## Phase 7 — Observability
See [observability/README.md](../observability/README.md). In short:
```bash
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring -f observability/values-prometheus.yaml
kubectl apply -f observability/prometheus-rules.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml
helm install fluent-bit fluent/fluent-bit -n monitoring -f observability/fluent-bit-values.yaml
```

## Phase 8 — Validate & clean up
```bash
./scripts/validate.sh     # non-destructive checks
./scripts/cleanup.sh      # destroys everything (asks for confirmation)
```
