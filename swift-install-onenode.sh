#!/bin/bash

#----controller node---

. /home/openstack/admin-openrc

# Create the swift user:
openstack user create --domain default --password "sw123" swift

# Add the admin role to the swift user.
openstack role add --project service --user swift admin

# Create the swift service entity.
openstack service create --name swift --description "OpenStack Object Storage" object-store

# Create the Object Storage service API endpoints.
openstack endpoint create --region RegionOne object-store public http://controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne object-store internal http://controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne object-store admin http://controller:8080/v1

# install the package
sudo apt-get install swift swift-proxy python3-swiftclient python3-keystoneclient python3-keystonemiddleware memcached -y

# create /etc/swift directory
sudo touch /etc/swift
cd /etc/swift

# Obtain the proxy service configuration file from the Object Storage source repository:
curl -o /etc/swift/proxy-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/proxy-server.conf-sample

config_file="/etc/swift/proxy-server.conf"
def="bind_port = 8080
user = swift
swift_dir = /etc/swift"
pipe="pipeline = catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"
app="use = egg:swift#proxy
account_autocreate = True"
key="use = egg:swift#keystoneauth
operator_roles = admin,user"
auth="paste.filter_factory = keystonemiddleware.auth_token:filter_factory
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_id = default
user_domain_id = default
project_name = service
username = swift
password = sw123
delay_auth_decision = True"
cache="use = egg:swift#memcache
memcache_servers = controller:11211"

if [ -f "$config_file" ]; then
    	echo "updating the $config_file"
    	sudo cp $config_file $config_file.1.bak
    
    	# In the [DEFAULT] section, configure the bind port, user, and configuration directory.
	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"

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

	# In the [pipeline:main] section, remove the tempurl and tempauth modules and add the authtoken and keystoneauth modules.
    	if grep -q "^\[pipeline:main\]" "$config_file"; then
	    echo "[pipeline:main] section found in $config_file"
	    # Check if there is already a connection string in the [pipeline:main] section
	    if grep -A1 "^\[pipeline:main\]" "$config_file" | grep -q "^pipeline ="; then
		echo "Existing connection string found, commenting it out"
		# Comment out the existing connection string
		sudo sed -i "s/^.*pipeline = .*/# &/" "$config_file"
	    else
		echo "No existing connection string found in the [pipeline:main] section"
	    fi
	    # Add the new connection string below the [pipeline:main] section
	    sudo sed -i "/^\[pipeline:main\]/a$pipe" "$config_file"
	    echo "New connection string added to [pipeline:main] section"
    	else
	    echo "[pipeline:main] section not found in $config_file"
	    echo "Adding the [pipeline:main] section and new connection string"
    	# If the [database] section doesn't exist, append it to the config file
    	echo -e "\n[pipeline:main]\n$pipe" | sudo tee -a "$config_file"
    	fi
	
	# In the [app:proxy-server] section, enable automatic account creation:
	if grep -q "^\[app:proxy-server\]" "$config_file"; then
	    echo "[app:proxy-server] section found in $config_file"

	    # Add the app:proxy-server below the [app:proxy-server] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[app:proxy-server\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in app:proxy-server section"
		    sudo sed -i "/^\[app:proxy-server\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to app:proxy-server section"
		    sudo sed -i "/^\[app:proxy-server\]/a$key = $value" "$config_file"
		fi
	    done <<< "$app"
	    echo "app:proxy-server added to [app:proxy-server] section"

	else
	    echo "[app:proxy-server] section not found in $config_file"
	    echo "Adding the [app:proxy-server] section and new connection string"

    	# If the [app:proxy-server] section doesn't exist, append it to the config file
    	echo "[app:proxy-server]" >> "$config_file"
    	
    	# Add the app:proxy-server below the [app:proxy-server] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[app:proxy-server\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in app:proxy-server section"
	       sudo sed -i "/^\[app:proxy-server\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to app:proxy-server section"
	       sudo sed -i "/^\[app:proxy-server\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$app"
	fi
	
	#In the [filter:keystoneauth] section, configure the operator roles:
	if grep -q "^\[filter:keystoneauth\]" "$config_file"; then
	    echo "[filter:keystoneauth] section found in $config_file"

	    # Add the filter:keystoneauth below the [filter:keystoneauth] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[filter:keystoneauth\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in filter:keystoneauth section"
		    sudo sed -i "/^\[filter:keystoneauth\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to filter:keystoneauth section"
		    sudo sed -i "/^\[filter:keystoneauth\]/a$key = $value" "$config_file"
		fi
	    done <<< "$key"
	    echo "filter:keystoneauth added to [filter:keystoneauth] section"

	else
	    echo "[filter:keystoneauth] section not found in $config_file"
	    echo "Adding the [filter:keystoneauth] section and new connection string"

    	# If the [filter:keystoneauth] section doesn't exist, append it to the config file
    	echo "[filter:keystoneauth]" >> "$config_file"
    	
    	# Add the filter:keystoneauth below the [filter:keystoneauth] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[filter:keystoneauth\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in filter:keystoneauth section"
	       sudo sed -i "/^\[filter:keystoneauth\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to filter:keystoneauth section"
	       sudo sed -i "/^\[filter:keystoneauth\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$key"
	fi 
	   
	# In the [filter:cache] section, configure the memcached location:
	   
	if grep -q "^\[filter:cache\]" "$config_file"; then
	    echo "[filter:cache] section found in $config_file"

	    # Add the filter:cache below the [filter:cache] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[filter:cache\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in filter:cache section"
		    sudo sed -i "/^\[filter:cache\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to filter:cache section"
		    sudo sed -i "/^\[filter:cache\]/a$key = $value" "$config_file"
		fi
	    done <<< "$cache"
	    echo "DEFAULT added to [filter:cache] section"

	else
	    echo "[filter:cache] section not found in $config_file"
	    echo "Adding the [filter:cache] section and new connection string"

    	# If the [filter:cache] section doesn't exist, append it to the config file
    	echo "[filter:cache]" >> "$config_file"
    	
    	# Add the DEFAULT below the [filter:cache] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[filter:cache\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in filter:cache section"
	       sudo sed -i "/^\[filter:cache\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to filter:cache section"
	       sudo sed -i "/^\[filter:cache\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$cache"
	fi

