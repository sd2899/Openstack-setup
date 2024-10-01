#!/bin/bash

#---create Horizon dashboard-----
#Install the packages
apt install openstack-dashboard -y

# Configure the Openstack dashboard configuration file
config_file="/etc/openstack-dashboard/local_settings.py"

sudo cp $config_file $config_file.bak
echo "backup completed successfully"

# Configure the dashboard to use OpenStack services on the controller node.
sudo sed -i "s/^.*OPENSTACK_HOST = .*/# &/" "$config_file"
echo 'OPENSTACK_HOST = "controller" ' >> $config_file

#In the Dashboard configuration section, allow your hosts to access Dashboard.
sudo sed -i "s/^.*ALLOWED_HOSTS = .*/# &/" "$config_file"
echo 'ALLOWED_HOSTS = ["*"] ' >> "$config_file"

#Configure the memcached session storage service:
sudo sed -i "s/^.*SESSION_ENGINE = .*/# &/" "$config_file"
echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> $config_file

NEW_BACKEND="django.core.cache.backends.memcached.MemcachedCache"
NEW_LOCATION="controller:11211"

# Check if the 'CACHES' section exists
if grep -q "CACHES" "$config_file"; then
    echo "CACHES section found in $config_file"

    # Update the BACKEND value in the CACHES section
    if grep -q "'BACKEND':" "$config_file"; then
        echo "Updating BACKEND value"
        sudo sed -i "s/'BACKEND':.*/'BACKEND': '$NEW_BACKEND',/" "$config_file"
    else
        echo "BACKEND key not found, adding it"
        sudo sed -i "/CACHES = {/,/}/ s/\('default':.*\)/\1\n\t\t'BACKEND': '$NEW_BACKEND',/" "$config_file"
    fi

    # Update the LOCATION value in the CACHES section
    if grep -q "'LOCATION':" "$config_file"; then
        echo "Updating LOCATION value"
        sudo sed -i "s/'LOCATION':.*/'LOCATION': '$NEW_LOCATION'/" "$config_file"
    else
        echo "LOCATION key not found, adding it"
        sudo sed -i "/CACHES = {/,/}/ s/\('default':.*\)/\1\n\t\t'LOCATION': '$NEW_LOCATION'/" "$config_file"
    fi

else
    echo "CACHES section not found in $config_file"
fi

echo "Cache configuration update complete."

# Enable the Identity API version
sudo sed -i "s/^.*OPENSTACK_KEYSTONE_URL = .*/# &/" "$config_file"
echo 'OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST' >> $config_file

# configure the time zone
sudo sed -i "s/^.*TIME_ZONE = .*/# &/" "$config_file"
echo 'TIME_ZONE = "Asia/Kolkata"' >> $config_file

# Configure theme
sudo sed -i "s/^.*DEFAULT_THEME = .*/# &/" "$config_file"
echo "DEFAULT_THEME = 'ubuntu' " >> $config_file

# configure the webroot
sudo sed -i "s/^.*WEBROOT = .*/# &/" "$config_file"
echo "WEBROOT='/horizon/'" >> $config_file

# Enable support for domains:
echo "OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True" >> $config_file

sudo bash -c 'cat <<EOF >> $config_file
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}

OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"

OPENSTACK_NEUTRON_NETWORK = {
	#...
	"enable_router": True,
	"enable_quotas": True,
	"enable_ipv6": True,
	"enable_distributed_router": True,
	"enable_ha_router": True,
	"enable_fip_topology_check": True,
}

EOF'

sudo chown horizon:horizon /usr/lib/python3/dist-packages/openstack_dashboard/local/local_settings.py
sudo chown -R horizon:horizon /var/lib/openstack-dashboard/
sudo chmod -R 755 /var/lib/openstack-dashboard/
sudo chmod -R 600 /var/lib/openstack-dashboard/secret_key
sudo chown -R horizon:horizon /usr/share/openstack-dashboard/
sudo chmod -R 755 /usr/share/openstack-dashboard/

sudo su -s /bin/sh -c "python3 /usr/share/openstack-dashboard/manage.py collectstatic --noinput" horizon

conf_file1="/etc/apache2/conf-available/openstack-dashboard.conf"
sudo bash -c "cat <<EOF >> $conf_file1
WSGIApplicationGroup %{GLOBAL}
EOF"

#Reload the web server configuration:
systemctl reload apache2.service
