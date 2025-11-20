#!/bin/bash
set -e

# Apply Gateway API routes with environment variable substitution

if [ -z "$HOMELAB_DOMAIN" ]; then
  echo "Error: HOMELAB_DOMAIN environment variable is not set"
  echo "Usage: export HOMELAB_DOMAIN=your.domain && $0"
  echo "Or:    source .env && $0"
  exit 1
fi

echo "Using domain: $HOMELAB_DOMAIN"
echo ""

# Apply Gateway (no substitution needed)
echo "Applying Gateway..."
kubectl apply -f gateway.yaml

# Apply HTTPRoutes with environment variable substitution
echo "Applying Grafana HTTPRoute..."
envsubst < grafana-http-route.yaml | kubectl apply -f -

echo "Applying Prometheus HTTPRoute..."
envsubst < prometheus-http-route.yaml | kubectl apply -f -

echo "Applying Alertmanager HTTPRoute..."
envsubst < alertmanager-http-route.yaml | kubectl apply -f -

echo ""
echo "✅ All routes applied successfully!"
echo ""
echo "Routes configured:"
echo "  - grafana.$HOMELAB_DOMAIN"
echo "  - prometheus.$HOMELAB_DOMAIN"
echo "  - alertmanager.$HOMELAB_DOMAIN"
