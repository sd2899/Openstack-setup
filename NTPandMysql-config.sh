#!/bin/bash

# Variables
NTP_SERVER="0.pool.ntp.org"  # Replace with your NTP server if needed
SUBNET="10.0.0.0/24"
MYSQL_BIND_ADDRESS="10.0.2.15"
CHRONY_CONF="/etc/chrony/chrony.conf"
MYSQL_CONF="/etc/mysql/mariadb.conf.d/99-openstack.cnf"

# Backup the original chrony.conf
if [ -f "$CHRONY_CONF" ]; then
    cp $CHRONY_CONF $CHRONY_CONF.bak
fi

# Update the chrony.conf file
echo "Updating $CHRONY_CONF..."

# Using 'sed' to insert or replace the allow statement
sed -i "s/^allow .*/allow $SUBNET/" $CHRONY_CONF

# Add the NTP server line if it's not already there
grep -q "^server $NTP_SERVER" $CHRONY_CONF || echo "server $NTP_SERVER iburst" >> $CHRONY_CONF

# Restart the chrony service
echo "Restarting the chrony service..."
sudo service chrony restart

if [ $? -eq 0 ]; then
    echo "Chrony configuration updated and service restarted successfully!"
else
    echo "Failed to restart chrony service."
fi

# Create and configure the 99-openstack.cnf file for MySQL
echo "Creating $MYSQL_CONF..."

# Backup existing MySQL configuration if exists
if [ -f "$MYSQL_CONF" ]; then
    cp $MYSQL_CONF $MYSQL_CONF.bak
fi

# Write the new configuration to the file
cat <<EOF | sudo tee $MYSQL_CONF > /dev/null
[mysqld]
bind-address = $MYSQL_BIND_ADDRESS

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

# Restart the MySQL service
echo "Restarting the MySQL service..."
sudo service mysql restart

if [ $? -eq 0 ]; then
    echo "MySQL configuration updated and service restarted successfully!"
else
    echo "Failed to restart MySQL service."
fi

