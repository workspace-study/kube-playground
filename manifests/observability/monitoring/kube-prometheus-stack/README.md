# Envs
```bash
export KUBE_STATE_METRICS_NAMESPACE=monitoring
export KUBE_STATE_METRICS_VERSION=79.5.0
export KUBE_STATE_METRICS_RELEASE_NAME="prometheus-stack"
```

# Add the repo
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

# update the repo
```bash
helm repo update
```

# If need, find for the specfiic version
```bash
helm search repo prometheus-community/kube-prometheus-stack --versions
```

# Install this version
```bash
helm upgrade --install $KUBE_STATE_METRICS_RELEASE_NAME prometheus-community/kube-prometheus-stack \
    --version $KUBE_STATE_METRICS_VERSION \
    -f values.yaml \
    --namespace $KUBE_STATE_METRICS_NAMESPACE \
    --create-namespace
```

# Post install
```bash
kubectl --namespace monitoring get pods -l "release=prometheus-stack"
```
## Get Grafana 'admin' user password by running:
```bash
kubectl --namespace monitoring get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```
## Access Grafana local instance:
```bash
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=prometheus-stack" -oname)
kubectl --namespace monitoring port-forward $POD_NAME 3000
```
## Get your grafana admin user password by running:
```bash
kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
```