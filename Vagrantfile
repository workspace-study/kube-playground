IMAGE_NAME = "generic/rocky9"
K8S_VERSION = "1.34.1"
HELM_VERSION = "3.19.0"
N = 1

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false

    config.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 2
        v.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
    end

    config.vm.define "control" do |control|
        control.vm.box = IMAGE_NAME
        control.vm.network "private_network", ip: "192.168.56.10"
        control.vm.hostname = "control"
        config.vm.synced_folder "examples/resources/", "/opt/resources"

        control.vm.provision "ansible" do |ansible|
            ansible.playbook = "./playbooks/control-playbook.yml"
            ansible.extra_vars = {
                node_ip: "192.168.56.10",
                k8s_version: K8S_VERSION,
                helm_version: HELM_VERSION,
                ansible_python_interpreter: "/usr/bin/python3",
            }
        end
    end

    (1..N).each do |i|
        config.vm.define "worker-#{i}" do |worker|
            worker.vm.box = IMAGE_NAME
            worker.vm.network "private_network", ip: "192.168.56.#{i + 10}"
            worker.vm.hostname = "worker-#{i}"
            worker.vm.provision "ansible" do |ansible|
                ansible.playbook = "./playbooks/worker-playbook.yml"
                ansible.extra_vars = {
                    control_node_ip: "192.168.56.10",
                    node_ip: "192.168.56.#{i + 10}",
                    k8s_version: K8S_VERSION,
                    ansible_python_interpreter: "/usr/bin/python3",
                }
            end
        end
    end
end