else
    echo "$config_file does not exist
    exiting."
    exit 1
fi

# ---- compute installation

# install the package
sudo apt-get install xfsprogs rsync -y
# Format the /dev/sdb and /dev/sdc devices as XFS:
mkfs.xfs /dev/sdc
# Create the mount point directory structure:
mkdir -p /srv/node/sdc
uuid=$(blkid -s UUID -o value "/dev/sdc")
cp /etc/fstab /etc/fstab.bak
echo "UUID="$uuid" /srv/node/sdc xfs noatime 0 2" >> /etc/fstab
mount /srv/node/sdc

rsyncd="uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = 10.0.2.15

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock"

conf="/etc/rsyncd.conf"
if [ -f "$conf" ] ; then
    sudo cp $conf $conf.bak
    echo "$rsyncd" >> $conf
    
else
    echo "$conf file not found"
    sudo touch $conf
    echo "$rsyncd" >> $conf
fi

# Edit the /etc/default/rsync file and enable the rsync service:
echo "RSYNC_ENABLE=true" >> /etc/default/rsync

# Start the rsync service:
sudo service rsync start

# Install the packages:
sudo apt-get install swift swift-account swift-container swift-object -y

# Obtain the accounting, container, and object service configuration files from the Object Storage source repository:
curl -o /etc/swift/account-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/account-server.conf-sample
curl -o /etc/swift/container-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/container-server.conf-sample
curl -o /etc/swift/object-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/object-server.conf-sample
curl -o /etc/swift/internal-client.conf https://raw.githubusercontent.com/openstack/swift/refs/heads/master/etc/internal-client.conf-sample

# Edit the /etc/swift/account-server.conf file and complete the following actions:
config_file="/etc/swift/account-server.conf"
declare -A config_vars=(
["bind_ip"]="10.0.2.15"
["bind_port"]="6202"
["user"]="swift"
["swift_dir"]="/etc/swift"
["devices"]="/srv/node"
["mount_check"]="True"
)

a_pipe="pipeline = healthcheck recon account-server"
recon="use = egg:swift#recon
recon_cache_path = /var/cache/swift"

