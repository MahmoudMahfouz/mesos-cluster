docker_service 'default' do
  action [:create, :start]
  version '1.5.0'
end

include_recipe 'mesos::slave'
include_recipe 'consul'
