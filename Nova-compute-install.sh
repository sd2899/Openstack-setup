#!/bin/bash

# Install the packages.
sudo apt install nova-compute -y

metadata_id=$(openssl rand -hex 10 -f value -c id)

# configure the /etc/nova/nova.conf file
config_file="/etc/nova/nova.conf"
trans_url="transport_url = rabbit://openstack:R123@controller:5672/"
api="auth_strategy = keystone"
keystone_authtoken_config="www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = no123"
service_user="send_service_user_token = true
auth_url = https://controller/identity
auth_strategy = keystone
auth_type = password
project_domain_name = Default
project_name = service
user_domain_name = Default
username = nova
password = no123"
vnc="enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = 192.168.56.101
novncproxy_base_url = http://controller:6080/vnc_auto.html"
glance="api_servers = http://controller:9292"
oslo_con="lock_path = /var/lib/nova/tmp"
placement="region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = p123"
neutron="region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = neutron
password = ne123
service_metadata_proxy = true
metadata_proxy_shared_secret = $metadata_id"

if [ -f "$config_file" ]; then
    	echo "updating the $config_file"
    	sudo cp $config_file $config_file.bak
    	# Check if the [DEFAULT] section exists
	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"

	    # Check if there is already a transport_url string in the [Default] section
	    if grep -A1 "^\[DEFAULT\]" "$config_file" | grep -q "^transport_url ="; then
		echo "Existing transport_url string found, commenting it out"
		
		# Comment out the existing transport_url string
		sudo sed -i "s/^.*transport_url = .*/# &/" "$config_file"
		
	    else
		echo "No existing connection string found in the [default] section"
	    fi

	    # Add the new connection string below the [database] section
	    sudo sed -i "/^\[DEFAULT\]/a$trans_url" "$config_file"
	    echo "New connection string added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file"
	    echo "Adding the [DEFAULT] section and new connection string"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo -e "\n[DEFAULT]\n$trans_url" | sudo tee -a "$config_file"
    	#echo -e "\n[DEFAULT]\n$my_ip" | sudo tee -a "$config_file"
	fi
	
	# edit the [api] section for keystone
	if grep -q "^\[api\]" "$config_file"; then
	    echo "[api] section found in $config_file"

	    # Add the paste_deploy below the [paste_deploy] section
	    sudo sed -i "/^\[api\]/a$api" "$config_file"
	    echo "auth_strategy added to [api] section"

	else
	    echo "[api] section not found in $config_file"
	    echo "Adding the [api] section and keystone auth"

    	# If the [api] section doesn't exist, append it to the config file
    	echo -e "\n[api]\n$api" | sudo tee -a "$config_file"
	fi
	
	# Editing the [keystone_authtoken] section
	if grep -q "^\[keystone_authtoken\]" "$config_file"; then
	    echo "[keystone_authtoken] section found in $config_file"

	    # Add the keystone_authtoken below the [keystone_authtoken] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[keystone_authtoken\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in keystone_authtoken section"
		    sudo sed -i "/^\[keystone_authtoken\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to keystone_authtoken section"
		    sudo sed -i "/^\[keystone_authtoken\]/a$key = $value" "$config_file"
		fi
	    done <<< "$keystone_authtoken_config"
	    echo "keystone_authtoken added to [keystone_authtoken] section"

	else
	    echo "[keystone_authtoken] section not found in $config_file"
	    echo "Adding the [keystone_authtoken] section and new connection string"

    	# If the [keystone_authtoken] section doesn't exist, append it to the config file
    	echo "[keystone_authtoken]" >> "$config_file"
    	
    	# Add the keystone_authtoken below the [keystone_authtoken] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[keystone_authtoken\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in keystone_authtoken section"
	       sudo sed -i "/^\[keystone_authtoken\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to keystone_authtoken section"
	       sudo sed -i "/^\[keystone_authtoken\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$keystone_authtoken_config"
	fi
	
	# Editing the [service_user] section
	if grep -q "^\[service_user\]" "$config_file"; then
	    echo "[service_user] section found in $config_file"

	    # Add the service_user below the [service_user] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[service_user\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in service_user section"
		    sudo sed -i "/^\[service_user\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to service_user section"
		    sudo sed -i "/^\[service_user\]/a$key = $value" "$config_file"
		fi
	    done <<< "$service_user"
	    echo "service_user added to [service_user] section"

	else
	    echo "[service_user] section not found in $config_file"
	    echo "Adding the [service_user] section and new connection string"

    	# If the [service_user] section doesn't exist, append it to the config file
    	echo "[service_user]" >> "$config_file"
    	
    	# Add the service_user below the [service_user] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[service_user\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in service_user section"
	       sudo sed -i "/^\[service_user\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to service_user section"
	       sudo sed -i "/^\[service_user\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$service_user"
	fi
	
	# edit the [vnc] section
	if grep -q "^\[vnc\]" "$config_file"; then
	    echo "[vnc] section found in $config_file"

	    # Add the vnc below the [vnc] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[vnc\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in vnc section"
		    sudo sed -i "/^\[vnc\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to vnc section"
		    sudo sed -i "/^\[vnc\]/a$key = $value" "$config_file"
		fi
	    done <<< "$vnc"
	    echo "service_user added to [vnc] section"

	else
	    echo "[vnc] section not found in $config_file"
	    echo "Adding the [vnc] section and new connection string"

    	# If the [vnc] section doesn't exist, append it to the config file
    	echo "[vnc]" >> "$config_file"
    	
    	# Add the vnc below the [vnc] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[vnc\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in vnc section"
	       sudo sed -i "/^\[vnc\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to vnc section"
	       sudo sed -i "/^\[vnc\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$vnc"
	fi
	
	# edit glance section
	if grep -q "^\[glance\]" "$config_file"; then
	    echo "[glance] section found in $config_file"

	    # Add the api_server below the [glance] section
	    sudo sed -i "/^\[glance\]/a$glance" "$config_file"
	    echo "glance added to [glance] section"

	else
	    echo "[glance] section not found in $config_file"
	    echo "Adding the [glance] section and new connection string"

    	# If the [glance] section doesn't exist, append it to the config file
    	echo -e "\n[glance]\n$glance" | sudo tee -a "$config_file"
	fi
	
	# edit oslo_concurrency section 
	if grep -q "^\[oslo_concurrency\]" "$config_file"; then
	    echo "[oslo_concurrency] section found in $config_file"

	    # Add the lock_path below the [oslo_concurrency] section
	    sudo sed -i "/^\[oslo_concurrency\]/a$oslo_con" "$config_file"
	    echo "lock_path added to [oslo_concurrency] section"

	else
	    echo "[oslo_concurrency] section not found in $config_file"
	    echo "Adding the [oslo_concurrency] section and new connection string"

    	# If the [oslo_concurrency] section doesn't exist, append it to the config file
    	echo -e "\n[oslo_concurrency]\n$oslo_con" | sudo tee -a "$config_file"
	fi
	
	# edit the [placement] section
	if grep -q "^\[placement\]" "$config_file"; then
	    echo "[placement] section found in $config_file"

	    # Add the placement-conf below the [placement] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[placement\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in placement section"
		    sudo sed -i "/^\[placement\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to placement section"
		    sudo sed -i "/^\[placement\]/a$key = $value" "$config_file"
		fi
	    done <<< "$placement"
	    echo "placement-conf added to [placement] section"

	else
	    echo "[placement] section not found in $config_file"
	    echo "Adding the [placement] section and new connection string"

    	# If the [placement] section doesn't exist, append it to the config file
    	echo -e "\n[placement]\n$oslo_con" | sudo tee -a "$config_file"
	fi
	
	# edit the [neutron] section
	if grep -q "^\[neutron\]" "$config_file"; then
	    echo "[neutron] section found in $config_file"

	    # Add the neutron-conf below the [neutron] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[neutron\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in neutron section"
		    sudo sed -i "/^\[neutron\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to neutron section"
		    sudo sed -i "/^\[neutron\]/a$key = $value" "$config_file"
		fi
	    done <<< "$neutron"
	    echo "neutron-conf added to [neutron] section"

	else
	    echo "[neutron] section not found in $config_file"
	    echo "Adding the [neutron] section and new connection string"

    	# If the [neutron] section doesn't exist, append it to the config file
    	echo -e "\n[neutron]\n$oslo_con" | sudo tee -a "$config_file"
    	# Add the neutron-conf below the [neutron] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)	
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[neutron\]" "$config_file" | grep -q "^$key ="; then
		echo "Updating $key in neutron section"
		sudo sed -i "/^\[neutron\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	 	echo "Adding $key to neutron section"
		sudo sed -i "/^\[neutron\]/a$key = $value" "$config_file"
	   fi
	done <<< "$neutron"
	echo "neutron-conf added to [neutron] section"
        fi
        
