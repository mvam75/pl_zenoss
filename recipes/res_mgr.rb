#
# Cookbook Name:: pl_zenoss
# Recipe:: res_mgr
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

# support packages download
support_packages = [ "rabbitmq-server-#{node["zenoss"]["version"]["rabbitmq-server"]}", "zenoss_msmonitor-#{node["zenoss"]["version"]["zenoss_msmonitor"]}" ]

support_packages.each do |spkg|
  pl_zenoss_repository "#{spkg}.rpm" do
    path "#{node["deployment"]["repo_url"]}/zenoss"
    username username
    password password
    action :fetch
    not_if "rpm -q #{spkg}"
  end
end

## zenoss package download
pl_zenoss_repository "zenoss_resmgr-#{node["zenoss"]["version"]["zenoss_resmgr"]}.rpm" do
  path "#{node["deployment"]["repo_url"]}/zenoss"
  username username
  password password
  action :fetch
  not_if "rpm -q zenoss-#{node["zenoss"]["version"]["zenoss_resmgr"]}"
end

## install RabbitMQ and ZenDS
support_services = %w[rabbitmq-server]

support_services.each do |svc|
  # install packages
  yum_package "#{svc}" do
    action :install
    flush_cache [:before]
    source "#{Chef::Config[:file_cache_path]}/#{svc}-#{node["zenoss"]["version"][svc]}.rpm"
    version node["zenoss"]["version"][svc]
    options "--nogpgcheck"
    not_if "rpm -q #{svc}-#{node["zenoss"]["version"][svc]}"

    notifies :start, "service[#{svc}]"
    notifies :enable, "service[#{svc}]"
  end

  # control services
  service "#{svc}" do
    start_command "/sbin/service #{svc} start &> /dev/null"
    stop_command "/sbin/service #{svc} stop &> /dev/null"
    restart_command "/sbin/service #{svc} restart &> /dev/null"
    status_command "/sbin/service #{svc} status &> /dev/null"

    supports [:stop, :start, :restart, :status, :enable]
    action [:start, :enable]
  end
end

## install Zenoss and MSMonitor seperate because their RPM package name does not match the installed name. Yay Zenoss!
yum_package "zenoss_resmgr-#{node["zenoss"]["version"]["zenoss_resmgr"]}" do
  action :install
  source "#{Chef::Config[:file_cache_path]}/zenoss_resmgr-#{node["zenoss"]["version"]["zenoss_resmgr"]}.rpm"
  options "--nogpgcheck"
  not_if "rpm -q zenoss-#{node["zenoss"]["version"]["zenoss_resmgr"]}"
end

yum_package "zenoss_msmonitor-#{node["zenoss"]["version"]["zenoss_msmonitor"]}" do
  action :install
  source "#{Chef::Config[:file_cache_path]}/zenoss_msmonitor-#{node["zenoss"]["version"]["zenoss_msmonitor"]}.rpm"
  options "--nogpgcheck"
  not_if "rpm -q zenoss_msmonitor-#{node["zenoss"]["version"]["zenoss_msmonitor"]}"
end

# store the public key on the server as an attribute
ruby_block "zenoss public key" do
  block do
    pubkey = IO.read("/home/zenoss/.ssh/id_dsa.pub")
    node.set["zenoss"]["server"]["zenoss_pubkey"] = pubkey
    node.save
    #write out the authorized_keys for the zenoss user
    ak = File.new("/home/zenoss/.ssh/authorized_keys", "w+")
    ak.puts pubkey
    ak.chown(File.stat("/home/zenoss/.ssh/id_dsa.pub").uid,File.stat("/home/zenoss/.ssh/id_dsa.pub").gid)
  end
  action :nothing
end

# generate SSH key for the zenoss user
execute "ssh-keygen -q -t dsa -f /home/zenoss/.ssh/id_dsa -N \"\" " do
  user "zenoss"
  action :run
  not_if {File.exists?("/home/zenoss/.ssh/id_dsa.pub")}
  notifies :create, "ruby_block[zenoss public key]", :immediately
end

# get mysqltuner
execute "mysqltuner" do
  user "zenoss"
  group "zenoss"
  cwd "#{node["zenoss"]["server"]["zenhome"]}/bin"
  command "wget -q -N --no-check-certificate mysqltuner.pl"
  not_if {::File.exists?("#{node["zenoss"]["server"]["zenhome"]}/bin/mysqltuner.pl")}
