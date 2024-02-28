## Devploy Cluster K8s Ez

Change Info file hosts

> Require ssh with role **`root`**

- ansible_host=`<host_IP>`
- For master set: `primary`=**true**
- For worker set: `secondary`=**true**
- groups for master: `[master]`
- groups for worker: `[worker]`
- groups for cluster: `[cluster]`

After setup OK, checking!!!

```bash
ansible -i hosts all -m ping
```

## How's it work!

```bash
ansible-playbook -i hosts playbook.yml
```
