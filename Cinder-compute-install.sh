#!/bin/bash

# install supporting utility packages.
sudo apt install lvm2 thin-provisioning-tools -y

# Create the LVM physical volume /dev/sdb:
sudo pvcreate /dev/sda3

# Create the LVM volume group cinder-volumes:
sudo vgcreate cinder-volumes /dev/sda3

conf="/etc/lvm/lvm.conf"
sudo cp $conf $conf.bak
sed -i '/devices {/!b;n;c\	filter = [ "a/sda3/", "r/.*/"]' $conf
echo "lvm conf done...."    	

#Install the packages:
sudo apt install cinder-volume tgt -y


# Edit the /etc/cinder/cinder.conf file and complete the following actions:
config_file="/etc/cinder/cinder.conf"
db_con="connection = mysql+pymysql://cinder:ci123@controller/cinder"
trans_url="transport_url = rabbit://openstack:R123@controller"
def_ser="auth_strategy = keystone"
keystone_authtoken_config="www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = cinder
password = ci123
service_token_roles_required = True
service_token_roles = admin"
oslo_con="lock_path = /var/lib/cinder/tmp"
lvm="volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = tgtadm"
def="enabled_backends = lvm
glance_api_servers = http://controller:9292"

if [ -f "$config_file" ]; then
    	echo "updating the $config_file"
    	sudo cp $config_file $config_file.bak
    	
    	sudo chown cinder:cinder /etc/cinder/cinder.conf
    	
    	#In the [database] and [database] sections, configure database access.
    	if grep -q "^\[database\]" "$config_file"; then
	    echo "[database] section found in $config_file"
	    # Check if there is already a connection string in the [api_database] section
	    if grep -A1 "^\[database\]" "$config_file" | grep -q "^connection ="; then
		echo "Existing connection string found, commenting it out"
		# Comment out the existing connection string
		sudo sed -i "s/^.*connection = .*/# &/" "$config_file"
	    else
		echo "No existing connection string found in the [database] section"
	    fi
	    # Add the new connection string below the [api_database] section
	    sudo sed -i "/^\[database\]/a$db_con" "$config_file"
	    echo "New connection string added to [database] section"
    	else
	    echo "[database] section not found in $config_file"
	    echo "Adding the [database] section and new connection string"
    	# If the [database] section doesn't exist, append it to the config file
    	echo -e "\n[database]\n$db_con" | sudo tee -a "$config_file"
    	fi
    	
    	#In the [DEFAULT] section, configure RabbitMQ message queue access.
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
    	echo -e "\n[DEFAULT]\n\n$trans_url" | sudo tee -a "$config_file"
	fi
	
	# edit the [DEFAULT] section for keystone
	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"

	    # Add the DEFAULT below the [DEFAULT] section
	    sudo sed -i "/^\[DEFAULT\]/a$def_ser" "$config_file"
	    echo "auth_strategy added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file"
	    echo "Adding the [DEFAULT] section and keystone auth"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo -e "\n[DEFAULT]\n$def_ser" | sudo tee -a "$config_file"
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
    	
    	# Editing the [lvm] section
	if grep -q "^\[lvm\]" "$config_file"; then
	    echo "[lvm] section found in $config_file"

	    # Add the lvm below the [lvm] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[lvm\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in lvm section"
		    sudo sed -i "/^\[lvm\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to lvm section"
		    sudo sed -i "/^\[lvm\]/a$key = $value" "$config_file"
		fi
	    done <<< "$lvm"
	    echo "lvm added to [lvm] section"

	else
	    echo "[lvm] section not found in $config_file"
	    echo "Adding the [lvm] section and new connection string"

    	# If the [lvm] section doesn't exist, append it to the config file
    	echo "[lvm]" >> "$config_file"
    	
    	# Add the lvm below the [lvm] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[lvm\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in lvm section"
	       sudo sed -i "/^\[lvm\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to lvm section"
	       sudo sed -i "/^\[lvm\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$lvm"
	fi
	
	# Editing the [DEFAULT] section
	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"

	    # Add the lvm below the [DEFAULT] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[DEFAULT\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in DEFAULT section"
		    sudo sed -i "/^\[DEFAULT\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to DEFAULT section"
		    sudo sed -i "/^\[DEFAULT\]/a$key = $value" "$config_file"
		fi
	    done <<< "$def"
	    echo "DEFAULT added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file"
	    echo "Adding the [DEFAULT] section and new connection string"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo "[DEFAULT]" >> "$config_file"
    	
    	# Add the DEFAULT below the [DEFAULT] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[DEFAULT\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in DEFAULT section"
	       sudo sed -i "/^\[DEFAULT\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to DEFAULT section"
	       sudo sed -i "/^\[DEFAULT\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$def"
	fi

else
    echo "$config_file not found. 
    exiting....."
    exit 1
fi    	

sudo touch /etc/tgt/conf.d/cinder.conf
coff="/etc/tgt/conf.d/cinder.conf"
if [ -f "$coff" ]; then 
	echo "include /var/lib/cinder/volumes/*" >> "$coff"
else
	echo "$coff not found"
	exit 1
fi
echo "Storage Node configuration done!!"

# Restart the Block Storage volume service including its dependencies:
sudo service tgt restart
sudo service cinder-volume restart
sudo systemctl restart iscsid

# create the file for nova
sudo touch /var/lib/nova/tmp/os-brick-connect_volume
chown -R nova:nova /var/lib/nova/tmp/
