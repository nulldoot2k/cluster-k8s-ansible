## Devploy Cluster K8s Ez

Change Info file hosts

> Require ssh with role **`root`**

- ansible_host=`<host_IP>`
- For master set: `primary`=**true**
- For worker set: `secondary`=**true**
- groups for master: `[master]`
- groups for worker: `[worker]`
- groups for cluster: `[cluster]`

Change Info NFS storage

- firewall_allow_ips: Allows IP or Range to Client connect to Server | Require
- nfs_fstype is the type of filesystem to create on the disk. Checking with **`df -T /`**
- nfs_export is the path to exported filesystem mountpoint on the NFS server.
- nfs_export_subnet is the host or network to which the export is shared. Optional, "*".
- nfs_export_options are the options to apply to the export.
- nfs_client_mnt_point is the path to the mountpoint on the NFS clients.
- nfs_client_mnt_options allows passing mount options to the NFS client.
- nfs_server is the IP address or hostname of the NFS server.
- nfs_enable: a mapping with keys server and client - values are bools determining the role of the host.

After setup OK, checking!!!

```bash
ansible -i hosts all -m ping
```

## How's it work!

```bash
ansible-playbook -i hosts playbook.yml
```

## Uninstall Cluster

```bash
ansible-playbook -i hosts playbook.yml --tags uninstall-cluster
```
