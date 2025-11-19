#!/bin/bash
set -e

# Get script directory to find .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/.kube

echo "Fetching kubeconfig from control plane..."
vagrant ssh control -c "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/vagrant-k8s-config

if [ -f "$SCRIPT_DIR/.env" ]; then
    eval "$(grep -E '^(BRIDGE_NETWORK|CONTROL_IP_PUBLIC|CONTEXT_NAME)=' "$SCRIPT_DIR/.env")"
else
    echo "Warning: .env not found, using defaults"
fi

CONTROL_IP="${BRIDGE_NETWORK}.${CONTROL_IP_PUBLIC}"
echo "Using control plane IP: ${CONTROL_IP}"

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