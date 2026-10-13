#!/bin/bash
# Non-destructive validation of the NexusFlow cluster. Exits non-zero on failure.
set -uo pipefail

PASS=0
FAIL=0

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Infrastructure ==="
check "kubectl can reach the cluster" kubectl cluster-info
check "at least one node is Ready" bash -c "kubectl get nodes | grep -q ' Ready '"

echo "=== GitOps (ArgoCD) ==="
check "argocd namespace exists" kubectl get ns argocd
check "podinfo Application exists" kubectl get application podinfo -n argocd
check "myapp Application exists" kubectl get application myapp -n argocd

echo "=== Service Mesh (Istio) ==="
check "istio-system namespace exists" kubectl get ns istio-system
check "istiod is running" bash -c "kubectl get deploy istiod -n istio-system >/dev/null 2>&1"
check "STRICT mTLS PeerAuthentication applied" kubectl get peerauthentication default

echo "=== Observability ==="
check "monitoring namespace exists" kubectl get ns monitoring
check "custom PrometheusRule applied" kubectl get prometheusrule custom-alerts -n monitoring
check "grafana pod present" bash -c "kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana | grep -q grafana"

echo ""
echo "=== Static manifests (no cluster needed) ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if command -v helm >/dev/null 2>&1; then
  check "helm chart lints" helm lint "$REPO_ROOT/helm-charts/myapp"
fi
if command -v kubectl >/dev/null 2>&1; then
  check "kustomize overlay builds" kubectl kustomize "$REPO_ROOT/apps/podinfo/overlays/dev"
fi

echo ""
echo "----------------------------------------"
echo "Passed: $PASS   Failed: $FAIL"
echo "----------------------------------------"
[ "$FAIL" -eq 0 ]
