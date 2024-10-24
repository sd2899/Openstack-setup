#!/bin/bash
backup_dir="/srv/node/sdc/backup-openstack/"
filename="${backup_dir}/mysql-`hostname`-`eval date +%Y%m%d`.sql.gz"
# Dump the entire MySQL database
/usr/bin/mysqldump --opt --all-databases | gzip > $filename

# copy the all the directory to create the backup
cp -r /etc/chrony /srv/node/sdc/backup-openstack/
cp -r /etc/memcached.conf /srv/node/sdc/backup-openstack/
cp -r /etc/mysql /srv/node/sdc/backup-openstack/
cp -r /etc/default/etcd /srv/node/sdc/backup-openstack/
cp -r /etc/nova /srv/node/sdc/backup-openstack/
cp -r /etc/keystone /srv/node/sdc/backup-openstack/
cp -r /etc/glance /srv/node/sdc/backup-openstack/
cp -r /etc/placement /srv/node/sdc/backup-openstack/
cp -r /etc/neutron /srv/node/sdc/backup-openstack/
cp -r /etc/cinder /srv/node/sdc/backup-openstack/
cp -r /etc/swift /srv/node/sdc/backup-openstack/
cp -r /etc/openstack-dashboard /srv/node/sdc/backup-openstack/

#backup the lib directory files
cp -r /var/lib/chrony /srv/node/sdc/backup-openstack/lib
cp -r /var/lib/nova /srv/node/sdc/backup-openstack/lib
cp -r /var/lib/keystone /srv/node/sdc/backup-openstack/lib
cp -r /var/lib/glance /srv/node/sdc/backup-openstack/lib
cp -r /var/lib/placement /srv/node/sdc/backup-openstack/lib
cp -r /var/lib/neutron /srv/node/sdc/backup-openstack/lib
cp -r /var/lib/cinder /srv/node/sdc/backup-openstack/lib
cp -r /var/lib/swift /srv/node/sdc/backup-openstack/lib


#backup the lib directory files
cp -r /var/log/chrony /srv/node/sdc/backup-openstack/log
cp -r /var/log/mysql /srv/node/sdc/backup-openstack/log
cp -r /var/log/rabbitmq /srv/node/sdc/backup-openstack/log
cp -r /var/log/nova /srv/node/sdc/backup-openstack/log
cp -r /var/log/keystone /srv/node/sdc/backup-openstack/log
cp -r /var/log/glance /srv/node/sdc/backup-openstack/log
cp -r /var/log/placement /srv/node/sdc/backup-openstack/log
cp -r /var/log/neutron /srv/node/sdc/backup-openstack/log
cp -r /var/log/openvswitch /srv/node/sdc/backup-openstack/log
cp -r /var/log/cinder /srv/node/sdc/backup-openstack/log
cp -r /var/log/swift /srv/node/sdc/backup-openstack/log


# Delete backups older than 7 days
find $backup_dir -ctime +7 -type f -delete
