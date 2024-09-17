#!/bin/bash

#----placement Service configuration and installation----

DB_ROOT_PASS="123"
SQL_COMMANDS=$( cat <<EOF 
CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY 'p123';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY 'p123';  
EOF
)

mysql -uroot -p"$DB_ROOT_PASS" -e "$SQL_COMMANDS"
if [ $? -eq 0 ]; then
  echo "Placement database created and privileges granted successfully"
else
  echo "There was an error setting up the database"
fi
echo "database setup complete"

. /home/openstack/admin-openrc

# Create a Placement service user
openstack user create --domain default --password "p123" placement

# Add the Placement user to the service project with the admin role
openstack role add --project service --user placement admin

# Create the Placement API entry in the service catalog:
openstack service create --name placement --description "Placement API" placement

# Create the Placement API service endpoints
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

# Install the packages:
sudo apt install placement-api -y

# Edit the /etc/placement/placement.conf file and complete the following actions

#configure the placement Config file
config_file="/etc/placement/placement.conf"
NEW_DB_CONNECTION="connection = mysql+pymysql://placement:p123@controller/placement"
keystone_authtoken_config="auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = p123"
api_conf="auth_strategy = keystone"

# check the placement configuration file exists or not
if [ -f "$config_file" ]; then
	echo "Updating $config_file"
	sudo cp $config_file $config_file.bak
	echo "backup created for the file"
	
	# Check if the [placement_database] section exists
	if grep -q "^\[placement_database\]" "$config_file"; then
	    echo "[placement_database] section found in $config_file"

	    # Check if there is already a connection string in the [placement_database] section
	    if grep -A1 "^\[placement_database\]" "$config_file" | grep -q "^connection ="; then
		echo "Existing connection string found, commenting it out"
		
		# Comment out the existing connection string
		sudo sed -i "s/^.*connection = .*/# &/" "$config_file"
		
	    else
		echo "No existing connection string found in the [placement_database] section"
	    fi

	    # Add the new connection string below the [placement_database] section
	    sudo sed -i "/^\[placement_database\]/a$NEW_DB_CONNECTION" "$config_file"
	    echo "New connection string added to [placement_database] section"

	else
	    echo "[placement_database] section not found in $config_file"
	    echo "Adding the [placement_database] section and new connection string"

    	# If the [placement_database] section doesn't exist, append it to the config file
    	echo -e "\n[placement_database]\n$NEW_DB_CONNECTION" | sudo tee -a "$config_file"
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
    	sudo bash -c "cat <<EOF >> $config_file
    	[keystone_authtoken]
    	EOF"
    	
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
	# edit api section
	if grep -q "^\[api\]" "$config_file"; then
	    echo "[api] section found in $config_file"

	    # Add the api below the [api] section
	    sudo sed -i "/^\[api\]/a$api_conf" "$config_file"
	    echo "paste_deploy added to [api] section"

	else
	    echo "[api] section not found in $config_file"
	    echo "Adding the [api] section and new connection string"

    	# If the [api] section doesn't exist, append it to the config file
    	echo -e "\n[api]\n$api_conf" | sudo tee -a "$config_file"
	fi

else
    echo "glance configuration file $config_file not found. Exiting..."
    exit 1
fi

# Populate the placement database:
su -s /bin/sh -c "placement-manage db sync" placement

# Reload the web server
sudo service apache2 restart

# verify the installation
#. admin-openrc

# Perform status checks to make sure everything is in order:
placement-status upgrade check

# Run some commands against the placement API and Install the osc-placement plugin.
pip3 install osc-placement

