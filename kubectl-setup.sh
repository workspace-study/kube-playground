#!/bin/bash
set -e

mkdir -p ~/.kube

echo "Fetching kubeconfig from control plane..."
vagrant ssh control -c "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/vagrant-k8s-config

if [ ! -s ~/.kube/vagrant-k8s-config ]; then
    echo "Error: Failed to fetch kubeconfig from control plane"
    exit 1
fi

source .env 2>/dev/null || true
CONTROL_IP="${BRIDGE_NETWORK}.${CONTROL_IP_PUBLIC}"

echo "Updating server IP to ${CONTROL_IP}:6443..."
sed -i "s|server: https://[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+:6443|server: https://${CONTROL_IP}:6443|g" ~/.kube/vagrant-k8s-config

# Merge kubeconfigs
export KUBECONFIG=~/.kube/config:~/.kube/vagrant-k8s-config

if kubectl config get-contexts ${CONTEXT_NAME} &>/dev/null; then
    echo "Context '${CONTEXT_NAME}' already exists, using it..."
    kubectl config use-context ${CONTEXT_NAME}
else
    echo "Setting up context as '${CONTEXT_NAME}'..."
    kubectl config use-context kubernetes-admin@kubernetes
    kubectl config rename-context kubernetes-admin@kubernetes ${CONTEXT_NAME}
fi

echo ""
echo "kubectl is now configured to access your Vagrant cluster"
echo ""
echo "Current context: $(kubectl config current-context)"
echo "Cluster info:"
kubectl cluster-info