action :start do
  Chef::Log.info "Starting daemon #{new_resource.name} now"

  execute "zencatalogservice start #{new_resource.name}" do
    user "zenoss"
    cwd "/opt/zenoss/bin"
    environment ({
                 'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
                 'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
                 'ZENHOME' => node["zenoss"]["server"]["zenhome"]
                })
    command "#{node["zenoss"]["server"]["zenhome"]}/bin/zencatalogservice start #{new_resource.name}"
    new_resource.updated_by_last_action(true)
  end
end

action :restart do
  Chef::Log.info "Restarting daemon #{new_resource.name} now"

  execute "zencatalogservice restart #{new_resource.name}" do
    user "zenoss"
    cwd "/opt/zenoss/bin"
    environment ({
                 'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
                 'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
                 'ZENHOME' => node["zenoss"]["server"]["zenhome"]
                })
    command "#{node["zenoss"]["server"]["zenhome"]}/bin/zencatalogservice restart #{new_resource.name}"
    new_resource.updated_by_last_action(true)
  end
end

action :stop do
  Chef::Log.info "Stopping daemon #{new_resource.name} now"

  execute "zencatalogservice stop #{new_resource.name}" do
    user "zenoss"
    cwd "/opt/zenoss/bin"
    environment ({
                 'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
                 'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
                 'ZENHOME' => node["zenoss"]["server"]["zenhome"]
                })
    command "#{node["zenoss"]["server"]["zenhome"]}/bin/zencatalogservice stop #{new_resource.name}"
  end
end

action :status do
  Chef::Log.info "Checking status of #{new_resource.name} now"

  execute "zencatalogservice status #{new_resource.name}" do
    user "zenoss"
    cwd "/opt/zenoss/bin"
    environment ({
                 'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
                 'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
                 'ZENHOME' => node["zenoss"]["server"]["zenhome"]
                })
    command "#{node["zenoss"]["server"]["zenhome"]}/bin/zencatalogservice status #{new_resource.name}"
  end
end

action :zenstatus do
  Chef::Log.info "Checking status of #{new_resource.name} now"

  execute "/sbin/service #{new_resource.name} status" do
    user "zenoss"
    environment ({
               'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
               'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
               'ZENHOME' => node["zenoss"]["server"]["zenhome"]
               })
    command "/sbin/service zenoss status"
  end
end

=begin
def load_current_resource
  @zs = Chef::Resource::ZenossService.new(new_resource.name)
  @zs.service_name(new_resource.service_name)

  Chef::Log.debug("Checking status of service #{new_resource.service_name}")

  begin
    if run_command_with_systems_locale(:command => "/sbin/service #{new_resource.service_name} status") == 0
      @zs.running(true)
    end
  rescue Chef::Exceptions::Exec
    @zs.running(false)
    nil
  end
end
=end
