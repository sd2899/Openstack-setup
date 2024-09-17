#!/bin/bash

# Keystone installation

# Create Keystone database and grant previleges
DB_ROOT_PASS="123"  # Replace with your MariaDB/MySQL root password
# Create the SQL commands to be executed
SQL_COMMANDS=$(cat <<EOF
CREATE DATABASE keystone;

GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'k123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'k123';
EOF
)

# Run the SQL commands as root
echo "Setting up nova databases and granting privileges..."

mysql -uroot -p"$DB_ROOT_PASS" -e "$SQL_COMMANDS"

if [ $? -eq 0 ]; then
  echo "Databases created and privileges granted successfully."
else
  echo "There was an error setting up the databases."
fi
echo "Database setup completed"

# install the package
sudo apt install keystone
sleep 20

#keystone configuration
config_file="/etc/keystone/keystone.conf"
cp $config_file $config_file.bak

# Define the new connection string and token provider
NEW_DB_CONNECTION="connection = mysql+pymysql://keystone:k123@controller/keystone"
NEW_TOKEN_PROVIDER="provider = fernet"

# Edit the [database] section: comment out existing 'connection' lines and add the new connection string
sed -i.bak '/^\[database\]/,/^\[/ {
    /^\[database\]/!b
    :a
    N
    /^\[/!ba
    s/^connection = .*/# &/
    i\
'"$NEW_DB_CONNECTION"'
}' "$config_file"

# Edit the [token] section: comment out existing 'provider' lines and set the new token provider
sed -i.bak '/^\[token\]/,/^\[/ {
    /^\[token\]/!b
    :a
    N
    /^\[/!ba
    s/^provider = .*/# &/
    i\
'"$NEW_TOKEN_PROVIDER"'
}' "$cofig_file"

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
sudo bash -c "cat <<EOF > $conf
ServerName controller
EOF"

echo "apache updated successfully"

# restart the service
service apache2 restart

cat <<EOF > /home/admin-openrc
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