end

execute "set mysqltuner" do
  cwd "#{node["zenoss"]["server"]["zenhome"]}/bin"
  command "chmod +x mysqltuner.pl"
  #not_if {::File.exists?("#{node["zenoss"]["server"]["zenhome"]}/bin/mysqltuner.pl")}
end

# ensure that we're using Oracle Java
link "/usr/bin/java" do
  to "/usr/java/default/bin/java"
end

# provide restart and status support
service "zenoss" do
  action :nothing
  supports [:status, :restart, :enable]

  only_if {::File.exists?("#{node["zenoss"]["server"]["zenhome"]}/bin/zencatalogservice")}
end

# start zenoss after install
execute "start zenoss" do
  command "/sbin/service zenoss start && touch #{node["zenoss"]["server"]["zenhome"]}/.firstrun"
  creates "#{node["zenoss"]["server"]["zenhome"]}/.firstrun"
end

## daemon templates. yes, it would have been easy to put these into a loop.
## but i wanted to use the 'variables' option to make it easier to find files 
## that have been modified.

execute "restart zope" do
  action :nothing
  user "zenoss"
  group "zenoss"
  environment ({
              'LD_LIBRARY_PATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib",
              'PYTHONPATH' => "#{node["zenoss"]["server"]["zenhome"]}/lib/python",
              'ZENHOME' => node["zenoss"]["server"]["zenhome"]
              })
  cwd "#{node["zenoss"]["server"]["zenhome"]}/bin"
  command "#{node["zenoss"]["server"]["zenhome"]}/bin/zopectl restart"
end

template "zope.conf" do
  path "/opt/zenoss/etc/zope.conf"
  source "zope.conf.erb"
  owner "zenoss"
  group "zenoss"

  variables(
    :cache_local_mb => node["zenoss"]["settings"]["zope"]["cache_local_mb"],
    :python_check_interval => node["zenoss"]["settings"]["zope"]["python_check_interval"]
  )

  notifies :run, "execute[restart zope]", :immediately
end

template "zeneventd.conf" do
  path "/opt/zenoss/etc/zeneventd.conf"
  source "zeneventd.conf.erb"
  owner "zenoss"
  group "zenoss"

  variables(
    :zodb_cachesize => node["zenoss"]["settings"]["zeneventd"]["zodb_cachesize"]
  )

  notifies :restart, "pl_zenoss_zen_daemon[zeneventd]", :immediately
end

template "zencatalogservice.conf" do
  path "/opt/zenoss/etc/zencatalogservice.conf"
  source "zencatalogservice.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zeneventserver.conf" do
  path "/opt/zenoss/etc/zeneventserver.conf"
  source "zeneventserver.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenwebserver.conf" do
  path "/opt/zenoss/etc/zenwebserver.conf"
  source "zenwebserver.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenhub.conf" do
  path "/opt/zenoss/etc/zenhub.conf"
  source "zenhub.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenping.conf" do
  path "/opt/zenoss/etc/zenping.conf"
  source "zenping.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zensyslog.conf" do
  path "/opt/zenoss/etc/zensyslog.conf"
  source "zensyslog.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenstatus.conf" do
  path "/opt/zenoss/etc/zenstatus.conf"
  source "zenstatus.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenactiond.conf" do
  path "/opt/zenoss/etc/zenactiond.conf"
  source "zenactiond.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zentrap.conf" do
  path "/opt/zenoss/etc/zentrap.conf"
  source "zentrap.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenmodeler.connf" do
  path "/opt/zenoss/etc/zenmodeler.conf"
  source "zenmodeler.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenperfsnmp.conf" do
  path "/opt/zenoss/etc/zenperfsnmp.conf"
  source "zenperfsnmp.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zencommand.conf" do
  path "/opt/zenoss/etc/zencatalogservice.conf"
  source "zencatalogservice.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenjmx.conf" do
  path "/opt/zenoss/etc/zenjmx.conf"
  source "zenjmx.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenjserver.conf" do
  path "/opt/zenoss/etc/zenjserver.conf"
  source "zenjserver.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenmailtx.conf" do
  path "/opt/zenoss/etc/zenmailtx.conf"
  source "zenmailtx.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenwebtx.conf" do
  path "/opt/zenoss/etc/zenwebtx.conf"
  source "zenwebtx.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenvmwareevents.conf" do
  path "/opt/zenoss/etc/zenvmwareevents.conf"
  source "zenvmwareevents.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenvmwaremodeler.conf" do
  path "/opt/zenoss/etc/zenvmwaremodeler.conf"
  source "zenvmwaremodeler.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenvmwareperf.conf" do
  path "/opt/zenoss/etc/zenvmwareperf.conf"
  source "zenvmwareperf.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenucsevents.conf" do
  path "/opt/zenoss/etc/zenucsevents.conf"
  source "zenucsevents.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zenvcloud.conf" do
  path "/opt/zenoss/etc/zenvcloud.conf"
  source "zenvcloud.conf.erb"
  owner "zenoss"
  group "zenoss"
