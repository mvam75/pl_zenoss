Description
===========
Installs and configures Zenoss 4 Enterprise

Requirements
============
Centos 6.x
Access to Zenoss 4 Enterprise RPMs

Recipes
=======
default -- install openssh-clients package which isn't default on Centos 6
client -- sets up the zenoss user and create ssh keys for the resource manager/hubs/collectors
res_mgr -- install the zenoss resource manager
remote_hub -- installs and configures a remote hub
remote_collector -- installs and configures a remote collector
zends -- installs and creates the zends database services