else
    echo "$config_file not found. 
    exiting....."
    exit 1
fi

val=$(egrep -c '(vmx|svm)' /proc/cpuinfo)

if [ $val -eq 0 ]; then
	config_file1="/etc/nova/nova-compute.conf"
	libvirt="virt_type = qemu"

	if [ -f "$config_file1" ]; then
    		echo "updating the $config_file1"
    		sudo cp $config_file1 $config_file2.bak
    	
	    	# edit libvirt section 
		if grep -q "^\[libvirt\]" "$config_file1"; then
		    echo "[libvirt] section found in $config_file1"

		    # Add the lock_path below the [libvirt] section
		    sudo sed -i "/^\[libvirt\]/a$libvirt" "$config_file1"
		    echo "lock_path added to [libvirt] section"

		else
		    echo "[libvirt] section not found in $config_file1"
		    echo "Adding the [libvirt] section and new connection string"

	    	# If the [libvirt] section doesn't exist, append it to the config file
	    	echo -e "\n[libvirt]\n$libvirt" | sudo tee -a "$config_file1"
		fi
	    	
	else
	    echo "$config_file1 not found. 
	    exiting....."
	    exit 1
	fi
else
	echo "using kvm hypervisor"
fi

sudo chown nova:nova -R /etc/nova/
sudo chown nova:nova -R /etc/nova/nova.conf
sudo chmod -R 755 /etc/nova/nova.conf
sudo chown nova:nova -R /var/lib/nova/instances/
sudo chmod -R 755 /var/lib/nova/instances/
	
	
	

