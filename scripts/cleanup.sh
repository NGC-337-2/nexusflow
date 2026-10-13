#!/bin/bash
set -e

echo "WARNING: This will destroy all AWS resources!"
read -p "Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Deleting Kubernetes resources..."
kubectl delete namespace argocd monitoring myapp-prod myapp-staging myapp-dev podinfo istio-system 2>/dev/null || true

echo "Destroying infrastructure with Terraform..."
cd "$REPO_ROOT/terraform"
terraform destroy -auto-approve

echo "Cleanup complete!"
