sudo apt-get update
sudo apt install chrony
sudo apt install mariadb-server python3-pymysql
sudo apt install rabbitmq-server
sudo apt install memcached python3-memcache
sudo apt install etcd
sudo add-apt-repository cloud-archive:bobcat
sudo apt install python3-openstackclient
sudo apt install glance
sudo apt install placement-api
sudo apt install nova-api nova-conductor nova-novncproxy nova-scheduler
sudo apt install neutron-server neutron-plugin-ml2 \
  neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent
sudo apt install cinder-api cinder-scheduler
sudo apt-get install swift swift-proxy python3-swiftclient \
  python3-keystoneclient python3-keystonemiddleware \
  memcached
sudo apt-get install barbican-api barbican-keystone-listener barbican-worker  