if [ -f "$config_file" ]; then
    	echo "updating the $config_file"
    	sudo cp $config_file $config_file.bak
    	
 	#In the [DEFAULT] and [DEFAULT] sections, configure database access.
    	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"
	    for key in "${!config_vars[@]}"; do
	        value="${config_vars[$key]}"
	        if grep -q "^$key" "$config_file"; then
	            sed -i "/^\[DEFAULT\]/,/^\[/{s|^$key =.*|$key = $value|}" "$config_file"
	            echo "updated $key to $value"
	        else
	            sed -i "/^\[DEFAULT]/a $key = $value" "$config_file"
	            echo "Added $key wih value $value"
	        fi
	    done
	fi
	
	# In the [pipeline:main] section
    	if grep -q "^\[pipeline:main\]" "$config_file"; then
	    echo "[pipeline:main] section found in $config_file"
	    # Check if there is already a connection string in the [pipeline:main] section
	    if grep -A1 "^\[pipeline:main\]" "$config_file" | grep -q "^pipeline ="; then
		echo "Existing connection string found, commenting it out"
		# Comment out the existing connection string
		sudo sed -i "s/^.*pipeline = .*/# &/" "$config_file"
	    else
		echo "No existing connection string found in the [pipeline:main] section"
	    fi
	    # Add the new connection string below the [pipeline:main] section
	    sudo sed -i "/^\[pipeline:main\]/a$a_pipe" "$config_file"
	    echo "New connection string added to [pipeline:main] section"
    	else
	    echo "[pipeline:main] section not found in $config_file"
	    echo "Adding the [pipeline:main] section and new connection string"
    	# If the [pipeline:main] section doesn't exist, append it to the config file
    	echo -e "\n[pipeline:main]\n$a_pipe" | sudo tee -a "$config_file"
    	fi
    	
    	#In the [filter:recon] section, configure the recon (meters) cache directory:
	   
	if grep -q "^\[filter:recon\]" "$config_file"; then
	    echo "[filter:recon] section found in $config_file"

	    # Add the filter:cache below the [filter:cache] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[filter:recon\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in filter:recon section"
		    sudo sed -i "/^\[filter:recon\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to filter:recon section"
		    sudo sed -i "/^\[filter:recon\]/a$key = $value" "$config_file"
		fi
	    done <<< "$recon"
	    echo "DEFAULT added to [filter:recon] section"

	else
	    echo "[filter:recon] section not found in $config_file"
	    echo "Adding the [filter:recon] section and new connection string"

    	# If the [filter:recon] section doesn't exist, append it to the config file
    	echo "[filter:recon]" >> "$config_file"
    	
    	# Add the DEFAULT below the [filter:recon] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[filter:recon\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in filter:recon section"
	       sudo sed -i "/^\[filter:recon\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to filter:recon section"
	       sudo sed -i "/^\[filter:recon\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$recon"
	fi
else
    echo "$config_file not found"
    exit 1
fi

# Edit the /etc/swift/container-server.conf file and complete the following actions:
config_file1="/etc/swift/container-server.conf"

declare -A config_vars1=(
["bind_ip"]="10.0.2.15"
["bind_port"]="6201"
["user"]="swift"
["swift_dir"]="/etc/swift"
["devices"]="/srv/node"
["mount_check"]="True"
)

c_pipe="pipeline = healthcheck recon container-server"
recon1="use = egg:swift#recon
recon_cache_path = /var/cache/swift"

