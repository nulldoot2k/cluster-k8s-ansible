# <center> Ansible-Kubernetes Centralization 1.28.X </center>

<center>Automate the provisioning of a new bare-metal multi-node Kubernetes cluster with Ansible. Uses all the industry-standard tools for an enterprise-grade cluster.</center>

## 0. Preview

Cluster HA K8s + ETCD

![cluster](https://i.imgur.com/lNfDM7S.png)

Cluster Single

![single](https://i.imgur.com/Wb8Otxx.png)


## 1. Table of Contents

- [Stack](#stack) 
- [Requirements](#requirements) 
- [Prerequisites](#prerequisites)
- [Usage](#usage) 
- [Uninstall Cluster](#uninstall-cluster) 

## 2. Stack

- Ansible: An open source IT automation engine.
- ContainerD: An industry-standard container runtime.
- Kubernetes: An open-source system for automating deployment, scaling, and management of containerized applications.
- Flannel: An open source networking and network security solution for containers (CNI).
- Calico An open source networking and network security solution same Flannel.
- MetalLB: A bare metal load-balancer for Kubernetes.
- Nginx: An Ingress controller.
- Etcd v3.3.4
- Helm v2.9.1
- Nginx-ingress-controller v0.14.0
- Prometheus v2.3.2

## 3. Requirements

1. The cluster requires at least 4 servers, bare-metal or virtual, with Ubuntu 20.04 LTS X installed. 
2. All servers are in the same network and able to see each other.
3. An Ansible Server has to be setup in the same network with Ansible v2.4 (or later) and python-netaddr installed.
4. Internet access is available for all servers to download software binaries.
5. Password-less SSH has to be enabled for the root user on all servers except the Ansible Server
6. Root user remote login has to be enabled on all servers except the Ansible Server.

Make sure that your SSH key is already installed on the machines by running the following command:

```sh
ssh-copy-id <The remote username>@<The IPv4 address of the remote machine>
```

- VirtualBox: This tutorial leverages the [VirtualBox](https://www.virtualbox.org/) to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes cluster from the ground up. Click to [download and install VirtualBox](https://www.virtualbox.org/wiki/Downloads).

Use Vagrant to manage virtual machine resources, and use the vagrant-hosts plug-in to manage the **/etc/hosts** file in the virtual machine.

```bash
vagrant plugin install vagrant-hosts
```

output

```bash
Installing the 'vagrant-hosts' plugin. This can take a few minutes...
Fetching rake-13.2.1.gem
Removing rake
Successfully uninstalled rake-13.2.1
```

## 4. Quick Start

1, Edit the values of the default variables to your requirements
```bash
vi group_vars/all
```
2, Edit the Ansible inventory file to your requirements
```bash
vi inventory/hosts.ini
```
3, Validate host and user

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags checking-hosts
```

## 5. Run Ansible Playbooks

Require Modify [Line](https://github.com/nulldoot2k/cluster-k8s-ansible/blob/main/group_vars/all#L30)

```bash
cluster_ha: true --> false
# describe
True: Deploy with Cluster External
False: Deploy with Cluster Internal
```

When False: Run ansible playbook for cluster internal, setup nfs volume and container with k8s and setup component.

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags nfs,common,containerd,k8s,k8s-init,join-worker,cni-calico,ingress,k8s-nfs
```

When True: Run ansible playbook for cluster external, setup vip HA, ETCD and nfs volume and container with k8s and setup component.

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags nfs,haproxy,keepalived,common,containerd,k8s,k8s-init,join-worker,cni-calico,ingress,k8s-nfs
```

## 6. Deploy step by step

### 6.1 Setup VIP

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags haproxy,keepalived
```

### 6.2 Setup Certs

Gen Certs and Sync Certs if not exists certs for etcd and cluster

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags gen-certs,sync-certs
```

### 6.3 Setup ETCD

Require sync certs before run ansible here

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags etcd
```

> Note that: IF error certs, let's remove certs old and sync certs new and restart systemd

### 6.4 Init Cluster

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags k8s-init
```

### 6.5 Join Master Node

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags join-master
```

### 6.6 Join Worker Node

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags join-worker
```

### 6.7 Setup CNI

Choose type cni for cluster

```bash
cni-calico: ansible-playbook -i inventory/hosts.ini playbook.yml --tags cni-calico
cni-flannel: ansible-playbook -i inventory/hosts.ini playbook.yml --tags cni-flannel
cni-cilium: ansible-playbook -i inventory/hosts.ini playbook.yml --tags cni-cilium
```

### 6.8 Setup Ingress

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags ingress
```

### 6.9 Setup NFS

Modify variable: [whitelist](https://github.com/nulldoot2k/cluster-k8s-ansible/blob/main/group_vars/all#L99) and Run playbook

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags nfs,k8s-nfs
```

## 7. Result Output Ansible

### 7.1 Dashboard HAproxy

- Login Chrome: ***:9000/haproxy_stats**
- Hint: **[username/password]** 

![haproxy](https://i.imgur.com/zcAY4gl.png)

### 7.2 Check ETCD

Connect to any master and try output via command 

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.pem \
  --cert=/etc/kubernetes/pki/etcd/etcd.pem \
  --key=/etc/kubernetes/pki/etcd/etcd-key.pem \
  member list -w=table
```
```bash
... member list -w=table
... endpoint status -w=table --cluster
... endpoint health -w=table --cluster
```

### 7.3 Check Health Kubernetes

Copy file config master to local machine and exports

```bash
export KUBECONFIG=/path.../config
```

Check Node and Pods

```bash
kubectl get node
NAME      STATUS   ROLES           AGE     VERSION
master1   Ready    control-plane   7d23h   v1.28.10
master2   Ready    control-plane   7d23h   v1.28.10
master3   Ready    control-plane   7d23h   v1.28.10
worker1   Ready    <none>          7d23h   v1.28.10
worker2   Ready    <none>          7d23h   v1.28.10
worker3   Ready    <none>          7d23h   v1.28.10
```

### 7.4 Check Ingress Nginx

Kubernetes offers several options when exposing your service based on a feature called Kubernetes Service-types and they are:

- ClusterIP – This Service-type generally exposes the service on an internal IP, reachable only within the cluster, and possibly only within the cluster-nodes.
- NodePort – This is the most basic option of exposing your service to be accessible outside of your cluster, on a specific port (called the NodePort) on every node in the cluster. We will illustrate this option shortly.
- LoadBalancer – This option leverages on external Load-Balancing services offered by various providers to allow access to your service. This is a more reliable option when thinking about high availability for your service, and has more feature beyond default access.
- ExternalName – This service does traffic redirect to services outside of the cluster. As such the service is thus mapped to a DNS name that could be hosted out of your cluster. It is important to note that this does not use proxying.

1, Deploy Image Nginxx

```bash
kubectl create deployment nginx --image=nginx
```

2, Exposing Your Nginx Service to Public Network

```bash
kubectl create service loadbalancer nginx --tcp=80:80
```

3, Check service

```bash
kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
nginx        LoadBalancer   10.96.163.143   192.168.101.1   80:31451/TCP   106s
```

4, Checking result

```bash
curl 192.168.101.1
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

### 7.5 Show mount NFS

Connect to NFS Server

```bash
showmount -e

===> result success
/mnt/nfs/promdata Range_IP_Worker
```

Connect to NFS Client

```bash
sudo mount | grep promdata

===> results
<IP_Server>:/mnt/nfs/promdata on /mnt/nfs/promdata type nfs4 (rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=Client_IP,local_lock=none,addr=Server_IP)
```

## 8. Monitoring

```bash
git submodule update --init --recursive
```

## Uninstall Cluster

```bash
ansible-playbook -i hosts playbook.yml --tags uninstall-cluster
```

## Thanks for Reading!
- Donate: Visa Viettinbank: **103868801400**
