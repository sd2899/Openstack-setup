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

Unable to execute ['ovs-ofctl', 'add-flows', '-O', 'OpenFlow10', 'br-int', '-']. Exception: Exit code: 1; Cmd: ['ovs-ofctl', 'add-flows', '-O', 'OpenFlow10', 'br-int', '-']; Stdin: hard_timeout=0,idle_timeout=0,priority=0,table=71,cookie=4841432465141476094,actions=drop; Stdout: ; Stderr: ovs-ofctl: /var/run/openvswitch/br-int.mgmt: failed to open socket (Permission denied)


 [None req-1018b209-3993-4cc4-88a4-2bec13cb17f3 - - - - - -] Synchronizing state complete
2024-10-04 12:45:19.560 35196 INFO neutron.agent.dhcp.agent [None req-1018b209-3993-4cc4-88a4-2bec13cb17f3 - - - - - -] Synchronizing state
2024-10-04 12:45:19.574 35196 INFO neutron.agent.dhcp.agent [None req-e5b99478-d68d-4224-9b41-510af1c0d3d5 - - - - - -] All active networks have been fetched through RPC.
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent [None req-608473be-4c32-49ef-b740-e26cf84d6f9a - - - - - -] Unable to disable dhcp for 421fc95a-791f-4a26-890d-41572e095e4a.: PermissionError: [Errno 13] Permission denied
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent Traceback (most recent call last):
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/dhcp/agent.py", line 270, in _call_driver
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent     rv = getattr(driver, action)(**action_kwargs)
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/dhcp.py", line 375, in disable
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent     self._destroy_namespace_and_port()
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/dhcp.py", line 389, in _destroy_namespace_and_port
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent     ip_lib.delete_network_namespace(self.network.namespace)
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/ip_lib.py", line 963, in delete_network_namespace
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent     privileged.remove_netns(namespace, **kwargs)
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/oslo_privsep/priv_context.py", line 271, in _wrap
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent     return self.channel.remote_call(name, args, kwargs,
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/oslo_privsep/daemon.py", line 215, in remote_call
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent     raise exc_type(*result[2])
2024-10-04 12:45:19.583 35196 ERROR neutron.agent.dhcp.agent PermissionError: [Errno 13] Permission denied


 [None req-e630ade8-5546-466f-89a1-7d11da81826d - - - - - -] Error during L3NATAgentWithStateReport.periodic_sync_routers_task: PermissionError: [Errno 13] Permission denied
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task Traceback (most recent call last):
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task   File "/usr/lib/python3/dist-packages/oslo_service/periodic_task.py", line 216, in run_periodic_tasks
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task     task(self, context)
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task   File "/usr/lib/python3/dist-packages/neutron/agent/l3/agent.py", line 890, in periodic_sync_routers_task
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task     with self.namespaces_manager as ns_manager:
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task   File "/usr/lib/python3/dist-packages/neutron/agent/l3/namespace_manager.py", line 71, in __enter__
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task     self._all_namespaces = self.list_all()
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task   File "/usr/lib/python3/dist-packages/neutron/agent/l3/namespace_manager.py", line 117, in list_all
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task     namespaces = ip_lib.list_network_namespaces()
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task   File "/usr/lib/python3/dist-packages/neutron/agent/linux/ip_lib.py", line 972, in list_network_namespaces
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task     return privileged.list_netns(**kwargs)
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task   File "/usr/lib/python3/dist-packages/oslo_privsep/priv_context.py", line 271, in _wrap
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task     return self.channel.remote_call(name, args, kwargs,
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task   File "/usr/lib/python3/dist-packages/oslo_privsep/daemon.py", line 215, in remote_call
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task     raise exc_type(*result[2])
2024-10-04 12:53:23.759 36745 ERROR oslo_service.periodic_task PermissionError: [Errno 13] Permission denied




ERROR neutron.agent.dhcp.agent [None req-8800c3fc-c029-4ca3-bebe-9c7fc00f1ea6 - - - - - -] Unable to disable dhcp for b147ba7d-5756-4d06-88a8-10a7c4593ab1.: PermissionError: [Errno 13] Permission denied
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent Traceback (most recent call last):
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/dhcp/agent.py", line 270, in _call_driver
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent     rv = getattr(driver, action)(**action_kwargs)
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/dhcp.py", line 375, in disable
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent     self._destroy_namespace_and_port()
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/dhcp.py", line 389, in _destroy_namespace_and_port
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent     ip_lib.delete_network_namespace(self.network.namespace)
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/neutron/agent/linux/ip_lib.py", line 963, in delete_network_namespace
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent     privileged.remove_netns(namespace, **kwargs)
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/oslo_privsep/priv_context.py", line 271, in _wrap
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent     return self.channel.remote_call(name, args, kwargs,
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent   File "/usr/lib/python3/dist-packages/oslo_privsep/daemon.py", line 215, in remote_call
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent     raise exc_type(*result[2])
2024-10-04 17:00:07.629 71215 ERROR neutron.agent.dhcp.agent PermissionError: [Errno 13] Permission denied
