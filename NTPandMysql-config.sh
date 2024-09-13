#!/bin/bash

# update the system
sudo apt update

# Define variables
NTP_SERVER="your.ntp.server"  # Replace with your NTP server
SUBNET="10.0.2.15/24"  # Replace with your subnet if different
MYSQL_BIND_ADDRESS="10.0.2.15"  # Replace with your MySQL bind address
MEMCACHED_IP="10.0.2.15"  # Replace with your management IP address for memcached
ETCD_IP="10.0.2.15"  # Replace with your etcd management IP address

#---chrony---
# install the chrony
sudo apt install chrony

# Update chrony configuration
CONFIG_FILE="/etc/chrony/chrony.conf"
echo "Creating the backup of the original file"
cp $CONFIG_FILE $CONFIG_FILE.bak
 
echo "Updating /etc/chrony/chrony.conf..."
sudo bash -c "cat <<EOF > $CONFIG_FILE
# Use public servers from the pool.ntp.org project.
server $NTP_SERVER iburst

# Allow clients from the local subnet
allow $SUBNET

# If necessary, replace $SUBNET with a description of your subnet.
EOF"

# Restart chrony service
echo "Restarting chrony service..."
sudo systemctl restart chrony

# verify Operation
echo "Verify Operations"
chronyc sources

#---MariaDB-----
# install MariaDB
sudo apt install mariadb-server python3-pymysql

# Configure MariaDB
echo "Updating /etc/mysql/mariadb.conf.d/99-openstack.cnf..."
sudo bash -c "cat <<EOF > /etc/mysql/mariadb.conf.d/99-openstack.cnf
[mysqld]
bind-address = $MYSQL_BIND_ADDRESS

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF"

# Restart MySQL/MariaDB service
echo "Restarting MySQL/MariaDB service..."
sudo systemctl restart mysql

# ------Rabbit message queue------
# Rabbit message queue installation and configuration
sudo apt install rabbitmq-server

# Add the openstack user and Replace RABBIT_PASS with a suitable password.
rabbitmqctl add_user openstack R123

# Permit configuration, write, and read access for the openstack user:
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#-------memcached Server-------
# install memcached server
sudo apt install memcached python3-memcache

# Configure memcached
CONFIG_FILE_mem="/etc/memcached.conf"
echo "Create the backup of the memcached.conf file"
cp $CONFIG_FILE_mem $CONFIG_FILE_mem.bak

echo "Updating /etc/memcached.conf..."
sudo bash -c "sed -i 's/-l .*/-l $MEMCACHED_IP/' $CONFIG_FILE_mem"

# Restart memcached service
echo "Restarting memcached service..."
sudo systemctl restart memcached

#-----etcd--------
# install etcd 
sudo apt install etcd

# Configure etcd
CONFIG_FILE_etcd="/etc/default/etcd"
cp $CONFIG_FILE_etcd $CONFIG_FILE_etcd.bak

echo "Updating /etc/default/etcd..."
sudo bash -c "cat <<EOF > $CONFIG_FILE_mem
ETCD_NAME=\"controller\"
ETCD_DATA_DIR=\"/var/lib/etcd\"
ETCD_INITIAL_CLUSTER_STATE=\"new\"
ETCD_INITIAL_CLUSTER_TOKEN=\"etcd-cluster-01\"
ETCD_INITIAL_CLUSTER=\"controller=http://$ETCD_IP:2380\"
ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http://$ETCD_IP:2380\"
ETCD_ADVERTISE_CLIENT_URLS=\"http://$ETCD_IP:2379\"
ETCD_LISTEN_PEER_URLS=\"http://0.0.0.0:2380\"
ETCD_LISTEN_CLIENT_URLS=\"http://$ETCD_IP:2379\"
EOF"

# Enable and restart etcd service
echo "Enabling and restarting etcd service..."
sudo systemctl enable etcd
sudo systemctl restart etcd

#-------openstack Package-----
#Openstack packages
sudo add-apt-repository cloud-archive:bobcat

#client installation
sudo apt install python3-openstackclient

echo "Openstack Prerequisites installation, Configuration and setup completed successfully!"
