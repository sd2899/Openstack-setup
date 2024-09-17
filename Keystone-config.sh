#!/bin/bash

# Keystone installation

# Create Keystone database and grant previleges
DB_ROOT_PASS="123"  # Replace with your MariaDB/MySQL root passwor
# Create the SQL commands to be executed
SQL_COMMANDS=$(cat <<EOF
CREATE DATABASE keystone;

GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'k123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'k123';
EOF
)

# Run the SQL commands as root
echo "Setting up keystone databases and granting privileges..."

mysql -uroot -p"$DB_ROOT_PASS" -e "$SQL_COMMANDS"

if [ $? -eq 0 ]; then
  echo "Databases created and privileges granted successfully."
else
  echo "There was an error setting up the databases."
fi
echo "Database setup completed"

# install the package
sudo apt install keystone -y

#keystone configuration
config_file="/etc/keystone/keystone.conf"
cp $config_file $config_file.bak

# Define the new connection string and token provider
NEW_DB_CONNECTION="connection = mysql+pymysql://keystone:k123@controller/keystone"
NEW_TOKEN_PROVIDER="provider = fernet"

if [ -f "$config_file" ]; then
	echo "Updatng $config_file"
	
	# Check if the [database] section exists
	if grep -q "^\[database\]" "$config_file"; then
	    echo "[database] section found in $config_file"

	    # Check if there is already a connection string in the [database] section
	    if grep -A1 "^\[database\]" "$config_file" | grep -q "^connection ="; then
		echo "Existing connection string found, commenting it out"
		
		# Comment out the existing connection string
		sudo sed -i.bak '/^\[database\]/,/^\[/ {
		    /^\[database\]/!b
		    :a
		    N
		    /^\[/!ba
		    s/^\([[:space:]]*connection[[:space:]]*=.*\)/# \1/
		}' "$config_file"
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
	
	# editing the token section
	if grep -q "^\[token\]" "$config_file"; then
	    echo "[token] section found in $config_file"

	    # Check if there is already a connection string in the [database] section
	    if grep -A1 "^\[token\]" "$config_file" | grep -q "^provider ="; then
		echo "Existing provider string found, commenting it out"
		
		# Comment out the existing connection string
		sudo sed -i.bak '/^\[token\]/,/^\[/ {
		    /^\[token\]/!b
		    :a
		    N
		    /^\[/!ba
		    s/^\([[:space:]]*provider[[:space:]]*=.*\)/# \1/
		}' "$config_file"
	    else
		echo "No existing provider string found in the [token] section"
	    fi

	    # Add the new provider string below the [token] section
	    sudo sed -i "/^\[token\]/a$NEW_TOKEN_PROVIDER" "$config_file"
	    echo "New connection string added to [token] section"

	else
	    echo "[token] section not found in $config_file"
	    echo "Adding the [token] section and new connection string"

    	# If the [token] section doesn't exist, append it to the config file
    	echo -e "\n[token]\n$NEW_TOKEN_PROVIDER" | sudo tee -a "$config_file"
	fi
else
    echo "keystone configuration file $config_file not found. Exiting..."
    exit 1
fi
# Inform the user
echo "Keystone configuration updated successfully!"

#Populate the Identity service database:
su -s /bin/sh -c "keystone-manage db_sync" keystone
echo "database populated..."

#Initialize Fernet key repositories:
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
echo "Keys initialized successfully"

#Bootstrap the Identity service:
keystone-manage bootstrap --bootstrap-password A123 \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
echo "bootstraping the identity service successfully."

conf="/etc/apache2/apache2.conf"
sudo bash -c "cat <<EOF >> $conf
ServerName controller"

echo "apache updated successfully"

# restart the service
service apache2 restart

cat <<EOF > /home/openstack/admin-openrc
export OS_USERNAME=admin
export OS_PASSWORD=A123
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF
echo "admin-openrc created successfully"

chmod +x admin-openrc
. admin-openrc
