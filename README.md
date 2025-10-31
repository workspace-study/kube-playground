# Vagrant Kubernetes

Table of Content
  * [Requirements](#requirements)
  * [Setup](#setup)
  * [Resource Configuration](#resource-configuration)
  * [Kubernetes version](#kubernetes-version)
  * [Starting](#starting)
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

Default the following is started/installed:

* 1 Control node (4GB RAM, 2 CPUs)
* 1 Worker node (2GB RAM, 2 CPUs)

You can change this to your needs by updating the `Vagrantfile` and adjusting `N` variable for more workers.

## Resource Configuration

### VM Allocation

| Node | RAM | CPU | For Pods |
|------|-----|-----|----------|
| Control | 4GB | 2 | ~3GB |
| Workers | 2GB | 2 | ~1.5GB |

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

### Files Modified
- VM resources: `Vagrantfile`
- Control kubelet: `playbooks/control-playbook.yml` (lines 123-167)
- Worker kubelet: `playbooks/worker-playbook.yml` (lines 123-128)

## Change Cluster Name

Clyster name could be changed inside the file `control-playbook.yaml` in `playbook` dir.

Inside the file, change the line that start on line 5:

```sh
  vars:
    - cluster_name: "<here-cluster-name>""
```

## Kubernetes version

Current version: **1.34** (configurable)

Change in `Vagrantfile`:

```ruby
IMAGE_NAME = "ubuntu/jammy64"
K8S_VERSION = "1.34"
N = 1  # Number of worker nodes
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

### Rebuild Cluster
```bash
vagrant destroy -f
vagrant up
```