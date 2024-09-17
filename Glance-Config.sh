#!/bin/bash
#------Glance Installation---------------

DB_ROOT_PASS="123"

SQL_COMMANDS=$(cat <<EOF
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'g123';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'g123';
EOF
)

mysql -uroot -p"$DB_ROOT_PASS" -e "$SQL_COMMANDS"

if [ $? -eq 0 ]; then
  echo "Databases created and privileges granted successfully."
else
  echo "There was an error setting up the databases."
fi
echo "Database setup completed"

. /home/openstack/admin-openrc
# create service project
openstack project create --domain default --description "Project description" service

# Create the Glance User and assign the admin role
openstack user create --domain default --password "g123" glance
openstack role add --project service --user glance admin
SERVICE_ID=$(openstack service create --name glance --description "OpenStack Image" image -f value -c id)
openstack role add --user glance --user-domain Default --system all reader

# Create Glance endpoints
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
endpoint_id=$(openstack endpoint create --region RegionOne image admin http://controller:9292 -f value -c id)

# install the package
sudo apt install glance -y

# Create the OpenStack Service
#echo "Creating OpenStack service: $SERVICE_NAME..."
#SERVICE_ID=$(openstack service create --name "$SERVICE_NAME" --description "$SERVICE_DESCRIPTION" "$SERVICE_TYPE" -f value -c id)

#configure the Glance Config file
config_file="/etc/glance/glance-api.conf"
NEW_DB_CONNECTION="connection = mysql+pymysql://glance:g123@controller/glance"
keystone_authtoken_config="www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = g123"
paste_deploy_conf="flavor = keystone"
glance_store_conf="stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/"
oslo_limit_conf="auth_url = http://controller:5000
auth_type = password
user_domain_id = default
username = $SERVICE_ID
system_scope = all
password = g123
endpoint_id = $endpoint_id
region_name = RegionOne"
default_conf="use_keystone_quotas = True"

if [ -f "$config_file" ]; then
	echo "Updatng $config_file"
	sudo cp $config_file $config_file.bak
 
	# Check if the [database] section exists
	if grep -q "^\[database\]" "$config_file"; then
	    echo "[database] section found in $config_file"

	    # Check if there is already a connection string in the [database] section
	    if grep -A1 "^\[database\]" "$config_file" | grep -q "^connection ="; then
		echo "Existing connection string found, commenting it out"
		
		# Comment out the existing connection string
		sudo sed -i "s/^.*connection = .*/# &/" "$config_file"
		
	    else
		echo "No existing connection string found in the [database] section"
	    fi

	    # Add the new connection string below the [database] section
	    sudo sed -i "/^\[database\]/a$NEW_DB_CONNECTION" "$config_file"
	    echo "New connection string added to [database] section"

	else
	    echo "[database] section not found in $config_file"
	    echo "Adding the [database] section and new connection string"

    	# If the [database] section doesn't exist, append it to the config file
    	echo -e "\n[database]\n$NEW_DB_CONNECTION" | sudo tee -a "$config_file"
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
    	#echo -e "\n[keystone_authtoken]\n$keystone_authtoken_config" | sudo tee -a "$config_file"
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
	
	# edit paste_deploy section
	if grep -q "^\[paste_deploy\]" "$config_file"; then
	    echo "[paste_deploy] section found in $config_file"

	    # Add the paste_deploy below the [paste_deploy] section
	    sudo sed -i "/^\[paste_deploy\]/a$paste_deploy_conf" "$config_file"
	    echo "paste_deploy added to [paste_deploy] section"

	else
	    echo "[paste_deploy] section not found in $config_file"
	    echo "Adding the [paste_deploy] section and new connection string"

    	# If the [paste_deploy] section doesn't exist, append it to the config file
    	echo -e "\n[paste_deploy]\n$paste_deploy_conf" | sudo tee -a "$config_file"
	fi
	
	# edit glance_store section
	if grep -q "^\[glance_store\]" "$config_file"; then
	    echo "[glance_store] section found in $config_file"

	    # Add the glance_store below the [glance_store] section
	    while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[glance_store\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in glance_store section"
		    sudo sed -i "/^\[glance_store\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to glance_store section"
		    sudo sed -i "/^\[glance_store\]/a$key = $value" "$config_file"
		fi
	    done <<< "$glance_store_conf"
	    echo "glance_store added to [glance_store] section"

	else
	    echo "[glance_store] section not found in $config_file"
	    echo "Adding the [glance_store] section and new connection string"

    	# If the [glance_store] section doesn't exist, append it to the config file
    	#echo -e "\n[glance_store]\n$glance_store_conf" | sudo tee -a "$config_file"
    	echo "[glance_store]" >> "$config_file"
    	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[glance_store\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in glance_store section"
	       sudo sed -i "/^\[glance_store\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to glance_store section"
	       sudo sed -i "/^\[glance_store\]/a$key = $value" "$config_file"
	   fi
	done <<< "$glance_store_conf"
	fi
	
	#edit the oslo_limit section
	if grep -q "^\[oslo_limit\]" "$config_file"; then
	    echo "[oslo_limit] section found in $config_file"
	    
	    if [ -z "$SERVICE_ID" ]; then
    		echo "Failed to create the service. Exiting..."
    		exit 1
	    fi
	    echo "Service created with ID: $SERVICE_ID"
	    
	    if [ -z "$endpoint_id" ]; then
    		echo "Failed to create the service. Exiting..."
    		exit 1
	    fi
	    echo "Service created with ID: $endpoint_id"
	    
	    # Add the oslo_limit below the [oslo_limit] section
	    while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[oslo_limit\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in oslo_limit section"
		    sudo sed -i "/^\[oslo_limit\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to oslo_limit section"
		    sudo sed -i "/^\[oslo_limit\]/a$key = $value" "$config_file"
		fi
	    done <<< "$oslo_limit_conf"
	    echo "oslo_limit added to [oslo_limit] section"

	else
	    echo "[oslo_limit] section not found in $config_file"
	    echo "Adding the [oslo_limit] section and new connection string"

    	# If the [oslo_limit] section doesn't exist, append it to the config file
    	#echo -e "\n[oslo_limit]\n$oslo_limit_conf" | sudo tee -a "$config_file"
    	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[oslo_limit\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in oslo_limit section"
	       sudo sed -i "/^\[oslo_limit\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to oslo_limit section"
	       sudo sed -i "/^\[oslo_limit\]/a$key = $value" "$config_file"
	   fi
	done <<< "$oslo_limit_conf"
	fi
	
	# edit default section
	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"

	    # Add the paste_deploy below the [paste_deploy] section
	    sudo sed -i "/^\[DEFAULT\]/a$default_conf" "$config_file"
	    echo "default configuration added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file"
	    echo "Adding the [paste_deploy] section and new connection string"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo -e "\n[DEFAULT]\n$default_conf" | sudo tee -a "$config_file"
	fi
else
    echo "glance configuration file $config_file not found. Exiting..."
    exit 1
fi


# Populate the Image service database:
su -s /bin/sh -c "glance-manage db_sync" glance

# Restart the Image services:
sudo service glance-api restart
