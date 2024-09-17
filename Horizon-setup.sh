#!/bin/bash

#---create Horizon dashboard-----
#Install the packages
apt install openstack-dashboard -y

# Configure the Openstack dashboard configuration file
config_file="/etc/openstack-dashboard/local_settings.py"

sudo cp $config_file $config_file.bak
echo "backup completed successfully"

sudo bash -c "cat <<EOF >> $config_file
OPENSTACK_HOST = "controller"
ALLOWED_HOSTS = ["*"]

# Configure the memcached session storage service:
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
	'default': {
     	'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
     	'LOCATION': 'controller:11211',
	}
}

SITE_BRANDING = "C3iHUb OpenCloud"
HORIZON_CONFIG["help_url"] = "#"
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST

OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}

OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
OPENSTACK_NEUTRON_NETWORK = {
	#...
	'enable_router': True,
	'enable_quotas': True,
	'enable_ipv6': True,
	'enable_distributed_router': True,
	'enable_ha_router': True,
	'enable_fip_topology_check': True,
}
ENABLE_VOLUME = True;
ENABLE_VOLUME_TYPES = True;
OPENSTACK_SWIFT_ENABLED = True;

 TIME_ZONE = "Asia/Kolkata"
 DEFAULT_THEME = 'ubuntu'
 WEBROOT='/horizon/'
ALLOWED_HOSTS = ['*']

EOF"

conf_file1="/etc/apache2/conf-available/openstack-dashboard.conf"
sudo bash -c "cat <<EOF >> $config_file1
WSGIApplicationGroup %{GLOBAL}
EOF"

#Reload the web server configuration:
systemctl reload apache2.service

