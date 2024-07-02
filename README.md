# <center> Ansible-Kubernetes Repository 1.28.X </center>

<center>Automate the provisioning of a new bare-metal multi-node Kubernetes cluster with Ansible. Uses all the industry-standard tools for an enterprise-grade cluster.</center>

## Preview

Cluster HA K8s + ETCD

![image](https://i.imgur.com/lNfDM7S.png)

Cluster Single

![image](https://i.imgur.com/Wb8Otxx.png)


## Table of Contents

- [Stack](#stack) 
- [Requirements](#requirements) 
- [Prerequisites](#prerequisites)
- [Usage](#usage) 
- [Uninstall Cluster](#uninstall-cluster) 

## Stack

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

## Requirements

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

## Prerequisites

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

## Usage

1, Clone this Git repository to your local working station:
```bash
git clone git@git.paas.vn:datvm/ansible-k8s.git
```
2, Change directory to the root directory of the project
```bash
cd ansible-k8s
```
3, Edit the values of the default variables to your requirements
```bash
vi group_vars/all
```
4, Edit the Ansible inventory file to your requirements
```bash
vi inventory/hosts.ini
```
5, Validate host and user

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags checking-hosts
```

### For Cluster Single

Require Modify [Line](https://git.paas.vn/datvm/ansible-k8s/-/blob/master/group_vars/all?ref_type=heads#L30)

```bash
cluster_ha: true --> false
```

Run playbook

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags common,containerd,k8s,k8s-init,join-worker,cni-calico,ingress
```

If setup NFS

Modify variable: [whitelist](https://git.paas.vn/datvm/ansible-k8s/-/blob/master/group_vars/all?ref_type=heads#L99) and Run playbook

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags nfs,k8s-nfs
```

### For Cluster HA ETCD + K8s

Require Modify [Line](https://git.paas.vn/datvm/ansible-k8s/-/blob/master/group_vars/all?ref_type=heads#L30)

```bash
cluster_ha: false --> true
```

Run playbook

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags nfs,haproxy,keepalived,cfssl,gen-certs,sync-certs,common,containerd,k8s,etcd,k8s-init,join-master,join-worker,cni-calico,ingress,k8s-nfs
```

Gen Certs and Sync Certs if not exists certs for etcd and cluster: Not require

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml --tags gen-certs,sync-certs
```

## Check ETCD

Connect to any master 

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

## Check HAproxy

![haproxy](https://i.imgur.com/zcAY4gl.png)

## Uninstall Cluster

```bash
ansible-playbook -i hosts playbook.yml --tags uninstall-cluster
```

## Thanks for Reading!
- Donate: Visa Viettinbank: **103868801400**
