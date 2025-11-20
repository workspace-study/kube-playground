#!/bin/bash
set -e

echo "Applying Gateway..."
kubectl apply -f gateway.yaml

echo "Applying Grafana HTTPRoute..."
envsubst < grafana-http-route.yaml | kubectl apply -f -

echo "Applying Prometheus HTTPRoute..."
envsubst < prometheus-http-route.yaml | kubectl apply -f -

echo "Applying Alertmanager HTTPRoute..."
envsubst < alertmanager-http-route.yaml | kubectl apply -f -

echo ""
echo "All routes applied successfully!"
echo ""