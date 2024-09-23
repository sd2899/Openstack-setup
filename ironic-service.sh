#! /bin/bash

#---- Nova Installation----------

DB_ROOT_PASS="123"

SQL_COMMANDS=$(cat <<EOF 
CREATE DATABASE ironic CHARACTER SET utf8mb3;

GRANT ALL PRIVILEGES ON ironic.* TO 'ironic'@'localhost' IDENTIFIED BY 'ir123';
GRANT ALL PRIVILEGES ON ironic.* TO 'ironic'@'%' IDENTIFIED BY 'ir123';
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

# install the package
apt-get install ironic-api ironic-conductor python3-ironicclient -y

# configure the /etc/ironic/ironic.conf file
config_file="/etc/ironic/ironic.conf"
db_con="connection=mysql+pymysql://ironic:ir123@controller/ironic?charset=utf8"
trans_url="transport_url = rabbit://openstack:R123@controller:5672/"
def="rpc_transport = json-rpc
auth_strategy=keystone"
json_rpc="auth_type = password
auth_url=http://controller:5000
username=ironic
password=ir123
project_name=service
project_domain_id=default
user_domain_id=default
port = 9999"
keystone_authtoken_config="www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = ironic
password = ir123"


if [ -f "$config_file" ]; then
    	echo "updating the $config_file"
    	sudo cp $config_file $config_file.bak
    	
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
    	
    	# configure the transport url in the [DEFAULT] section.
    	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"
	    # Check if there is already a connection string in the [api_database] section
	    if grep -A1 "^\[DEFAULT\]" "$config_file" | grep -q "^transport_url ="; then
		echo "Existing connection string found, commenting it out"
		# Comment out the existing transport_url string
		sudo sed -i "s/^.*transport_url = .*/# &/" "$config_file"
	    else
		echo "No existing connection string found in the [DEFAULT] section"
	    fi
	    # Add the new connection string below the [DEFAULT] section
	    sudo sed -i "/^\[DEFAULT\]/a$trans_url" "$config_file"
	    echo "New connection string added to [DEFAULT] section"
    	else
	    echo "[DEFAULT] section not found in $config_file"
	    echo "Adding the [DEFAULT] section and new connection string"
    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo -e "\n[DEFAULT]\n$trans_url" | sudo tee -a "$config_file"
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
	
	# Editing the [DEFAULT] section
	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"

	    # Add the keystone_authtoken below the [keystone_authtoken] section
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
	
	# Editing the [json_rpc] section
	if grep -q "^\[json_rpc\]" "$config_file"; then
	    echo "[json_rpc] section found in $config_file"

	    # Add the json_rpc below the [json_rpc] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[json_rpc\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in json_rpc section"
		    sudo sed -i "/^\[json_rpc\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to json_rpc section"
		    sudo sed -i "/^\[json_rpc\]/a$key = $value" "$config_file"
		fi
	    done <<< "$json_rpc"
	    echo "json_rpc added to [json_rpc] section"

	else
	    echo "[json_rpc] section not found in $config_file"
	    echo "Adding the [json_rpc] section and new connection string"

    	# If the [json_rpc] section doesn't exist, append it to the config file
    	echo "[json_rpc]" >> "$config_file"
    	
    	# Add the json_rpc below the [json_rpc] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[json_rpc\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in json_rpc section"
	       sudo sed -i "/^\[json_rpc\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to json_rpc section"
	       sudo sed -i "/^\[json_rpc\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$json_rpc"
	fi
else
    echo "$config_file not found. 
    exiting....."
    exit 1
fi    	

#Create the Bare Metal service database tables:
ironic-dbsync --config-file /etc/ironic/ironic.conf create_schema

# restart the ironic-api service
sudo service ironic-api restart

# Download the etc/apache2/ironic file and copy it to apache sites.
wget https://opendev.org/openstack/ironic/raw/branch/master/etc/apache2/ironic

sudo cp /home/openstack/Downloads/ironic /etc/apache2/sites-available/ironic.conf
sed -i "s/^.*SetEnv APACHE_RUN_USER stack.*/# &/" "/etc/apache2/sites-available/ironic.conf"
echo "SetEnv openstack stack" >> "/etc/apache2/sites-available/ironic.conf"

sed -i "s/^.*SetEnv APACHE_RUN_GROUP stack.*/# &/" "/etc/apache2/sites-available/ironic.conf"
echo "SetEnv root stack" >> "/etc/apache2/sites-available/ironic.conf"

# stop and disable the ironic-api service.
sudo service ironic-api stop
sudo service ironic-api disable

# Enable the apache ironic in site and reload.
sudo a2ensite ironic
sudo service apache2 reload


# ui installation
cd /etc/
git clone https://opendev.org/openstack/ironic-ui

#Change into the root directory of your horizon installation and activate the python virtualenv. Example:
source .venv/bin/activate

cp ./ironic_ui/enabled/_2200_ironic.py ../horizon/openstack_dashboard/local/enabled

pip install -r requirements.txt -e .

./run_tests.sh --runserver

