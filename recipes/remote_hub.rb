# install zenoss dep repo
execute "install zenoss deps" do
  command "rpm -i http://deps.zenoss.com/yum/zenossdeps-#{node["zenoss"]["version"]["deps"]}.rpm"
  action :run
  not_if "rpm -q zenossdeps-#{node["zenoss"]["version"]["deps"]}"
end

# install rrdtool
yum_package "rrdtool" do
  action :install
  not_if "rpm -q rrdtool"
end

# ensure that we're using Oracle Java
link "/usr/bin/java" do
  to "/usr/java/default/bin/java"
end

pw = Chef::EncryptedDataBagItem.load(node["deployment"]["repo_data_bag_name"], node["deployment"]["repo_data_bag_item"])
username = pw['user']
password = pw['pass']

# download and install zends -- do not start it
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
end

# download and install the resource manager -- do not start it
pl_zenoss_repository "zenoss_resmgr-#{node["zenoss"]["version"]["zenoss_resmgr"]}.rpm" do
  path "#{node["deployment"]["repo_url"]}/zenoss"
  username username
  password password
  action :fetch
  not_if "rpm -q zenoss-#{node["zenoss"]["version"]["zenoss_resmgr"]}"
end

yum_package "zenoss_resmgr-#{node["zenoss"]["version"]["zenoss_resmgr"]}" do
  action :install
  source "#{Chef::Config[:file_cache_path]}/zenoss_resmgr-#{node["zenoss"]["version"]["zenoss_resmgr"]}.rpm"
  options "--nogpgcheck"
  not_if "rpm -q zenoss-#{node["zenoss"]["version"]["zenoss_resmgr"]}"
end
