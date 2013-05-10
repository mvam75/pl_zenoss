require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

# add a collector
action :add do
  if @collector.exists
    Chef::Log.info "Collector #{new_resource.collector} already exists."
  else
    Chef::Log.info "Creating new collector #{new_resource.name}. This may take a while."
    execute "add a collector" do
      user "zenoss"
      group "zenoss"
      cwd "#{node["zenoss"]["server"]["zenhome"]}/bin"
      environment ({
                  'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
                  'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
                  'ZENHOME' => node["zenoss"]["server"]["zenhome"],
                  'PATH' => "/opt/zends/bin:/opt/zenoss/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/zenoss/bin"
                  })
      command "#{node["zenoss"]["server"]["zenhome"]}/bin/dc-admin add-collector --collector-host #{new_resource.collector} --install-user=zenoss #{new_resource.collector} #{new_resource.hub}"
    end
    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  @collector = Chef::Resource::PlZenossZencollector.new(new_resource.collector)
  Chef::Log.debug("Checking to see if this collector is already setup")
  c = shell_out("sudo -u zenoss -i #{node["zenoss"]["server"]["zenhome"]}/bin/dc-admin --collector-pattern #{new_resource.collector} list")
  exists = c.stdout.include?(new_resource.collector)
  @collector.exists(exists)
end
