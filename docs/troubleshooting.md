# Troubleshooting

## Terraform apply: permission / AccessDenied errors
**Symptom:** `terraform apply` fails creating the cluster with KMS, CloudWatch Logs, or IAM `AccessDenied`.
**Cause:** Your IAM user/role lacks permissions the EKS module needs (KMS key for secrets encryption, CloudWatch log group for the control plane).
**Fix:** Attach the required permissions (KMS create/describe, `logs:*` for the cluster log group, EKS/EC2/IAM) to your principal, or temporarily disable cluster encryption/log types for a non-production run, then re-apply.

## `kubectl get nodes` → Unauthorized / cannot connect
```bash
aws eks update-kubeconfig --name eventyx-eks --region ap-south-1
rm -rf ~/.kube/cache
# If still unauthorized, create an access entry for your ARN:
YOUR_ARN=$(aws sts get-caller-identity --query Arn --output text)
aws eks create-access-entry --cluster-name eventyx-eks --principal-arn "$YOUR_ARN" --type STANDARD --region ap-south-1
aws eks associate-access-policy --cluster-name eventyx-eks --principal-arn "$YOUR_ARN" \
  --access-scope type=cluster \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --region ap-south-1
```

## ArgoCD app stuck "OutOfSync" / "Missing"
```bash
argocd app diff podinfo
argocd app sync podinfo --force
```
For private repos, add credentials in ArgoCD → Settings → Repositories.

## Pods never reach Running
```bash
kubectl describe pod -n <ns> <pod>
kubectl logs -n <ns> <pod>
```
Common causes: image pull errors, insufficient node resources (SPOT reclaim), missing IRSA permissions.

## Istio pods not 2/2 (sidecar missing)
Ensure the namespace is labelled and pods were restarted after labelling:
```bash
kubectl label namespace <ns> istio-injection=enabled
kubectl rollout restart deployment -n <ns>
```

## Metrics Server / HPA shows `<unknown>`
Patch Metrics Server for EKS kubelet TLS:
```bash
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

## Prometheus not loading custom rules
The `PrometheusRule` must carry the label the Prometheus CR selects on (`release: prometheus` here), or install the stack with `ruleSelectorNilUsesHelmValues: false` (already set in `observability/values-prometheus.yaml`).
