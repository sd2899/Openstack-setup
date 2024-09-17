#!/bin/bash

# Add the openstack user and Replace RABBIT_PASS with a suitable password.
rabbitmqctl add_user openstack Ra2486

# Permit configuration, write, and read access for the openstack user:
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# create a file to store the admin credentials
cat <<EOF > /home/demo/admin-openrc
export OS_USERNAME=admin
export OS_PASSWORD=Admin123
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

# Run the script to get the admin cli authentication 
chmod +x admin-openrc
. admin-openrc

# Create the Glance User and assign the admin role
openstack user create --domain default --password "g123" glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
# Create Glance endpoints
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292


# Create the Placement User and assign the admin role
openstack user create --domain default --password "p123" placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
# Create placement endpoints
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778


# Create the Nova User and assign the admin role
openstack user create --domain default --password "no123" prompt nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
# Create the Compute API service endpoints
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1


# Create the Neutron User and assign the admin role
openstack user create --domain default --password "ne123" prompt neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
# Create the Networking service API endpoints
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696


# Create a cinder user and assign the admin role
openstack user create --domain default --password "c123" prompt cinder
openstack role add --project service --user cinder admin
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
# Create the Block Storage service API endpoints
openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s


# create Swift user and assign the admin role
openstack user create --domain default --password "s123" prompt swift
openstack role add --project service --user swift admin
openstack service create --name swift --description "OpenStack Object Storage" object-store
#Create the Object Storage service API endpoints:
openstack endpoint create --region RegionOne object-store public http://controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne object-store internal http://controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne object-store admin http://controller:8080/v1


# Create Barbican User and assign the admin role
openstack user create --domain default --password "b123" prompt barbican
openstack role add --project service --user barbican admin
openstack role create creator
openstack role add --project service --user barbican creator
openstack service create --name barbican --description "Key Manager" key-manager

#Create the Key Manager service API endpoints:
openstack endpoint create --region RegionOne key-manager public http://controller:9311
openstack endpoint create --region RegionOne key-manager internal http://controller:9311
openstack endpoint create --region RegionOne key-manager admin http://controller:9311