end

template "zentune.conf" do
  path "/opt/zenoss/etc/zentune.conf"
  source "zentune.conf.erb"
  owner "zenoss"
  group "zenoss"
end

## zenoss daemon support
zen_daemons = %w[catalogservice eventserver webserver hub eventd ping syslog status actiond trap modeler perfsnmp command jmx jserver mailtx webtx vmwareevents vmwaremodeler vmwareperf ucsevents vcloud tune]

zen_daemons.each do |zdaemon|
  pl_zenoss_zen_daemon "zen#{zdaemon}" do
    supports [:stop, :start, :restart, :status]

    only_if {::File.exists?("#{node["zenoss"]["server"]["zenhome"]}/bin/zencatalogservice")} 
  end
end

# skip the new install Wizard.
pl_zenoss_zendmd "skip setup wizard" do
  command "dmd._rq = True"
  action :run
end

# set snmp collection interval
pl_zenoss_zendmd "zsnmp polling" do
  command "dmd.Devices.zSnmpCollectionInterval=#{node["zenoss"]["settings"]["zsnmpcollectioninterval"]}"
  action :run
end

zen_databag = Chef::EncryptedDataBagItem.load('zenoss', node.chef_environment)

if zen_databag["adminpw"]
  adminpw = zen_databag["adminpw"]

  # use zendmd to set the admin password
  pl_zenoss_zendmd "set admin pass" do
    command "app.acl_users.userManager.updateUserPassword('admin', '#{adminpw}')"
    action :run
  end
else
  Chef::Log.warn "Admin password not found in the zenoss data bag. Please set this."
end

#### hubs & collectors
hubs = search(:node, 'role:zenoss_remotehub') || []
if hubs.length > 0
  if zen_databag["hubs"]

    zen_databag["hubs"].each do |hub|
      @hub = hub
    end

    # setup remote hub if needed
    pl_zenoss_zenhub "#{@hub}" do
      action :add
    end
  else
    Chef::Log.warn "Did not find hub hash in the zenoss databag. This is needed for remote hub setup."
  end
else
  Chef::Log.info "No remote hubs found. Make sure roles are created."
end

collectors = search(:node, 'role:zenoss_remotecollector') || []
if collectors.length > 0
  if zen_databag["collectors"]

    zen_databag["collectors"].each do |k, v|
      pl_zenoss_zencollector "#{k}" do
        hub "#{v["hub"]}"
        action :add
      end
    end
  else
    Chef::Log.warn "Did not find collector hash in the zenoss databag. This is needed for remote collector setup."
  end
else
  Chef::Log.info "No remote collectors found. Make sure roles are created."
end

#### settings for 1 min polling
if zen_databag["collectors"]
  zen_databag["collectors"].each do |k, v|

    # set process interval
    pl_zenoss_zendmd "set process cycle interval for #{k}" do
      command "dmd.Monitors.Performance.#{k}.processCycleInterval=#{node["zenoss"]["settings"]["processcycleinterval"]}"
      action :run
    end

    # set perfsnmpCycleInterval
    pl_zenoss_zendmd "set perf snmp cycle interval for #{k}" do
      command "dmd.Monitors.Performance.#{k}.perfsnmpCycleInterval=#{node["zenoss"]["settings"]["perfsnmpcycleinterval"]}"
      action :run
    end

    # set default RRD create
    pl_zenoss_zendmd "set default RRD create for #{k}" do
      command "dmd.Monitors.Performance.#{k}.defaultRRDCreateCommand=#{node["zenoss"]["settings"]["rrd"]}"
      action :run
    end
  end
end
