# Simple Kubernetes Lab - Ubuntu 22.04
IMAGE_NAME = "ubuntu/jammy64"
K8S_VERSION = "1.34"
N = 1

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false

    config.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.customize ["modifyvm", :id, "--audio", "none"]
        v.customize ["modifyvm", :id, "--usb", "off"]
        v.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
        v.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
    end

    config.vm.define "control" do |control|
        control.vm.box = IMAGE_NAME
        control.vm.network "private_network", ip: "192.168.56.10"
        control.vm.hostname = "control"
        control.vm.provider "virtualbox" do |v|
            v.memory = 4096
            v.cpus = 2
        end
        control.vm.provision "ansible" do |ansible|
            ansible.playbook = "./playbooks/control-playbook.yml"
            ansible.extra_vars = {
                node_ip: "192.168.56.10",
                k8s_version: K8S_VERSION,
                pod_network: "10.244.0.0/16",
            }
        end
    end

    (1..N).each do |i|
        config.vm.define "worker-#{i}" do |worker|
            worker.vm.box = IMAGE_NAME
            worker.vm.network "private_network", ip: "192.168.56.#{i + 10}"
            worker.vm.hostname = "worker-#{i}"
            worker.vm.provider "virtualbox" do |v|
                v.memory = 2048
                v.cpus = 2
            end

            worker.vm.provision "ansible" do |ansible|
                ansible.playbook = "./playbooks/worker-playbook.yml"
                ansible.extra_vars = {
                    node_ip: "192.168.56.#{i + 10}",
                    k8s_version: K8S_VERSION,
                }
            end
        end
    end
end