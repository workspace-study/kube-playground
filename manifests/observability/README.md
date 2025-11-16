# Observability

## Metrics API (Metrics Server)

The Metrics Server is required for `kubectl top nodes` and `kubectl top pods` commands to work.

### Installation


```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml
```

### For Development/Test Environments (Insecure TLS)

If you're running in a development environment with self-signed certificates, you may need to disable TLS verification:

```bash
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'
```

### Verify Installation

```bash
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# Wait for metrics to be available (may take 1-2 minutes)
kubectl top nodes
```

### Troubleshooting

If `kubectl top nodes` still returns an error:

1. Check metrics-server logs:
   ```bash
   kubectl logs -n kube-system deployment/metrics-server
   ```

2. Ensure metrics-server pod is running:
   ```bash
   kubectl get pods -n kube-system | grep metrics-server
   ```

3. Wait a minute or two for metrics collection to start, then try again.
