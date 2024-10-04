# Openstack-setup
for horizon error set compress_enable = false
nano /usr/share/openstack-dashboard/openstack-dashboard/settings.py
COMPRESS_ENABLE = False

INFO oslo.privsep.daemon [None req-38e54b72-abb0-4cc0-95d4-71fc14020c45 - - - - - -] Spawned new privsep daemon via rootwrap
2024-10-04 12:00:57.248 31232 INFO oslo.privsep.daemon [-] privsep daemon starting
2024-10-04 12:00:57.250 31232 INFO oslo.privsep.daemon [-] privsep process running with uid/gid: 0/0
2024-10-04 12:00:57.251 31232 INFO oslo.privsep.daemon [-] privsep process running with capabilities (eff/prm/inh): CAP_SYS_ADMIN/CAP_SYS_ADMIN/none
2024-10-04 12:00:57.251 31232 INFO oslo.privsep.daemon [-] privsep daemon running as pid 31232
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent [None req-38e54b72-abb0-4cc0-95d4-71fc14020c45 - - - - - -] Unable to disable dhcp for 421fc95a-791f-4a26-890d-41572e095e4a.: PermissionError: [Errno 13] Permission denied
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent Traceback (most recent call last):
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/dhcp/agent.py", line 270, in _call_driver
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent     rv = getattr(driver, action)(**action_kwargs)
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/dhcp.py", line 375, in disable
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent     self._destroy_namespace_and_port()
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/dhcp.py", line 389, in _destroy_namespace_and_port
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent     ip_lib.delete_network_namespace(self.network.namespace)
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/ip_lib.py", line 963, in delete_network_namespace
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent     privileged.remove_netns(namespace, **kwargs)
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/oslo_privsep/priv_context.py", line 271, in _wrap
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent     return self.channel.remote_call(name, args, kwargs,
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/oslo_privsep/daemon.py", line 215, in remote_call
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent     raise exc_type(*result[2])
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent PermissionError: [Errno 13] Permission denied
2024-10-04 12:00:57.585 31182 ERROR neutron.agent.dhcp.agent 
2024-10-04 12:00:57.596 31182 ERROR neutron.agent.dhcp.agent [None req-c7eee30e-9338-4999-b8dd-9130367c197b - - - - - -] Unable to disable dhcp for be277f56-4c67-4dc7-82e9-f1cd1a12cfbf.: PermissionError: [Errno 13] Permission denied

