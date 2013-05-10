
default["zenoss"]["server"]["zenhome"] = "/opt/zenoss"
default["zenoss"]["server"]["zendshome"] = "/opt/zends"
default["zenoss"]["server"]["zenoss_pubkey"] = ""

## program versions
default["zenoss"]["version"]["zends"] = "5.5.25a-1.r64630.el6.x86_64"
default["zenoss"]["version"]["zenoss_resmgr"] = "4.2.3-1695.el6.x86_64"
default["zenoss"]["version"]["rabbitmq-server"] = "2.8.6-1.noarch"
default["zenoss"]["version"]["deps"] = "4.2.x-1.el6.noarch"
default["zenoss"]["version"]["zenoss_msmonitor"] = "4.2.3-1.1695.el6.x86_64"

## custom tuning settings
# zope.conf
default["zenoss"]["settings"]["zope"]["python_check_interval"] = "1700"
default["zenoss"]["settings"]["zope"]["cache_local_mb"] = "512"

# zeneventd.conf
default["zenoss"]["settings"]["zeneventd"]["zodb_cachesize"] = "30000"

# RRD retentions
default["zenoss"]["settings"]["rrd"] = "('RRA:AVERAGE:0.5:1:10080', 'RRA:AVERAGE:0.5:10:4320', 'RRA:AVERAGE:0.5:60:2160', 'RRA:AVERAGE:0.5:1440:1095', 'RRA:MAX:0.5:10:4320', 'RRA:MAX:0.5:60:2160', 'RRA:MAX:0.5:1440:1095')"

# polling settings
default["zenoss"]["settings"]["processcycleinterval"] = 60
default["zenoss"]["settings"]["perfsnmpcycleinterval"] = 60
default["zenoss"]["settings"]["zsnmpcollectioninterval"] = 60
