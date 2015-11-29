# -*- mode: ruby -*-
# vi: set ft=ruby :

conf = {
  masters: {
    mem: 1024,
    cpu: 1,
    ip_start: "100.0.10.11",
    count: 3,
    zk: {
      election_port: 3888,
      follower_port: 2888
    }
  },
 slaves: {
    mem: 786,
    cpu: 1,
    ip_start: "100.0.10.101",
    count:4 
  }
}
require "ipaddr"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.

  #### MASTERS ####

  (1..conf[:masters][:count]).each do |i|
    name = "mesos-masters-#{i}"
    config.vm.define name do |cfg|

      #### PROVIDER CONFIG ####

      cfg.vm.provider :virtualbox do |vb|
        vb.name = "vagrant-#{name}"
        vb.customize ["modifyvm", :id, "--memory", conf[:masters][:mem], "--cpus", conf[:masters][:cpu], "--hwvirtex", "on"]
      end

      cfg.vm.box = "trusty64"
      cfg.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64    -vagrant-disk1.box"
      cfg.vm.network :private_network, ip: get_current_ip(conf[:masters][:ip_start], i)
      cfg.vm.hostname = name

      #### PROVISIONING CONFIG ####

      cfg.vm.provision "chef_solo" do |chef|
        mesos_zk = mesos_zookeerpers_host(conf[:masters][:ip_start], 2181, conf[:masters][:count])
        zk_cfg = zookeepers_servers(conf[:masters][:ip_start], conf[:masters][:count], conf[:masters][:zk][:follower_port], conf[:masters][:zk][:election_port])
        chef.add_recipe "apache_zookeeper"
        chef.add_recipe "mesos::master"
        chef.add_recipe "marathon"
        chef.add_recipe "marathon::service"
        #chef.add_recipe "hostname::default"
        chef.json = {
          set_fqdn: "#{name}.ibg.dev",
          hostname_cookbook: {
            hostsfile_ip: get_current_ip(conf[:masters][:ip_start], i) 
          },
          apache_zookeeper: {
            "zoo.cfg" => zk_cfg
          },
          zookeeper: {
            servers: zookeerpers_hosts_array(conf[:masters][:ip_start], conf[:masters][:count]),
            follower_port: conf[:masters][:zk][:follower_port] ,
            election_port: conf[:masters][:zk][:election_port] 
          },
          mesos: {
            master:{
              flags: {
                :port    => "5050",
                :log_dir => "/var/log/mesos",
                :zk      => "zk://#{mesos_zk}/mesos",
                :cluster => "ibg-test-cluster",
                :quorum  => "2"
              } 
            },
            mesosphere: {
              with_zookeeper: true
            }
          },
          marathon:{
            flags: {
              master: "zk://#{mesos_zk}/mesos",
              zk: "zk://#{mesos_zk}/marathon"
            }
          }
        }
      end
    end
  end

  #### SLAVES ####
  (1..conf[:slaves][:count]).each do |i|
    name = "mesos-slaves-#{i}"
    config.vm.define name do |cfg|

      #### PROVIDER CONFIG ####

      cfg.vm.provider :virtualbox do |vb|
        vb.name = "vagrant-#{name}"
        vb.customize ["modifyvm", :id, "--memory", conf[:slaves][:mem], "--cpus", conf[:slaves][:cpu], "--hwvirtex", "on"]
      end 

      cfg.vm.box = "trusty64"
      cfg.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64    -vagrant-disk1.box"
      cfg.vm.network :private_network, ip: get_current_ip(conf[:slaves][:ip_start], i)
      cfg.vm.hostname = name

      #### PROVISIONING CONFIG ####

      cfg.vm.provision "chef_solo" do |chef|
        chef.add_recipe "mesos::slave"
        #chef.add_recipe "hostname::default"
        mesos_zk = mesos_zookeerpers_host(conf[:masters][:ip_start], 2181, conf[:masters][:count])
        chef.json = {
          set_fqdn: "#{name}.ibg.dev",
          hostname_cookbook: {
            hostsfile_ip: get_current_ip(conf[:slaves][:ip_start], i) 
          },
          mesos: {
            slave:{
              flags: {
                :master      => "zk://#{mesos_zk}/mesos",
              } 
            }
          }
        }
      end
    end
  end
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end

def mesos_zookeerpers_host (starting_ip, port, count)
  masters_array = []
  ip_current = IPAddr.new starting_ip
  count.times { 
    masters_array << "#{ip_current.to_string}:#{port}"
    ip_current = ip_current.succ
  }
  masters_array.join(",")
end

def zookeerpers_hosts_array (starting_ip, count)
  masters_array = []
  ip_current = IPAddr.new starting_ip
  count.times { 
    masters_array << "#{ip_current.to_string}"
    ip_current = ip_current.succ
  }
  masters_array
end

def get_current_ip (ip_start, index)
  ip_current = IPAddr.new ip_start
  (index-1).times {ip_current = ip_current.succ}
  ip_current.to_string
end

def zookeepers_servers(ip_start, count, follow_port, elected_port)
  ip_current = IPAddr.new ip_start
  ret = {}
  (count).times do |i| 
    ret["server.#{i+1}"] = "#{ip_current.to_string}:#{follow_port}:#{elected_port}" 
    ip_current = ip_current.succ
  end
  ret
end
