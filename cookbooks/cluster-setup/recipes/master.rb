include_recipe 'apache_zookeeper'
include_recipe 'mesos::master'
include_recipe 'marathon'
include_recipe 'marathon::service'