if [ -f "$config_file1" ]; then
    	echo "updating the $config_file1"
    	sudo cp $config_file1 $config_file1.bak
    	
 	#In the [DEFAULT] and [DEFAULT] sections, configure database access.
    	if grep -q "^\[DEFAULT\]" "$config_file1"; then
	    echo "[DEFAULT] section found in $config_file1"
	    for key in "${!config_vars1[@]}"; do
	        value="${config_vars1[$key]}"
	        if grep -q "^$key" "$config_file1"; then
	            sed -i "/^\[DEFAULT\]/,/^\[/{s|^$key =.*|$key = $value|}" "$config_file1"
	            echo "updated $key to $value"
	        else
	            sed -i "/^\[DEFAULT]/a $key = $value" "$config_file1"
	            echo "Added $key wih value $value"
	        fi
	    done
	fi
	
	# In the [pipeline:main] section
    	if grep -q "^\[pipeline:main\]" "$config_file1"; then
	    echo "[pipeline:main] section found in $config_file1"
	    # Check if there is already a connection string in the [pipeline:main] section
	    if grep -A1 "^\[pipeline:main\]" "$config_file1" | grep -q "^pipeline ="; then
		echo "Existing connection string found, commenting it out"
		# Comment out the existing connection string
		sudo sed -i "s/^.*pipeline = .*/# &/" "$config_file1"
	    else
		echo "No existing connection string found in the [pipeline:main] section"
	    fi
	    # Add the new connection string below the [pipeline:main] section
	    sudo sed -i "/^\[pipeline:main\]/a$c_pipe" "$config_file1"
	    echo "New connection string added to [pipeline:main] section"
    	else
	    echo "[pipeline:main] section not found in $config_file1"
	    echo "Adding the [pipeline:main] section and new connection string"
    	# If the [pipeline:main] section doesn't exist, append it to the config file
    	echo -e "\n[pipeline:main]\n$c_pipe" | sudo tee -a "$config_file1"
    	fi
    	
    	#In the [filter:recon] section, configure the recon (meters) cache directory:
	   
	if grep -q "^\[filter:recon\]" "$config_file1"; then
	    echo "[filter:recon] section found in $config_file1"

	    # Add the filter:cache below the [filter:cache] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[filter:recon\]" "$config_file1" | grep -q "^$key ="; then
		    echo "Updating $key in filter:recon section"
		    sudo sed -i "/^\[filter:recon\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file1"
		else
		    echo "Adding $key to filter:recon section"
		    sudo sed -i "/^\[filter:recon\]/a$key = $value" "$config_file1"
		fi
	    done <<< "$recon1"
	    echo "DEFAULT added to [filter:recon] section"

	else
	    echo "[filter:recon] section not found in $config_file1"
	    echo "Adding the [filter:recon] section and new connection string"

    	# If the [filter:recon] section doesn't exist, append it to the config file
    	echo "[filter:recon]" >> "$config_file1"
    	
    	# Add the DEFAULT below the [filter:recon] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[filter:recon\]" "$config_file1" | grep -q "^$key ="; then
	       echo "Updating $key in filter:recon section"
	       sudo sed -i "/^\[filter:recon\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file1"
	   else
	       echo "Adding $key to filter:recon section"
	       sudo sed -i "/^\[filter:recon\]/a$key = $value" "$config_file1"
	   fi
	   done <<< "$recon1"
	fi
else
    echo "$config_file1 not found"
    exit 1
fi

# Edit the /etc/swift/object-server.conf file and complete the following actions:
config_file2="/etc/swift/object-server.conf"

declare -A config_vars2=(
["bind_ip"]="10.0.2.15"
["bind_port"]="6200"
["user"]="swift"
["swift_dir"]="/etc/swift"
["devices"]="/srv/node"
["mount_check"]="True"
)

b_pipe="pipeline = healthcheck recon object-server"
recon2="use = egg:swift#recon
recon_cache_path = /var/cache/swift
recon_cache_path = /var/lock"

