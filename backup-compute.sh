#!/bin/bash
backup_dir="/part2/Openstack-backup/c3i-servercompute"
log_dir="/part2/Openstack-backup/c3i-servercompute/log"
lib_dir="/part2/Openstack-backup/c3i-servercompute/lib"
conf_dir="/part2/Openstack-backup/c3i-servercompute/conf"
pass="284961"

# create the backup of the configuration directory
sshpass -p "$pass" scp -r /etc/chrony k8@172.29.233.32:$conf_dir 
sshpass -p "$pass" scp -r /etc/nova k8@172.29.233.32:$conf_dir
sshpass -p "$pass" scp -r /etc/neutron k8@172.29.233.32:$conf_dir
sshpass -p "$pass" scp -r /etc/cinder k8@172.29.233.32:$conf_dir

#backup the lib directory files
sshpass -p "$pass" scp -r /var/lib/chrony k8@172.29.233.32:$lib_dir
#scp -r /var/lib/nova $lib_dir
sshpass -p "$pass" scp -r /var/lib/neutron k8@172.29.233.32:$lib_dir
sshpass -p "$pass" scp -r /var/lib/cinder k8@172.29.233.32:$lib_dir

#backup the log directory files
sshpass -p "$pass" scp -r /var/log/chrony k8@172.29.233.32:$log_dir
sshpass -p "$pass" scp -r /var/log/nova k8@172.29.233.32:$log_dir
sshpass -p "$pass" scp -r /var/log/neutron k8@172.29.233.32:$log_dir
sshpass -p "$pass" scp -r /var/log/openvswitch k8@172.29.233.32:$log_dir
sshpass -p "$pass" scp -r /var/log/cinder k8@172.29.233.32:$log_dir

# Delete backups older than 7 days
find $backup_dir -ctime +7 -type f -delete

