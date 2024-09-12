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

#keystone configuration
config_file="/etc/keystone/keystone.conf"
cp $config_file $config_file.bak

sudo bash -c "cat <<EOF > $config_file
# Update the [database] section
sed -i "/^\[database\]/,/^connection/ s|^connection *=.*|connection = mysql+pymysql://keystone:k123@controller/keystone|" $config_file

# Update the [token] section
sed -i "/^\[token\]/,/^provider/ s|^provider *=.*|provider = fernet|" $CONFIG_FILE

# Check if the updates were successful
if [ $? -eq 0 ]; then
    echo "Database configuration in $CONFIG_FILE updated successfully!"
else
    echo "Failed to update the database configuration."
fi
EOF
"
echo "file updated"
