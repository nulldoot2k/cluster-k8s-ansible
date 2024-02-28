## Devploy Cluster K8s Ez

Change Info file hosts

> Require ssh with role **`root`**

- ansible_host=`<host_IP>`
- For master set: `primary`=**true**
- For worker set: `secondary`=**true**
- groups for master: `[master]`
- groups for worker: `[worker]`
- groups for cluster: `[cluster]`

Install lib

```bash
pip install kubernetes
```

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

## StorageClass

```bash
git clone https://github.com/nulldoot2k/NFS-Volume-K8S.git
kubectl apply -f NFS-Volume-K8s/
```

## Deploy Nginxx

```bash
kubectl create deployment nginx --image=nginx
```

Exposing Your Nginx Service to Public Network

Kubernetes offers several options when exposing your service based on a feature called Kubernetes Service-types and they are:

- ClusterIP – This Service-type generally exposes the service on an internal IP, reachable only within the cluster, and possibly only within the cluster-nodes.
- NodePort – This is the most basic option of exposing your service to be accessible outside of your cluster, on a specific port (called the NodePort) on every node in the cluster. We will illustrate this option shortly.
- LoadBalancer – This option leverages on external Load-Balancing services offered by various providers to allow access to your service. This is a more reliable option when thinking about high availability for your service, and has more feature beyond default access.
- ExternalName – This service does traffic redirect to services outside of the cluster. As such the service is thus mapped to a DNS name that could be hosted out of your cluster. It is important to note that this does not use proxying.

The default Service-type is ClusterIP.

```bash
kubectl create service nodeport nginx --tcp=80:80
```

Check service

```bash
kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
nginx        NodePort    10.101.230.145   <none>        80:31150/TCP   5m54s
```

## Checking

```bash
curl $HOSTNAME:31150
--> results <--
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
