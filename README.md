# Vagrant Kubernetes

Table of Content
  * [Requirements](#requirements)
  * [Setup](#setup)
  * [Resource Configuration](#resource-configuration)
  * [Kubernetes version](#kubernetes-version)
  * [Starting](#starting)
  * [Accessing from Host Machine](#accessing-from-host-machine)
  * [Cilium LoadBalancer](#cilium-loadbalancer)
  * [Troubleshooting](#troubleshooting)

A small playground to experiment or play with Kubernetes on multiple Vagrant Ubuntu `ubuntu/jammy64` instances. So do not use this as a base for production like deployments (Kubespray for example).

## Requirements

Please make sure the following is installed before using this repo:

* Ansible; (if in WSL: on linux)
* Vagrant; (if in WSL: on linux)
* VirtualBox; (if in WSL: on Windows)
* Motivation!

### WSL2 + Vagrant
```bash
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"

vagrant plugin install virtualbox_WSL2

sudo tee /etc/wsl.conf > /dev/null <<EOF
[automount]
options = "metadata,umask=22,fmask=11"
EOF
```

## Setup

### Configuration (Optional)

You can customize network settings, VM resources, and LoadBalancer IP pool by creating a `.env` file:

```bash
# Copy the example file
cp .env.example .env

# Edit with your preferences
nano .env
```

**Available configuration options:**

```bash
# Network Configuration
BRIDGE_NETWORK=192.168.1        # Your home network (default)
PRIVATE_NETWORK=192.168.56      # Internal cluster network (default)

# Bridge Adapter (optional - leave empty to be prompted)
# Specify your network adapter to avoid manual selection during vagrant up
# Find adapter name: Get-NetAdapter | Select-Object Name, InterfaceDescription
BRIDGE_ADAPTER=                 # Example: "Killer(R) Wi-Fi 6 AX1650i 160MHz..."

# Control Plane IPs (last octet only)
CONTROL_IP_PUBLIC=50            # Results in: {BRIDGE_NETWORK}.50
CONTROL_IP_PRIVATE=10           # Results in: {PRIVATE_NETWORK}.10

# Worker Node IPs (starting last octet)
WORKER_IP_PUBLIC_START=51       # First worker: {BRIDGE_NETWORK}.51
WORKER_IP_PRIVATE_START=11      # First worker: {PRIVATE_NETWORK}.11

# LoadBalancer IP Pool (last octets)
LB_IP_START=60                  # Pool range: {BRIDGE_NETWORK}.60-99
LB_IP_END=99

# VM Resources
CONTROL_MEMORY=4096
CONTROL_CPUS=2
WORKER_MEMORY=2048
WORKER_CPUS=2
NUM_WORKERS=1
```

**Finding Your Bridge Adapter Name:**

To avoid being prompted for network adapter selection on `vagrant up`, set your bridge adapter in `.env`:

```powershell
# On Windows PowerShell - List available network adapters
Get-NetAdapter | Select-Object Name, InterfaceDescription

# Example output:
# Name                   InterfaceDescription
# ----                   --------------------
# Wi-Fi                  Killer(R) Wi-Fi 6 AX1650i 160MHz Wireless Network Adapter (201NGW)
# Ethernet               Realtek PCIe GbE Family Controller
```

Then add to your `.env` file (use the **InterfaceDescription**):
```bash
BRIDGE_ADAPTER=Killer(R) Wi-Fi 6 AX1650i 160MHz Wireless Network Adapter (201NGW)
```

**Example:** To change your network range and LoadBalancer pool:
```bash
# Edit .env file
echo "BRIDGE_NETWORK=10.0.0" > .env
echo "LB_IP_START=100" >> .env
echo "LB_IP_END=120" >> .env

# Deploy with new configuration
vagrant up
```

### Default Configuration

By default (without a `.env` file), the following is started/installed:

* 1 Control node (4GB RAM, 2 CPUs)
  - Public IP: `{BRIDGE_NETWORK}.{CONTROL_IP_PUBLIC}` (bridged network)
  - Private IP: `{PRIVATE_NETWORK}.{CONTROL_IP_PRIVATE}` (internal cluster network)
* 1 Worker node (2GB RAM, 2 CPUs)
  - Public IP: `{BRIDGE_NETWORK}.{WORKER_IP_PUBLIC_START}` (bridged network)
  - Private IP: `{PRIVATE_NETWORK}.{WORKER_IP_PRIVATE_START}` (internal cluster network)

**Default values:** See `.env.example` for all defaults.

### Network Architecture

This cluster uses **hybrid networking** with two separate networks:

| Network | Type | Interface | Purpose | Configurable Via |
|---------|------|-----------|---------|------------------|
| **Public** | Bridged | enp0s8 | API server access, LoadBalancer services | `BRIDGE_NETWORK` |
| **Private** | Private | enp0s9 | Internal cluster communication, pod traffic | `PRIVATE_NETWORK` |

**Benefits:**
- External services (LoadBalancer) accessible from home network
- Internal cluster traffic isolated and secure
- Better network segmentation
- Production-like architecture

**Customization:** All network settings are configured via `.env` file. See the Configuration section above.

## Resource Configuration

### VM Allocation

| Node | RAM | CPU | For Pods | Configurable Via |
|------|-----|-----|----------|------------------|
| Control | 4GB | 2 | ~3GB | `CONTROL_MEMORY`, `CONTROL_CPUS` |
| Workers | 2GB | 2 | ~1.5GB | `WORKER_MEMORY`, `WORKER_CPUS` |

### Why These Settings?

**Prevents CrashLoopBackOff**: Kubelet is configured with resource reservations to ensure system stability.

**Control Plane reserves**:
- 512Mi for system (OS processes)
- 512Mi for Kubernetes (kubelet, kube-proxy, etc.)

**Workers reserve**:
- 256Mi for system
- 256Mi for Kubernetes

### Eviction Policy

Pods are evicted when resources are low. Current thresholds prevent aggressive eviction:

- **Hard limit**: Evict immediately if memory < 100Mi available
- **Soft limit**: Evict after 1 minute if memory < 150-200Mi available (varies by node type)

**To avoid pod restarts**: Don't schedule pods that use more than the available memory listed above.

# Kubernetes version

Current version: **1.34** (configurable)

Change in `Vagrantfile`:

```ruby
IMAGE_NAME = "ubuntu/jammy64"
K8S_VERSION = "1.34"
```

Change number of workers in `.env`:
```bash
NUM_WORKERS=2  # Add more worker nodes
```

## Starting

Once you are ready, run the following to start everything:

```sh
vagrant up
```

Once everything is booted, use the following command to logon to the control node:

```sh
vagrant ssh control
```

You should be able to run `kubectl get nodes` now.

## Accessing from Host Machine

To access the Kubernetes cluster from your host machine (without SSHing into the VM), you can add the kubeconfig to your existing configuration:

```bash
# 1. Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# 2. Save the vagrant config to a separate file
vagrant ssh control -c "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/vagrant-k8s-config

# 3. Get the control plane IP from .env (or use default)
source .env 2>/dev/null || true
CONTROL_IP="${BRIDGE_NETWORK:-192.168.1}.${CONTROL_IP_PUBLIC:-50}"

# 4. Update the server address to use the bridged network IP
sed -i "s|server: https://[0-9.]*:6443|server: https://${CONTROL_IP}:6443|g" ~/.kube/vagrant-k8s-config

# 5. Add to your KUBECONFIG environment variable (add to ~/.bashrc or ~/.zshrc)
export KUBECONFIG=~/.kube/config:~/.kube/vagrant-k8s-config
```

After this, reload your shell or run `source ~/.bashrc` (or `~/.zshrc`), then verify:

```bash
# List all contexts
kubectl config get-contexts

# Switch to the vagrant cluster context
kubectl config use-context kubernetes-admin@kubernetes

# Optional: Rename the context to something more memorable
kubectl config rename-context kubernetes-admin@kubernetes main-home-cluster

# Test access
kubectl get nodes
```

Now you can switch between different Kubernetes clusters using `kubectl config use-context <context-name>`.

## Cilium LoadBalancer

This cluster is pre-configured with Cilium LoadBalancer support using L2 announcements. LoadBalancer services will automatically receive external IPs from the configured pool.

**IP Pool:** `{BRIDGE_NETWORK}.{LB_IP_START}` to `{BRIDGE_NETWORK}.{LB_IP_END}` (configurable via `.env`)

These IPs are **accessible from any device on your home network**, not just your host machine.

### Testing LoadBalancer

Create a test deployment and expose it as a LoadBalancer service:

```bash
# SSH into the control node
vagrant ssh control

# Create a test nginx deployment
kubectl create deployment nginx --image=nginx

# Expose it as LoadBalancer type
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check the service - you should see an EXTERNAL-IP from the pool
kubectl get svc nginx
```

You should see output like:
```
NAME    TYPE           CLUSTER-IP      EXTERNAL-IP               PORT(S)        AGE
nginx   LoadBalancer   10.96.100.123   {BRIDGE_NETWORK}.{IP}     80:30123/TCP   10s
```

Access the service from **any device on your network** (phone, laptop, tablet):
```bash
# Replace with the actual EXTERNAL-IP from the output above
curl http://<EXTERNAL-IP>

# Or open in your browser: http://<EXTERNAL-IP>
```

### Manually Enabling LoadBalancer (For Existing Clusters)

If you have an existing cluster without LoadBalancer support, you can enable it manually:

```bash
vagrant ssh control

# Load .env variables to get IPs
source /vagrant/.env 2>/dev/null || true
CONTROL_IP="${BRIDGE_NETWORK:-192.168.1}.${CONTROL_IP_PUBLIC:-50}"

# Upgrade Cilium with LoadBalancer features
cilium upgrade \
  --set l2announcements.enabled=true \
  --set l2announcements.leaseDuration=3s \
  --set l2announcements.leaseRenewDeadline=1s \
  --set l2announcements.leaseRetryPeriod=500ms \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=${CONTROL_IP} \
  --set k8sServicePort=6443 \
  --set devices='{enp0s8,enp0s9}'

# Wait for Cilium to be ready
cilium status --wait

# Apply LoadBalancer manifests (auto-generated from .env)
kubectl apply -f /tmp/cilium-lb-ippool.yaml
kubectl apply -f /vagrant/manifests/cilium-l2-announcement.yaml
```

### Configuration Details

- **Network Architecture**: Hybrid (bridged + private)
  - **Public Network**: `{BRIDGE_NETWORK}.0/24` (configured via `.env`)
  - **Private Network**: `{PRIVATE_NETWORK}.0/24` (configured via `.env`)
- **LoadBalancer IP Pool**: `{BRIDGE_NETWORK}.{LB_IP_START}` to `{BRIDGE_NETWORK}.{LB_IP_END}`
- **L2 Announcement Interface**: `enp0s8` (bridged network only)
- **Cilium Device Interfaces**: `enp0s8` (public) and `enp0s9` (private)
- **Manifests**:
  - LoadBalancer IP pool is auto-generated from `.env` variables
  - `manifests/cilium-l2-announcement.yaml` - L2 announcements on bridged interface

### How It Works

1. **API Server**: Listens on all interfaces, advertises on public IP (`{BRIDGE_NETWORK}.{CONTROL_IP_PUBLIC}`)
2. **Kubelet/Nodes**: Register using private IPs (`{PRIVATE_NETWORK}.x`) for internal communication
3. **Pod Traffic**: Routed through private network using VXLAN tunnels
4. **LoadBalancer Services**: Announced on public network, accessible from home network
5. **Cilium L2 Announcements**: Manages both interfaces (enp0s8 and enp0s9) for proper routing

### Customizing Network Configuration

All network configuration is managed via the `.env` file:

```bash
# Example: Change to different network
BRIDGE_NETWORK=10.0.0
PRIVATE_NETWORK=172.16.0

# Example: Different LoadBalancer range
LB_IP_START=100
LB_IP_END=150
```

After changing `.env`, rebuild the cluster:
```bash
vagrant destroy -f
vagrant up
```

## Troubleshooting

### Pods stuck in CrashLoopBackOff

Check node resources:
```bash
kubectl describe nodes
kubectl top nodes  # Requires metrics-server
```

### Check Resource Pressure
```bash
kubectl get nodes -o wide
kubectl describe node control-plane | grep -A 5 "Allocated resources"
```


### Cleanup
```bash
vagrant destroy -f
```