NodeScale = 135
IP_IW = "192.168.101."
NodeCount = 3

def setup_dns(node)
  node.vm.provision "setup-hosts", :type => "shell", :path => "setup/setup-hosts.sh" do |s|
    s.args = ["eth1", node.vm.hostname]
  end
  node.vm.provision "setup-dns", :type => "shell", :path => "setup/setup-dns.sh"
end

Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 300
  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision "shell", path: "setup/bootstrap.sh"
  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
      echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
    SHELL
  end
  
  # Node
  (1..NodeCount).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "bento/ubuntu-20.04"
      node.vm.network :private_network, ip: IP_IW + "#{NodeScale + i}"
      node.vm.hostname = "node#{i}"
      node.vm.network :forwarded_port, guest: 22, host: "#{2200 + i}", id: "ssh"
      node.vm.provider :virtualbox do |vb|
        vb.memory = 2048
        vb.cpus = i == 1 ? 2 : 1
      end
      setup_dns node
    end
  end
end
