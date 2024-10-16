#!/bin/bash

#---controller--
DB_ROOT_PASS="123"

SQL_COMMANDS=$(cat <<EOF 
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'ci123';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'ci123';
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

#Create a cinder user:
openstack user create --domain default --password "ci123" cinder

# Add the admin role to the cinder user:
openstack role add --project service --user cinder admin

# Create the cinderv3 service entity.
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

# Create the Block Storage service API endpoints:
openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s

# install the package
sudo apt install cinder-api cinder-scheduler -y

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
else
    echo "$config_file not found. 
    exiting....."
    exit 1
fi 

# Populate the Block Storage database.
su -s /bin/sh -c "cinder-manage db sync" cinder

config_file1="/etc/nova/nova.conf"
cinder="os_region_name = RegionOne"
conn="/etc/nova/nova-cinder.conf"
if [ -f "$config_file1" ]; then
    	echo "updating the $config_file1"
    	sudo cp $config_file1 $conn.bak
    	
    	# edit cinder section 
	if grep -q "^\[cinder\]" "$config_file1"; then
	    echo "[cinder] section found in $config_file1"

	    # Add the cinder below the [cinder] section
	    sudo sed -i "/^\[cinder\]/a$oslo_con" "$config_file1"
	    echo "region_name to [cinder] section"

	else
	    echo "[cinder] section not found in $config_file1"
	    echo "Adding the [cinder] section and new connection string"

    	# If the [cinder] section doesn't exist, append it to the config file
    	echo -e "\n[cinder]\n$cinder" | sudo tee -a "$config_file1"
	fi
else
    echo "$config_file1 not found. 
    exiting....."
    exit 1
fi 

#Restart the Compute API service:
service nova-api restart

#Restart the Block Storage services:
service cinder-scheduler restart
service apache2 restart
echo "services restarted successfully, controller node setup done !!!!"

#-------Compute Node Setup-----------

# install supporting utility packages.
sudo apt install lvm2 thin-provisioning-tools -y

# Create the LVM physical volume /dev/sdb:
sudo pvcreate /dev/sdb

# Create the LVM volume group cinder-volumes:
sudo vgcreate cinder-volumes /dev/sdb

conf="/etc/lvm/lvm.conf"
sudo cp $conf $conf.bak
sed -i '/devices {/!b;n;c\	filter = [ "a/sdb/", "r/.*/"]' $conf
echo "lvm conf done...."    	

#Install the packages:
sudo apt install cinder-volume tgt -y
lvm1="volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = tgtadm
volume_backend_name = lvm1
iscsi_ip_address = 192.168.56.103"
lvm2="volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = tgtadm
volume_backend_name = lvm1
iscsi_ip_address = 192.168.56.101"
def="enabled_backends = lvm1, lvm2
glance_api_servers = http://controller:9292"
    	
if [ -f "$config_file" ]; then
    	echo "updating the $config_file"
    	sudo cp $config_file $config_file.1.bak
    	
    	# Editing the [lvm] section
	if grep -q "^\[lvm1\]" "$config_file"; then
	    echo "[lvm1] section found in $config_file"

	    # Add the lvm below the [lvm] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[lvm1\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in lvm1 section"
		    sudo sed -i "/^\[lvm1\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to lvm section"
		    sudo sed -i "/^\[lvm1\]/a$key = $value" "$config_file"
		fi
	    done <<< "$lvm1"
	    echo "lvm added to [lvm1] section"

	else
	    echo "[lvm1] section not found in $config_file"
	    echo "Adding the [lvm1] section and new connection string"

    	# If the [lvm1] section doesn't exist, append it to the config file
    	echo "[lvm1]" >> "$config_file"
    	
    	# Add the lvm below the [lvm1] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[lvm1\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in lvm1 section"
	       sudo sed -i "/^\[lvm1\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to lvm1 section"
	       sudo sed -i "/^\[lvm1\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$lvm1"
	fi
	
	# Editing the [lvm2] section
	if grep -q "^\[lvm2\]" "$config_file"; then
	    echo "[lvm2] section found in $config_file"

	    # Add the lvm below the [lvm2] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[lvm2\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in lvm2 section"
		    sudo sed -i "/^\[lvm2\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to lvm2 section"
		    sudo sed -i "/^\[lvm2\]/a$key = $value" "$config_file"
		fi
	    done <<< "$lvm2"
	    echo "lvm added to [lvm2] section"

	else
	    echo "[lvm2] section not found in $config_file"
	    echo "Adding the [lvm2] section and new connection string"

    	# If the [lvm2] section doesn't exist, append it to the config file
    	echo "[lvm2]" >> "$config_file"
    	
    	# Add the lvm below the [lvm2] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[lvm2\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in lvm2 section"
	       sudo sed -i "/^\[lvm2\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to lvm2 section"
	       sudo sed -i "/^\[lvm2\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$lvm2"
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
