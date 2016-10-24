# -*- mode: ruby -*-
# vi: set ft=ruby :

conf = {
  masters: {
    mem: 1024,
    cpu: 1,
    count: 3,
    ip_start: "192.168.3.50",
    zk: {
      election_port: 3888,
      follower_port: 2888
    }
  },
 slaves: {
    mem: 4096,
    ip_start: "192.168.3.200",
    cpu: 2,
    count: 2
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
    name = "m-#{i}"
    ip = get_current_ip(conf[:masters][:ip_start], i)
    config.vm.define name do |cfg|

      #### PROVIDER CONFIG ####
      config.vm.box = "dummy"
      cfg.vm.provider :aws do |aws, override|
        aws.instance_type = 'm3.medium'
        aws.keypair_name = 'instabug'
        aws.region = 'us-east-1'

        aws.tags = {
          'Name' => name,
        }
        aws.security_groups = ['vagrant']

        aws.ami = 'ami-2d39803a' # Ubuntu
        override.ssh.username = 'ubuntu'
        override.ssh.private_key_path = '/Users/mm/.ssh/instabug.pem'

        # aws.ami = 'ami-6d1c2007' # centos
        # override.ssh.username = 'centos'
      end
      # cfg.vm.provider :virtualbox do |vb|
      #   vb.name = "vagrant-#{name}"
      #   vb.customize ["modifyvm", :id, "--memory", conf[:masters][:mem], "--cpus", conf[:masters][:cpu], "--hwvirtex", "on"]
      # end

      # cfg.vm.box = "trusty64"
      # cfg.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
      cfg.vm.network "private_network", ip: ip
      cfg.vm.hostname = name

      #### PROVISIONING CONFIG ####

      cfg.vm.provision "chef_solo" do |chef|
        zk = ip_with_port(conf[:masters][:ip_start], 2181, conf[:masters][:count])
        zk_full = zookeepers_servers(conf[:masters][:ip_start], conf[:masters][:count], conf[:masters][:zk][:follower_port], conf[:masters][:zk][:election_port])

        chef.add_recipe "cluster-setup::master"
        chef.json = {
          apache_zookeeper: {
            "zoo.cfg" => zk_full
          },
          consul: {
            ips: ip_with_port(conf[:masters][:ip_start], 8300, conf[:masters][:count]),
            config: {
            bind_addr: ip,
            bootstrap_expect: 3,
            data_dir: '/etc/consul/conf.d',
            domain: 'consul',
            log_level: 'INFO',
            recursor: '8.8.8.8',
            rejoin_after_leave: true,
            retry_join: ip_array(conf[:masters][:ip_start], conf[:masters][:count]),
            server: true,
            ui: true,
            ui_dir: '/opts/consul/ui',
          }
          },
          zookeeper: {
            servers: ip_array(conf[:masters][:ip_start], conf[:masters][:count]),
            follower_port: conf[:masters][:zk][:follower_port],
            election_port: conf[:masters][:zk][:election_port]
          },
          mesos: {
            version: '1.0.1',
            master: {
            flags: {
              :port    => "5050",
              :log_dir => "/var/log/mesos",
              :zk      => "zk://#{zk}/mesos",
              :cluster => "ibg-test-cluster",
              :quorum  => "2",
              :ip => ip,
              :hostname => ip,
            }
          }
          },
          marathon: {
            version: '1.1.1',
            flags: {
            master: "zk://#{zk}/mesos",
            zk: "zk://#{zk}/marathon",
            hostname: ip
          }
          }
        }
      end
    end
  end

  #### SLAVES ####
  (1..conf[:slaves][:count]).each do |i|
    name = "mesos-slaves-#{i}"
    ip =  get_current_ip(conf[:slaves][:ip_start], i)
    config.vm.define name do |cfg|

      #### PROVIDER CONFIG ####
      config.vm.box = "dummy"

      cfg.vm.provider :aws do |aws, override|
        aws.instance_type = 'm3.medium'
        aws.keypair_name = 'instabug'
        aws.region = 'us-east-1'

        aws.tags = {
          'Name' => name,
        }
        aws.security_groups = ['vagrant']

        aws.ami = 'ami-2d39803a' # Ubuntu
        override.ssh.username = 'ubuntu'
        override.ssh.private_key_path = '/Users/mm/.ssh/instabug.pem'

        # aws.ami = 'ami-6d1c2007' # centos
        # override.ssh.username = 'centos'
      end
      # cfg.vm.provider :virtualbox do |vb|
      #   vb.name = "vagrant-#{name}"
      #   vb.customize ["modifyvm", :id, "--memory", conf[:slaves][:mem], "--cpus", conf[:slaves][:cpu], "--hwvirtex", "on"]
      # end

      # cfg.vm.box = "trusty64"
      # cfg.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
      cfg.vm.network "private_network", ip: ip
      cfg.vm.hostname = name

      #### PROVISIONING CONFIG ####

      cfg.vm.provision "chef_solo" do |chef|
        #chef.add_recipe "mesos::slave"
        chef.add_recipe "cluster-setup::slave"
        zk = ip_with_port(conf[:masters][:ip_start], 2181, conf[:masters][:count])
        chef.json = {
          consul: {
            config: {
              start_join: ip_array(conf[:masters][:ip_start], conf[:masters][:count]),
            }
          },
          mesos: {
            version: '1.0.1',
            slave: {
              flags: {
                master: "zk://#{zk}/mesos",
                ip: ip,
                hostname: ip,
                containerizers: 'docker,mesos'
              }
            }
          }
        }
      end
    end
  end
end

def ip_with_port (starting_ip, port, count)
  masters_array = []
  ip_current = IPAddr.new starting_ip
  count.times {
    masters_array << "#{ip_current.to_string}:#{port}"
    ip_current = ip_current.succ
  }
  masters_array.join(",")
end

def ip_array (starting_ip, count)
  ret = []
  ip_current = IPAddr.new starting_ip
  count.times {
    ret << "#{ip_current.to_string}"
    ip_current = ip_current.succ
  }
  ret
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
