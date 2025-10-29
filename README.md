# Vagrant Kubernetes

Table of Content
  * [Requirements](#requirements)
  * [Setup](#setup)
  * [Kubernetes version](#kubernetes-version)
  * [Starting](#starting)

A small playground to experiment or play with Kubernetes on multiple Vagrant Ubuntu `ubuntu/bionic64` instances. So do not use this as a base for production like deployments (Kubespray for example).

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
```

## Setup

Default the following is started/installed:

* 1 Control node;
* 2 Worker nodes;

Each node has 2 CPU's configured with each 2GB of RAM. You can change this to your needs by updating the `Vagrantfile`.

## Change Cluster Name

Clyster name could be changed inside the file `control-playbook.yaml` in `playbook` dir.

Inside the file, change the line that start on line 5:

```sh
  vars:
    - cluster_name: "<here-cluster-name>""
```

## Kubernetes version

Kubernetes version 1.20.2 which can be changed in the `Vagrantfile` by looking in the top of the file for the line that starts with: `K8S_VERSION`. You can set that to a more recent version of Kubernetes before you start everything.

```ruby
    IMAGE_NAME = "ubuntu/bionic64"
    K8S_VERSION = "1.20.2"
    N = 2
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