if [ -f "$config_file2" ]; then
    	echo "updating the $config_file2"
    	sudo cp $config_file2 $config_file2.bak
    	
 	#In the [DEFAULT] and [DEFAULT] sections, configure database access.
    	if grep -q "^\[DEFAULT\]" "$config_file2"; then
	    echo "[DEFAULT] section found in $config_file2"
	    for key in "${!config_vars2[@]}"; do
	        value="${config_vars2[$key]}"
	        if grep -q "^$key" "$config_file2"; then
	            sed -i "/^\[DEFAULT\]/,/^\[/{s|^$key =.*|$key = $value|}" "$config_file2"
	            echo "updated $key to $value"
	        else
	            sed -i "/^\[DEFAULT]/a $key = $value" "$config_file2"
	            echo "Added $key wih value $value"
	        fi
	    done
	fi
	
	# In the [pipeline:main] section
    	if grep -q "^\[pipeline:main\]" "$config_file2"; then
	    echo "[pipeline:main] section found in $config_file2"
	    # Check if there is already a connection string in the [pipeline:main] section
	    if grep -A1 "^\[pipeline:main\]" "$config_file2" | grep -q "^pipeline ="; then
		echo "Existing connection string found, commenting it out"
		# Comment out the existing connection string
		sudo sed -i "s/^.*pipeline = .*/# &/" "$config_file2"
	    else
		echo "No existing connection string found in the [pipeline:main] section"
	    fi
	    # Add the new connection string below the [pipeline:main] section
	    sudo sed -i "/^\[pipeline:main\]/a$b_pipe" "$config_file2"
	    echo "New connection string added to [pipeline:main] section"
    	else
	    echo "[pipeline:main] section not found in $config_file2"
	    echo "Adding the [pipeline:main] section and new connection string"
    	# If the [pipeline:main] section doesn't exist, append it to the config file
    	echo -e "\n[pipeline:main]\n$b_pipe" | sudo tee -a "$config_file2"
    	fi
    	
    	#In the [filter:recon] section, configure the recon (meters) cache directory:
	   
	if grep -q "^\[filter:recon\]" "$config_file2"; then
	    echo "[filter:recon] section found in $config_file2"

	    # Add the filter:cache below the [filter:cache] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[filter:recon\]" "$config_file2" | grep -q "^$key ="; then
		    echo "Updating $key in filter:recon section"
		    sudo sed -i "/^\[filter:recon\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
		else
		    echo "Adding $key to filter:recon section"
		    sudo sed -i "/^\[filter:recon\]/a$key = $value" "$config_file2"
		fi
	    done <<< "$recon2"
	    echo "DEFAULT added to [filter:recon] section"

	else
	    echo "[filter:recon] section not found in $config_file2"
	    echo "Adding the [filter:recon] section and new connection string"

    	# If the [filter:recon] section doesn't exist, append it to the config file
    	echo "[filter:recon]" >> "$config_file2"
    	
    	# Add the DEFAULT below the [filter:recon] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[filter:recon\]" "$config_file1" | grep -q "^$key ="; then
	       echo "Updating $key in filter:recon section"
	       sudo sed -i "/^\[filter:recon\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
	   else
	       echo "Adding $key to filter:recon section"
	       sudo sed -i "/^\[filter:recon\]/a$key = $value" "$config_file2"
	   fi
	   done <<< "$recon2"
	fi
else
    echo "$config_file2 not found"
    exit 1
fi

#Ensure proper ownership of the mount point directory structure:
chown -R swift:swift /srv/node

#Create the recon directory and ensure proper ownership of it:
mkdir -p /var/cache/swift
chown -R root:swift /var/cache/swift
chmod -R 775 /var/cache/swift

# ------- Create Ring on controller Node ----------

cd /etc/swift

# ----- Create Account Ring ---------
# Create the base account.builder file
swift-ring-builder account.builder create 10 1 1

# Add each storage node to the ring:
swift-ring-builder account.builder add --region 1 --zone 1 --ip 10.0.2.15 --port 6202 --device sdc --weight 100

# Verify the ring contents:
swift-ring-builder account.builder

# Rebalance the ring:
swift-ring-builder account.builder rebalance

# ----------Create Container Ring-----------
# Create the base container.builder file:
swift-ring-builder container.builder create 10 1 1

# Add each storage node to the ring:
swift-ring-builder container.builder add --region 1 --zone 1 --ip 10.0.2.15 --port 6201 --device sdc --weight 100

# Verify the ring contents:
swift-ring-builder container.builder

# Rebalance the ring:
swift-ring-builder container.builder rebalance

# ------------- Create Object Ring ----------
#Create the base object.builder file:
swift-ring-builder object.builder create 10 1 1

# Add each storage node to the ring
swift-ring-builder object.builder add --region 1 --zone 1 --ip 10.0.2.15 --port 6200 --device sdc --weight 100

#Verify the ring contents:
swift-ring-builder object.builder

# Rebalance the ring:
swift-ring-builder object.builder rebalance

# Obtain the /etc/swift/swift.conf file from the Object Storage source repository:
curl -o /etc/swift/swift.conf https://opendev.org/openstack/swift/raw/branch/master/etc/swift.conf-sample

val=$(openssl rand -hex 6)
val1=$(openssl rand -hex 6)
conf_file="/etc/swift/swift.conf"
shsuffix="swift_hash_path_suffix = $val"
shprefix="swift_hash_path_prefix = $val1"
policy="name = Policy-0
default = yes"

