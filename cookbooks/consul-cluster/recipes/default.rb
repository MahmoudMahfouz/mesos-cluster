#
# Cookbook: consul-cluster
# License: Apache 2.0
#
# Copyright 2015 Bloomberg Finance L.P.
#
include_recipe 'consul::default'

directory "#{node['consul']['config']['data_dir']}/raft" do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

file "#{node['consul']['config']['data_dir']}/raft/peers.json" do
  content "#{node['consul']['ips'].split(',')}"
  mode '0755'
end

directory "#{node['consul']['config']['ui_dir']}" do
  action :delete
  recursive true
  only_if { File.exist? "#{node['consul']['config']['ui_dir']}" }
end

directory "#{node['consul']['config']['ui_dir']}" do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

execute 'Setup UI' do
  cwd "#{node['consul']['config']['ui_dir']}"
  command "wget https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_web_ui.zip && unzip consul_0.6.4_web_ui.zip"
end
