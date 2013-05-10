#
# Cookbook Name:: pl_zenoss
# Recipe:: client
#
# Copyright 2013, thePlatform
#
# All rights reserved - Do Not Redistribute
#

#create a 'zenoss' user for monitoring
user "zenoss" do
  comment "Zenoss monitoring account"
  home "/home/zenoss"
  supports :manage_home => true
  shell "/bin/bash"
  action :create
end

directory "home/zenoss" do
  owner "zenoss"
  mode "0755"
end

#create a home directory for them
directory "/home/zenoss/.ssh" do
  owner "zenoss"
  mode "0700"
  action :create
end

#get the zenoss user public key via search
server = search(:node, 'role:zenoss_res_mgr AND chef_environment:' + node.chef_environment) || []
if server.length > 0
  zenoss = server[0]["zenoss"]
  if zenoss["server"] and zenoss["server"]["zenoss_pubkey"]
    pubkey = zenoss["server"]["zenoss_pubkey"]
    file "/home/zenoss/.ssh/authorized_keys" do
      backup false
      owner "zenoss"
      mode "0600"
      content pubkey
      action :create
    end
  else
    Chef::Log.info("No Zenoss server found, device is unmonitored.")
  end
else
  Chef::Log.info("No Zenoss server found, device is unmonitored.")
end
