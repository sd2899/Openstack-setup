#! /bin/bash

#---- Neutron Installation----------

DB_ROOT_PASS="123"

SQL_COMMANDS=$(cat <<EOF 
CREATE DATABASE neutron;

GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'ne123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'ne123';
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

# Create the neutron user.
openstack user create --domain default --password "ne123" neutron

# Add the admin role to the neutron user.
openstack role add --project service --user neutron admin

# Create the neutron service entity.
openstack service create --name neutron --description "OpenStack Networking" network

# Create the Networking service API endpoints.
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696

# install the neutron packages.
sudo apt install neutron-server neutron-plugin-ml2 neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent -y

# Edit the /etc/neutron/neutron.conf file and complete the following actions. In the [database] section, configure database access:

config_file="/etc/neutron/neutron.conf"
db_con="connection = mysql+pymysql://neutron:ne123@controller/neutron"
def_ser="core_plugin = ml2
service_plugins = router
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true"
def_trans="transport_url = rabbit://openstack:R123@controller"
keystone_authtoken_config="www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = ne123"
nova_conf="auth_url = http://controller:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = nova
password = no123"
oslo_conf="lock_path = /var/lib/neutron/tmp"

config_file1="/etc/neutron/plugins/ml2/ml2_conf.ini"
ml2_conf="type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security"
ml2_type_flat="flat_networks = provider"
ml2_type_vxlan="vni_ranges = 1:1000"

config_file2="/etc/neutron/plugins/ml2/openvswitch_agent.ini"
ovs="bridge_mappings = provider:br-ex
local_ip = 10.0.2.15"
agent="tunnel_types = vxlan
l2_population = true"
securitygroup="enable_security_group = true
firewall_driver = openvswitch"

config_file3="/etc/neutron/l3_agent.ini"
def1="interface_driver = openvswitch"

config_file4="/etc/neutron/dhcp_agent.ini"
def="interface_driver = openvswitch
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true"

config_file5="/etc/neutron/metadata_agent.ini"
def2="nova_metadata_host = controller
metadata_proxy_shared_secret = fe6702d1e7648ffce39f"

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
    	
    	# Editing the [DEFAULT] section
	if grep -q "^\[DEFAULT\]" "$config_file"; then
	    echo "[DEFAULT] section found in $config_file"

	    # Add the keystone_authtoken below the [DEFAULT] section
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
	    done <<< "$def_ser"
	    echo "default services added to [DEFAULT] section"

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
	   done <<< "$def_ser"
	fi
    	
    	# Check if the [DEFAULT] section exists
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
	    sudo sed -i "/^\[DEFAULT\]/a$def_trans" "$config_file"
	    echo "New connection string added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file"
	    echo "Adding the [DEFAULT] section and new connection string"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo -e "\n[DEFAULT]\n\n$def_trans" | sudo tee -a "$config_file"
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
	
	# Editing the [nova] section
	if grep -q "^\[nova\]" "$config_file"; then
	    echo "[nova] section found in $config_file"

	    # Add the nova config below in the [nova] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[nova\]" "$config_file" | grep -q "^$key ="; then
		    echo "Updating $key in nova section"
		    sudo sed -i "/^\[nova\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
		else
		    echo "Adding $key to nova section"
		    sudo sed -i "/^\[nova\]/a$key = $value" "$config_file"
		fi
	    done <<< "$nova_conf"
	    echo "nova configuration added to [nova] section"

	else
	    echo "[nova] section not found in $config_file"
	    echo "Adding the [nova] section and new connection string"

    	# If the [nova] section doesn't exist, append it to the config file
    	echo "[nova]" >> "$config_file"
    	
    	# Add the nova configuration below the [nova] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[nova\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in nova section"
	       sudo sed -i "/^\[nova\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file"
	   else
	       echo "Adding $key to nova section"
	       sudo sed -i "/^\[nova\]/a$key = $value" "$config_file"
	   fi
	   done <<< "$nova_conf"
	fi
	
	# edit oslo_concurrency section
	if grep -q "^\[oslo_concurrency\]" "$config_file"; then
	    echo "[oslo_concurrency] section found in $config_file"

	    # Add the api_server below the [glance] section
	    sudo sed -i "/^\[oslo_concurrency\]/a$oslo_conf" "$config_file"
	    echo "oslo_concurrency added to [oslo_concurrency] section"

	else
	    echo "[oslo_concurrency] section not found in $config_file"
	    echo "Adding the [oslo_concurrency] section and new connection string"

    	# If the [oslo_concurrency] section doesn't exist, append it to the config file
    	echo -e "\n[oslo_concurrency]\n$oslo_conf" | sudo tee -a "$config_file"
	fi	
else
    echo "$config_file not found. 
    exiting....."
    exit 1
fi

# configure the $config_file1. check that file was found or not
if [ -f "$config_file1" ]; then
    	echo "updating the $config_file1"
    	sudo cp $config_file1 $config_file1.bak
    	# Editing the [ml2] section
	if grep -q "^\[ml2\]" "$config_file1"; then
	    echo "[ml2] section found in $config_file1"

	    # Add the nova config below in the [nova] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[ml2\]" "$config_file1" | grep -q "^$key ="; then
		    echo "Updating $key in ml2 section"
		    sudo sed -i "/^\[ml2\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file1"
		else
		    echo "Adding $key to ml2 section"
		    sudo sed -i "/^\[ml2\]/a$key = $value" "$config_file1"
		fi
	    done <<< "$ml2_conf"
	    echo "nova configuration added to [ml2] section"

	else
	    echo "[ml2] section not found in $config_file1"
	    echo "Adding the [ml2] section and new connection string"

    	# If the [ml2] section doesn't exist, append it to the config file
    	echo "[ml2]" >> "$config_file1"
    	
    	# Add the ml2 below the [ml2] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[ml2\]" "$config_file" | grep -q "^$key ="; then
	       echo "Updating $key in ml2 section"
	       sudo sed -i "/^\[ml2\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file1"
	   else
	       echo "Adding $key to ml2 section"
	       sudo sed -i "/^\[ml2\]/a$key = $value" "$config_file1"
	   fi
	   done <<< "$ml2_conf"
	fi
	
	# edit ml2_type_flat section
	if grep -q "^\[ml2_type_flat\]" "$config_file1"; then
	    echo "[ml2_type_flat] section found in $config_file1"

	    # Add the ml2_type_flat below the [ml2_type_flat] section
	    sudo sed -i "/^\[ml2_type_flat\]/a$ml2_type_flat" "$config_file1"
	    echo "ml2_type_flat added to [ml2_type_flat] section"

	else
	    echo "[ml2_type_flat] section not found in $config_file1"
	    echo "Adding the [ml2_type_flat] section and new connection string"

    	# If the [ml2_type_flat] section doesn't exist, append it to the config file
    	echo -e "\n[ml2_type_flat]\n$ml2_type_flat" | sudo tee -a "$config_file1"
	fi
	
	# edit ml2_type_vxlan section
	if grep -q "^\[ml2_type_vxlan\]" "$config_file1"; then
	    echo "[ml2_type_vxlan] section found in $config_file1"

	    # Add the ml2_type_vxlan below the [ml2_type_vxlan] section
	    sudo sed -i "/^\[ml2_type_vxlan\]/a$ml2_type_vxlan" "$config_file1"
	    echo "ml2_type_vxlan added to [ml2_type_vxlan] section"

	else
	    echo "[ml2_type_vxlan] section not found in $config_file1"
	    echo "Adding the [ml2_type_vxlan] section and new connection string"

    	# If the [ml2_type_vxlan] section doesn't exist, append it to the config file
    	echo -e "\n[ml2_type_vxlan]\n$ml2_type_vxlan" | sudo tee -a "$config_file1"
	fi
else
    echo "$config_file1 not found. 
    exiting....."
    exit 1
fi	

# configure the $config_file2. check that file was found or not
if [ -f "$config_file2" ]; then
    	echo "updating the $config_file2"
    	sudo cp $config_file2 $config_file2.bak
    	
    	# Editing the [ovs] section
	if grep -q "^\[ovs\]" "$config_file2"; then
	    echo "[ovs] section found in $config_file2"

	    # Add the nova config below in the [ovs] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[ovs\]" "$config_file2" | grep -q "^$key ="; then
		    echo "Updating $key in ovs section"
		    sudo sed -i "/^\[ovs\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
		else
		    echo "Adding $key to ovs section"
		    sudo sed -i "/^\[ovs\]/a$key = $value" "$config_file2"
		fi
	    done <<< "$ovs"
	    echo "ovs configuration added to [ovs] section"

	else
	    echo "[ovs] section not found in $config_file2"
	    echo "Adding the [ovs] section and new connection string"

    	# If the [ovs] section doesn't exist, append it to the config file
    	echo "[ovs]" >> "$config_file2"
    	
    	# Add the ovs configuration below the [ovs] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[ovs\]" "$config_file2" | grep -q "^$key ="; then
	       echo "Updating $key in ovs section"
	       sudo sed -i "/^\[ovs\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
	   else
	       echo "Adding $key to ovs section"
	       sudo sed -i "/^\[ovs\]/a$key = $value" "$config_file2"
	   fi
	   done <<< "$ovs"
	fi
    	
    	# Editing the [agent] section
	if grep -q "^\[agent\]" "$config_file2"; then
	    echo "[agent] section found in $config_file2"

	    # Add the agent config below in the [agent] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[agent\]" "$config_file2" | grep -q "^$key ="; then
		    echo "Updating $key in agent section"
		    sudo sed -i "/^\[agent\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
		else
		    echo "Adding $key to agent section"
		    sudo sed -i "/^\[agent\]/a$key = $value" "$config_file2"
		fi
	    done <<< "$agent"
	    echo "agent configuration added to [agent] section"

	else
	    echo "[agent] section not found in $config_file2"
	    echo "Adding the [agent] section and new connection string"

    	# If the [agent] section doesn't exist, append it to the config file
    	echo "[agent]" >> "$config_file2"
    	
    	# Add the agent configuration below the [agent] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[agent\]" "$config_file2" | grep -q "^$key ="; then
	       echo "Updating $key in agent section"
	       sudo sed -i "/^\[agent\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
	   else
	       echo "Adding $key to agent section"
	       sudo sed -i "/^\[agent\]/a$key = $value" "$config_file2"
	   fi
	   done <<< "$agent "
	fi
	
	# Editing the [securitygroup] section
	if grep -q "^\[securitygroup\]" "$config_file2"; then
	    echo "[securitygroup] section found in $config_file2"

	    # Add the agent config below in the [agent] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[securitygroup\]" "$config_file2" | grep -q "^$key ="; then
		    echo "Updating $key in securitygroup section"
		    sudo sed -i "/^\[securitygroup\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
		else
		    echo "Adding $key to securitygroup section"
		    sudo sed -i "/^\[securitygroup\]/a$key = $value" "$config_file2"
		fi
	    done <<< "$securitygroup"
	    echo "securitygroup configuration added to [securitygroup] section"

	else
	    echo "[securitygroup] section not found in $config_file2"
	    echo "Adding the [securitygroup] section and new connection string"

    	# If the [securitygroup] section doesn't exist, append it to the config file
    	echo "[securitygroup]" >> "$config_file2"
    	
    	# Add the securitygroup configuration below the [securitygroup] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[securitygroup\]" "$config_file2" | grep -q "^$key ="; then
	       echo "Updating $key in securitygroup section"
	       sudo sed -i "/^\[securitygroup\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file2"
	   else
	       echo "Adding $key to securitygroup section"
	       sudo sed -i "/^\[securitygroup\]/a$key = $value" "$config_file2"
	   fi
	   done <<< "$securitygroup"
	fi
	
	sudo sysctl net.bridge.bridge-nf-call-iptables = 1
	sudo sysctl net.bridge.bridge-nf-call-ip6tables = 1
	sudo ovs-vsctl add-br br-ex
	sudo ovs-vsctl add-port br-ex enp0s8
	sudo ifconfig up br-ex
	sudo ip addr add 172.29.24.217/22 dev br-ex
	sudo ip addr flush enp0s8
	sudo ip link set br-ex
	sudo ip route add default via 172.29.27.254 dev br-ex proto dhcp metric 100
	
else
    echo "$config_file2 not found. 
    exiting....."
    exit 1
fi

# configure the $config_file3. check that file was found or not
if [ -f "$config_file3" ]; then
    	echo "updating the $config_file3"
    	sudo cp $config_file3 $config_file3.bak
    	
    	# edit DEFAULT section
	if grep -q "^\[DEFAULT\]" "$config_file3"; then
	    echo "[DEFAULT] section found in $config_file3"

	    # Add the DEFAULT below the [DEFAULT] section
	    sudo sed -i "/^\[DEFAULT\]/a$def1" "$config_file3"
	    echo "DEFAULts added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file3"
	    echo "Adding the [DEFAULT] section and new connection string"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo -e "\n[DEFAULT]\n$def1" | sudo tee -a "$config_file3"
	fi

else
    echo "$config_file3 not found. 
    exiting....."
    exit 1
fi

# configure the $config_file4. check that file was found or not
if [ -f "$config_file4" ]; then
    	echo "updating the $config_file4"
    	sudo cp $config_file4 $config_file4.bak
    	
    	# Editing the [DEFAULT] section
	if grep -q "^\[DEFAULT\]" "$config_file4"; then
	    echo "[DEFAULT] section found in $config_file4"

	    # Add the agent config below in the [DEFAULT] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[DEFAULT\]" "$config_file4" | grep -q "^$key ="; then
		    echo "Updating $key in DEFAULT section"
		    sudo sed -i "/^\[DEFAULT\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file4"
		else
		    echo "Adding $key to DEFAULT section"
		    sudo sed -i "/^\[DEFAULT\]/a$key = $value" "$config_file4"
		fi
	    done <<< "$def"
	    echo "DEFAULT configuration added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file4"
	    echo "Adding the [DEFAULT] section and new connection string"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo "[DEFAULT]" >> "$config_file4"
    	
    	# Add the securitygroup configuration below the [securitygroup] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[DEFAULT\]" "$config_file4" | grep -q "^$key ="; then
	       echo "Updating $key in DEFAULT section"
	       sudo sed -i "/^\[DEFAULT\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file4"
	   else
	       echo "Adding $key to DEFAULT section"
	       sudo sed -i "/^\[DEFAULT\]/a$key = $value" "$config_file4"
	   fi
	   done <<< "$def "
	fi

else
    echo "$config_file4 not found. 
    exiting....."
    exit 1
fi

# configure the $config_file5. check that file was found or not
if [ -f "$config_file5" ]; then
    	echo "updating the $config_file5"
    	sudo cp $config_file5 $config_file5.bak
    	
    	# Editing the [DEFAULT] section
	if grep -q "^\[DEFAULT\]" "$config_file5"; then
	    echo "[DEFAULT] section found in $config_file5"

	    # Add the agent config below in the [DEFAULT] section
	     while IFS= read -r line; do
		key=$(echo "$line" | cut -d'=' -f1 | xargs)
		value=$(echo "$line" | cut -d'=' -f2- | xargs)
		
		# Check if the key exists in the section, if not, add it
		if grep -A10 "^\[DEFAULT\]" "$config_file5" | grep -q "^$key ="; then
		    echo "Updating $key in DEFAULT section"
		    sudo sed -i "/^\[DEFAULT\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file5"
		else
		    echo "Adding $key to DEFAULT section"
		    sudo sed -i "/^\[DEFAULT\]/a$key = $value" "$config_file5"
		fi
	    done <<< "$def2"
	    echo "DEFAULT configuration added to [DEFAULT] section"

	else
	    echo "[DEFAULT] section not found in $config_file5"
	    echo "Adding the [DEFAULT] section and new connection string"

    	# If the [DEFAULT] section doesn't exist, append it to the config file
    	echo "[DEFAULT]" >> "$config_file5"
    	
    	# Add the securitygroup configuration below the [securitygroup] section
	while IFS= read -r line; do
	   key=$(echo "$line" | cut -d'=' -f1 | xargs)
	   value=$(echo "$line" | cut -d'=' -f2- | xargs)
	   # Check if the key exists in the section, if not, add it
	   if grep -A10 "^\[DEFAULT\]" "$config_file5" | grep -q "^$key ="; then
	       echo "Updating $key in DEFAULT section"
	       sudo sed -i "/^\[DEFAULT\]/,/^\[/ s|^$key =.*|$key = $value|" "$config_file5"
	   else
	       echo "Adding $key to DEFAULT section"
	       sudo sed -i "/^\[DEFAULT\]/a$key = $value" "$config_file5"
	   fi
	   done <<< "$def2"
	fi

else
    echo "$config_file5 not found. 
    exiting....."
    exit 1
fi

# Populate the database:
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# For both networking options:

service neutron-server restart
service neutron-openvswitch-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

#For networking option 2, also restart the layer-3 service:
service neutron-l3-agent restart
	




