# Gateway API Setup

Single LoadBalancer gateway for routing multiple services via DNS hostnames.

## Prerequisites

- Cilium CNI installed with Gateway API enabled
- kubectl access to the cluster

## Installation

### 1. Install Gateway API CRDs

Cilium requires the experimental Gateway API CRDs (includes GRPCRoute and TLSRoute):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/experimental-install.yaml
```

### 2. Verify GatewayClass

```bash
kubectl get gatewayclass
# Should show: cilium with ACCEPTED=True
```

## Configuration

### Set Your Domain

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and set your domain:

```bash
HOMELAB_DOMAIN=your.domain
```

**Note:** `.env` is gitignored and won't be committed.

## Deployment

### Apply Gateway and Routes

```bash
source .env && ./apply-routes.sh
```

Or manually:

```bash
export HOMELAB_DOMAIN=your.domain

# Apply Gateway
kubectl apply -f gateway.yaml

# Apply HTTPRoutes with substitution
envsubst < grafana-http-route.yaml | kubectl apply -f -
envsubst < prometheus-http-route.yaml | kubectl apply -f -
envsubst < alertmanager-http-route.yaml | kubectl apply -f -
```

## Verification

### Check Gateway Status

```bash
kubectl get gateway observability-gateway -n monitoring
```

Expected output:
```
NAME                    CLASS    ADDRESS        PROGRAMMED   AGE
observability-gateway   cilium   192.168.X.XX   True         1m
```

### Check HTTPRoutes

```bash
kubectl get httproute -n monitoring
kubectl describe httproute grafana -n monitoring
```

### Get LoadBalancer IP

```bash
kubectl get gateway observability-gateway -n monitoring -o jsonpath='{.status.addresses[0].value}'
```

## DNS Configuration

Point all hostnames to the Gateway LoadBalancer IP:

```
grafana.$HOMELAB_DOMAIN      -> <LOADBALANCER-IP>
prometheus.$HOMELAB_DOMAIN   -> <LOADBALANCER-IP>
alertmanager.$HOMELAB_DOMAIN -> <LOADBALANCER-IP>
```

Or use wildcard DNS:

```
*.$HOMELAB_DOMAIN -> <LOADBALANCER-IP>
```

## Testing

```bash
# Test with curl
curl -I http://grafana.$HOMELAB_DOMAIN
curl -I http://prometheus.$HOMELAB_DOMAIN
curl -I http://alertmanager.$HOMELAB_DOMAIN

# Or open in browser
open http://grafana.$HOMELAB_DOMAIN
```

## Adding New Services

Create a new HTTPRoute:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-service
  namespace: monitoring
spec:
  parentRefs:
  - name: observability-gateway
  hostnames:
  - "myservice.${HOMELAB_DOMAIN}"
  rules:
  - backendRefs:
    - name: my-service-name
      port: 8080
```

Apply:

```bash
envsubst < my-service-http-route.yaml | kubectl apply -f -
```

## Architecture

```
                     ┌─────────────────────┐
                     │   LoadBalancer IP   │
                     │   192.168.X.XX      │
                     └──────────┬──────────┘
                                │
                     ┌──────────▼──────────┐
                     │  Cilium Gateway     │
                     │  (Port 80)          │
                     └──────────┬──────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
    ┌─────────▼────────┐ ┌─────▼──────┐ ┌───────▼────────┐
    │ grafana.domain   │ │ prometheus │ │ alertmanager   │
    │   HTTPRoute      │ │ HTTPRoute  │ │   HTTPRoute    │
    └─────────┬────────┘ └─────┬──────┘ └───────┬────────┘
              │                 │                 │
    ┌─────────▼────────┐ ┌─────▼──────┐ ┌───────▼────────┐
    │ Grafana Service  │ │ Prometheus │ │ Alertmanager   │
    │   (Port 80)      │ │  (Port 90) │ │  (Port 9093)   │
    └──────────────────┘ └────────────┘ └────────────────┘
```

## Troubleshooting

### Gateway stuck in "Unknown" or "Pending"

Check operator logs:

```bash
kubectl logs -n kube-system deployment/cilium-operator --tail=50 | grep gateway
```

Common issue: Missing Gateway API CRDs. Install experimental CRDs.

### HTTPRoute not attaching

Verify service exists:

```bash
kubectl get svc -n monitoring
```

Check HTTPRoute status:

```bash
kubectl describe httproute <name> -n monitoring
```

### DNS not resolving

Verify LoadBalancer has external IP:

```bash
kubectl get svc -n monitoring -l "gateway.networking.k8s.io/gateway-name=observability-gateway"
```

Test with curl using IP directly:

```bash
curl -H "Host: grafana.$HOMELAB_DOMAIN" http://<LOADBALANCER-IP>
```

## Files

- `gateway.yaml` - Gateway resource (1 LoadBalancer)
- `*-http-route.yaml` - HTTPRoute resources (hostname-based routing)
- `.env.example` - Template for domain configuration
- `apply-routes.sh` - Helper script to apply routes with env var substitution
- `.gitignore` - Prevents `.env` from being committed
