# Load environment variables from .env file if it exists
if File.exist?('.env')
  File.readlines('.env').each do |line|
    line.strip!
    next if line.empty? || line.start_with?('#')
    key, value = line.split('=', 2)
    ENV[key] = value if key && value
  end
end

# GENERAL
IMAGE_NAME = "ubuntu/jammy64"

# VERSIONS
K8S_VERSION = "1.34"
CILIUM_VERSION = "1.16.5"

# RESOURCES
CONTROL_PLANE_MEMORY = ENV['CONTROL_MEMORY'] || 4096
CONTROL_PLANE_CPU = ENV['CONTROL_CPUS'] || 2
WORKER_NODE_MEMORY = ENV['WORKER_MEMORY'] || 2048
WORKER_NODE_CPU = ENV['WORKER_CPUS'] || 2
N = ENV['NUM_WORKERS'] ? ENV['NUM_WORKERS'].to_i : 1

# NETWORK
BRIDGE_NETWORK = ENV['BRIDGE_NETWORK'] || "192.168.1"
PRIVATE_NETWORK = ENV['PRIVATE_NETWORK'] || "192.168.56"
BRIDGE_ADAPTER = ENV['BRIDGE_ADAPTER'] && !ENV['BRIDGE_ADAPTER'].empty? ? ENV['BRIDGE_ADAPTER'] : nil
POD_NETWORK = "10.244.0.0/16"
CONTROL_IP_PUBLIC = "#{BRIDGE_NETWORK}.#{ENV['CONTROL_IP_PUBLIC'] || '50'}"
CONTROL_IP_PRIVATE = "#{PRIVATE_NETWORK}.#{ENV['CONTROL_IP_PRIVATE'] || '10'}"
WORKER_IP_PUBLIC_START = ENV['WORKER_IP_PUBLIC_START'] ? ENV['WORKER_IP_PUBLIC_START'].to_i : 51
WORKER_IP_PRIVATE_START = ENV['WORKER_IP_PRIVATE_START'] ? ENV['WORKER_IP_PRIVATE_START'].to_i : 11

# LOADBALANCER
LB_IP_START = "#{BRIDGE_NETWORK}.#{ENV['LB_IP_START'] || '60'}"
LB_IP_END = "#{BRIDGE_NETWORK}.#{ENV['LB_IP_END'] || '99'}"

Vagrant.configure("2") do |config|
    # Increase boot timeout to prevent premature failures
    config.vm.boot_timeout = 600

    # SSH timeout settings
    config.vm.communicator = "ssh"
    config.ssh.connect_timeout = 60

    config.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.customize ["modifyvm", :id, "--audio", "none"]
        v.customize ["modifyvm", :id, "--usb", "off"]
        v.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
        v.customize ["modifyvm", :id, "--uartmode1", "disconnected"]

        # Performance optimizations
        v.customize ["modifyvm", :id, "--ioapic", "on"]
        v.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end

    config.vm.define "control" do |control|
        control.vm.box = IMAGE_NAME
        if BRIDGE_ADAPTER
            control.vm.network "public_network", ip: CONTROL_IP_PUBLIC, bridge: BRIDGE_ADAPTER
        else
            control.vm.network "public_network", ip: CONTROL_IP_PUBLIC
        end
        control.vm.network "private_network", ip: CONTROL_IP_PRIVATE
        control.vm.hostname = "control"
        control.vm.provider "virtualbox" do |v|
            v.memory = CONTROL_PLANE_MEMORY
            v.cpus = CONTROL_PLANE_CPU
            v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
        end
        control.vm.provision "ansible" do |ansible|
            ansible.playbook = "./playbooks/control-playbook.yml"
            ansible.extra_vars = {
                node_ip_public: CONTROL_IP_PUBLIC,
                node_ip_private: CONTROL_IP_PRIVATE,
                k8s_version: K8S_VERSION,
                pod_network: POD_NETWORK,
                cilium_version: CILIUM_VERSION,
                lb_ip_start: LB_IP_START,
                lb_ip_end: LB_IP_END,
                bridge_network: BRIDGE_NETWORK,
            }
        end
    end

    (1..N).each do |i|
        config.vm.define "worker-#{i}" do |worker|
            worker.vm.box = IMAGE_NAME
            if BRIDGE_ADAPTER
                worker.vm.network "public_network", ip: "#{BRIDGE_NETWORK}.#{WORKER_IP_PUBLIC_START + i - 1}", bridge: BRIDGE_ADAPTER
            else
                worker.vm.network "public_network", ip: "#{BRIDGE_NETWORK}.#{WORKER_IP_PUBLIC_START + i - 1}"
            end
            worker.vm.network "private_network", ip: "#{PRIVATE_NETWORK}.#{WORKER_IP_PRIVATE_START + i - 1}"
            worker.vm.hostname = "worker-#{i}"
            worker.vm.provider "virtualbox" do |v|
                v.memory = WORKER_NODE_MEMORY
                v.cpus = WORKER_NODE_CPU
                v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
            end

            worker.vm.provision "ansible" do |ansible|
                ansible.playbook = "./playbooks/worker-playbook.yml"
                ansible.extra_vars = {
                    node_ip_public: "#{BRIDGE_NETWORK}.#{WORKER_IP_PUBLIC_START + i - 1}",
                    node_ip_private: "#{PRIVATE_NETWORK}.#{WORKER_IP_PRIVATE_START + i - 1}",
                    k8s_version: K8S_VERSION,
                    bridge_network: BRIDGE_NETWORK,
                }
            end
        end
    end
end