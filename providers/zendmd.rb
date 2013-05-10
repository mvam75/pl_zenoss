#runs a command via zendmd
action :run do
  Chef::Log.info "zenoss_zendmd:#{new_resource.name}"
  Chef::Log.debug "#{new_resource.command}"
  #write the content to a temp file
  dmdscript = "#{rand(1000000)}.dmd"
  file "/tmp/#{dmdscript}" do
    backup false
    owner "zenoss"
    mode "0600"
    content new_resource.command
    action :create
  end
  #run the command as the zenoss user
  execute "zendmd" do
    user "zenoss"
    cwd "/tmp"
    environment ({
                   'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
                   'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
                   'ZENHOME' => node["zenoss"]["server"]["zenhome"]
                 })
    command "#{node["zenoss"]["server"]["zenhome"]}/bin/zendmd --commit --script=#{dmdscript}"
    action :run
  end
  #remove the temp file
  file "/tmp/#{dmdscript}" do
    action :delete
  end
end