if [ -f "$conf_file" ]; then
	sudo cp $conf_file $conf_file.bak
	#In the [swift-hash] and [swift-hash] sections, configure swift_hash_path_suffix .
    	if grep -q "^\[swift-hash\]" "$conf_file"; then
	    echo "[swift-hash] section found in $conf_file"
	    # Check if there is already a swift_hash_path_suffix string in the [api_database] section
	    if grep -A1 "^\[swift-hash\]" "$conf_file" | grep -q "^swift_hash_path_suffix ="; then
		echo "Existing swift_hash_path_suffix string found, commenting it out"
		# Comment out the existing connection string
		sudo sed -i "s/^.*swift_hash_path_suffix = .*/# &/" "$conf_file"
	    else
		echo "No existing swift_hash_path_suffix string found in the [swift-hash] section"
	    fi
	    # Add the new swift_hash_path_suffix string below the [swift-hash] section
	    sudo sed -i "/^\[swift-hash\]/a$shsuffix" "$conf_file"
	    echo "New swift_hash_path_suffix string added to [swift-hash] section"
    	else
	    echo "[swift-hash] section not found in $conf_file"
	    echo "Adding the [swift-hash] section and new connection string"
    	# If the [swift-hash] section doesn't exist, append it to the config file
    	echo -e "\n[swift-hash]\n$shsuffix" | sudo tee -a "$conf_file"
    	fi
    	
    	#In the [swift-hash] and [swift-hash] sections, configure swift_hash_path_prefix .
    	if grep -q "^\[swift-hash\]" "$conf_file"; then
	    echo "[swift-hash] section found in $conf_file"
	    # Check if there is already a swift_hash_path_prefix string in the [swift-hash] section
	    if grep -A1 "^\[swift-hash\]" "$conf_file" | grep -q "^swift_hash_path_prefix ="; then
		echo "Existing swift_hash_path_prefix string found, commenting it out"
		# Comment out the existing connection string
		sudo sed -i "s/^.*swift_hash_path_prefix = .*/# &/" "$conf_file"
	    else
		echo "No existing swift_hash_path_prefix string found in the [swift-hash] section"
	    fi
	    # Add the new swift_hash_path_prefix string below the [swift-hash] section
	    sudo sed -i "/^\[swift-hash\]/a$shprefix" "$conf_file"
	    echo "New swift_hash_path_prefix string added to [swift-hash] section"
    	else
	    echo "[swift-hash] section not found in $conf_file"
	    echo "Adding the [swift-hash] section and new swift_hash_path_prefix string"
    	# If the [swift-hash] section doesn't exist, append it to the config file
    	echo -e "\n[swift-hash]\n$shprefix" | sudo tee -a "$conf_file"
    	fi
    	
    	# Editing the [storage-policy:0] section
	if grep -q "^\[storage-policy:0\]" "$conf_file"; then
	    echo "[storage-policy:0] section found in $conf_file"

	    # Add the defaults below the [storage-policy:0] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[storage-policy:0\]" "$conf_file" | grep -q "^$key ="; then
		    echo "Updating $key in storage-policy:0 section"
		    sudo sed -i "/^\[storage-policy:0\]/,/^\[/ s|^$key =.*|$key = $value|" "$conf_file"
		else
		    echo "Adding $key to storage-policy:0 section"
		    sudo sed -i "/^\[storage-policy:0\]/a$key = $value" "$conf_file"
		fi
	    done <<< "$policy"
	    echo "storage-policy:0 added to [storage-policy:0] section"

	else
	    echo "[storage-policy:0] section not found in $conf_file"
	    echo "Adding the [storage-policy:0] section and new connection string"

    	# If the [storage-policy:0] section doesn't exist, append it to the config file
    	echo "[storage-policy:0]" >> "$conf_file"
    	
    	# Add the defaults below the [storage-policy:0] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[storage-policy:0\]" "$conf_file" | grep -q "^$key ="; then
	       echo "Updating $key in storage-policy:0 section"
	       sudo sed -i "/^\[storage-policy:0\]/,/^\[/ s|^$key =.*|$key = $value|" "$conf_file"
	   else
	       echo "Adding $key to storage-policy:0 section"
	       sudo sed -i "/^\[storage-policy:0\]/a$key = $value" "$conf_file"
	   fi
	   done <<< "$policy"
	fi
else
    echo "$conf_file does not exists "
    exit 1
fi

#On all nodes, ensure proper ownership of the configuration directory:
chown -R root:swift /etc/swift

# On the controller node and any other nodes running the proxy service, restart the Object Storage proxy service including its dependencies:
sudo service memcached restart
sudo service swift-proxy restart

# On the storage nodes, start the Object Storage services:
swift-init all start
