require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

# add a hub
action :add do
  if @hub.exists
    Chef::Log.info "Hub #{new_resource.name} already exists."
  else
    Chef::Log.info "Creating new hub #{new_resource.name}."
    execute "add a hub" do
      user "zenoss"
      group "zenoss"
      cwd "#{node["zenoss"]["server"]["zenhome"]}/bin"
      environment ({
                  'PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION' => "cpp",
                  'USE_ZENDS' => "1",
                  'LD_LIBRARY_PATH' => "/opt/zends/lib:#{node["zenoss"]["server"]["zenhome"]}/lib",
                  'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
                  'ZENHOME' => node["zenoss"]["server"]["zenhome"],
                  'INSTANCE_HOME' => "#{node["zenoss"]["server"]["zenhome"]}",
                  'PATH' => "/opt/zends/bin:/opt/zenoss/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/zenoss/bin"
                  })
      command "#{node["zenoss"]["server"]["zenhome"]}/bin/dc-admin add-hub --hub-port=8790 --xml-rpc-port=8082 --install-user=zenoss #{new_resource.hub} #{new_resource.hub}"
    end
    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  @hub = Chef::Resource::PlZenossZenhub.new(new_resource.hub)
  Chef::Log.debug("Checking to see if this hub is already setup")
  h = shell_out("sudo -u zenoss -i #{node["zenoss"]["server"]["zenhome"]}/bin/dc-admin --hub-pattern #{new_resource.hub} list")
  exists = h.stdout.include?(new_resource.hub)
  @hub.exists(exists)
end
