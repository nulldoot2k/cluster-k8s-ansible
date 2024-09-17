# -*- mode: ruby -*-
# vi: set ft=ruby :

IP_IW = "192.168.56."
Controller = 2
Worker = 2

def setup_dns(node)
  node.vm.provision "setup-hosts", :type => "shell", :path => "setup/setup-hosts.sh" do |s|
    s.args = ["eth1", node.vm.hostname]
  end
  node.vm.provision "setup-dns", :type => "shell", :path => "setup/setup-dns.sh"
end

def controller_setup(node)
  node.vm.provision "hearbeat", :type => "shell", :path => "setup/heartbeat.sh"
end

def worker_setup(node)
  node.vm.provision "worker-provision", :type => "shell", :path => "setup/worker-provision.sh"
end

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision "shell", path: "setup/bootstrap.sh"
  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
      echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
    SHELL
  end
  
  # Controller
  (0..Controller).each do |i|
    config.vm.define "controller-#{i}" do |node|
      node.vm.hostname = "controller-#{i}"
      node.vm.network :private_network, ip: IP_IW + "1#{i}"
      # node.vm.network :forwarded_port, guest: 22, host: "#{2200 + i}", id: "ssh"
      node.vm.provision :hosts, :sync_hosts => true
      node.vm.provider :virtualbox do |vb|
        vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
        vb.name = "controller-#{i}"
        vb.cpus = 1
        vb.memory = 1024
      end
      setup_dns node
    end
  end

  (0..Worker).each do |i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.hostname = "worker-#{i}"
      node.vm.network :private_network, ip: IP_IW + "2#{i}"
      # node.vm.network :forwarded_port, guest: 22, host: "#{2200 + i}", id: "ssh"
      node.vm.provision :hosts, :sync_hosts => true
      node.vm.provider :virtualbox do |vb|
        vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
        vb.name = "worker-#{i}"
        vb.cpus = 1
        vb.memory = 512
      end
      setup_dns node
    end
  end
end
