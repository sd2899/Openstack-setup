#! /bin/bash

#---- Neutron Installation----------
# install the neutron packages.
sudo apt install neutron-openvswitch-agent -y

# Edit the /etc/neutron/neutron.conf file and complete the following actions. In the [database] section, configure database access:

config_file="/etc/neutron/neutron.conf"
def_trans="transport_url = rabbit://openstack:R123@controller"
oslo_conf="lock_path = /var/lib/neutron/tmp"

config_file2="/etc/neutron/plugins/ml2/openvswitch_agent.ini"
ovs="bridge_mappings = provider:br-ex
local_ip = 192.168.56.101"
agent="tunnel_types = vxlan
l2_population = true"
securitygroup="enable_security_group = true
firewall_driver = openvswitch"

if [ -f "$config_file" ]; then
    	echo "updating the $config_file"
    	sudo cp $config_file $config_file.bak
        	
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
	sudo ifconfig br-ex up
	sudo ip addr flush dev enp0s8
	sudo ip addr add 172.29.24.161/22 dev br-ex
	sudo ip route add default via 172.29.27.254 dev br-ex proto dhcp metric 100
	sudo ip link set br-ex 
	echo "conf done!!"
	
else
    echo "$config_file2 not found. 
    exiting....."
    exit 1
fi

service neutron-openvswitch-agent restart	




