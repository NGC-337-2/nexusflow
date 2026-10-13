# Observability Stack

Four pillars: **metrics** (Prometheus), **dashboards** (Grafana), **tracing** (Jaeger), **logs** (Fluent Bit).

## 1. Prometheus + Grafana + Alertmanager

```bash
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f observability/values-prometheus.yaml
```

Apply the custom alert rules (8 alerts across 3 groups: error-rate, latency, resource-saturation):

```bash
kubectl apply -f observability/prometheus-rules.yaml
kubectl get prometheusrule -n monitoring
```

Access Grafana (admin / admin123):

```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
# http://localhost:3000
```

Access Prometheus:

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# http://localhost:9090
```

## 2. Jaeger (distributed tracing)

Installed via the Istio addon (matches Istio 1.20 in this project):

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml
kubectl port-forward svc/tracing -n istio-system 16686:80
# http://localhost:16686
```

## 3. Grafana Istio dashboards (addon, optional)

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml
```

## 4. Fluent Bit (log aggregation)

```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

helm install fluent-bit fluent/fluent-bit \
  -n monitoring \
  -f observability/fluent-bit-values.yaml

kubectl logs -f -n monitoring -l app.kubernetes.io/name=fluent-bit | head -50
```

## Useful PromQL

| Question | Query |
|----------|-------|
| CPU per pod | `sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)` |
| Mem available per node | `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100` |
| Istio request rate | `rate(istio_requests_total[5m])` |
| Istio 5xx error ratio | `rate(istio_requests_total{response_code=~"5.."}[5m]) / rate(istio_requests_total[5m])` |
