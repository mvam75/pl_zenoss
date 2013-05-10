#
# Cookbook Name:: pl_zenoss
# Recipe:: default
#
# Copyright 2013, thePlatform
#
# All rights reserved - Do Not Redistribute
#
#include_recipe "pl_zenoss::client"

yum_package "openssh-clients.x86_64" do
  action :install
end
