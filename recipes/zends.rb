#
# Cookbook Name:: pl_zenoss
# Recipe:: zends
#
# Copyright 2013, thePlatform
#
# All rights reserved - Do Not Redistribute
#

pw = Chef::EncryptedDataBagItem.load(node["deployment"]["repo_data_bag_name"], node["deployment"]["repo_data_bag_item"])
username = pw['user']
password = pw['pass']

# install zenoss dep repo
execute "install zenoss deps" do
  command "rpm -i http://deps.zenoss.com/yum/zenossdeps-#{node["zenoss"]["version"]["deps"]}.rpm"
  action :run
  not_if "rpm -q zenossdeps-#{node["zenoss"]["version"]["deps"]}"
end

pl_zenoss_repository "zends-#{node["zenoss"]["version"]["zends"]}.rpm" do
  path "#{node["deployment"]["repo_url"]}/zenoss"
  username username
  password password
  action :fetch
  not_if "rpm -q zends-#{node["zenoss"]["version"]["zends"]}"
end

yum_package "zends" do
  action :install
  flush_cache [:before]
  source "#{Chef::Config[:file_cache_path]}/zends-#{node["zenoss"]["version"]["zends"]}.rpm"
  version node["zenoss"]["version"]["zends"]
  options "--nogpgcheck"
  not_if "rpm -q zends-#{node["zenoss"]["version"]["zends"]}"

  notifies :start, "service[zends]"
  notifies :enable, "service[zends]"
end

service "zends" do
  supports [:stop, :start, :restart, :status, :enable]
  action [:start, :enable]
end
=begin
# set mysql passwords
execute "set mysql password" do
  command "sudo -u zenoss -i #{node["zenoss"]["server"]["zendshome"]}/bin/mysqladmin password #{mysqlpw}"
  creates "#{node["zenoss"]["server"]["zendshome"]}/bin/.mypw_set
  not_if {::File.exists?("#{node["zenoss"]["server"]["zendshome"]}/bin/.mypw_set"}
end 
=end