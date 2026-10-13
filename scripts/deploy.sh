#!/bin/bash
set -e

echo "=========================================="
echo "NexusFlow EKS Deployment Script"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Resolve repo root (script lives in <repo>/scripts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLUSTER_NAME="eventyx-eks"
REGION="ap-south-1"

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
command -v terraform >/dev/null 2>&1 || { echo "terraform not found"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "aws cli not found"; exit 1; }

# Deploy infrastructure
echo -e "${BLUE}Deploying infrastructure with Terraform...${NC}"
cd "$REPO_ROOT/terraform"
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Configure kubectl
echo -e "${BLUE}Configuring kubectl...${NC}"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# Wait for nodes
echo -e "${BLUE}Waiting for nodes to be Ready...${NC}"
kubectl wait --for=condition=Ready node --all --timeout=600s

# Deploy applications via ArgoCD (requires ArgoCD already installed - see docs/setup.md Phase 4)
echo -e "${BLUE}Deploying applications...${NC}"
kubectl apply -f "$REPO_ROOT/argocd/app-myapp.yaml"

echo -e "${GREEN}=========================================="
echo "Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. kubectl get nodes"
echo "2. kubectl get pods -A"
echo "3. Open ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
