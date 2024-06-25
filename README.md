# <center> Ansible-Kubernetes Repository 1.28.X </center>

<center>Automate the provisioning of a new bare-metal multi-node Kubernetes cluster with Ansible. Uses all the industry-standard tools for an enterprise-grade cluster.</center>

![image](https://github.com/nulldoot2k/cluster-k8s-ansible/assets/83489434/2626d953-bd21-4755-9e58-d51ea1124b6f)

## Table of Contents

- [Stack](#stack) 
- [Requirements](#requirements) 
- [Prerequisites](#prerequisites)
- [Usage](#usage) 
- [Test Nginx](#test-nginx) 
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
git clone https://github.com/nulldoot2k/cluster-k8s-ansible.git
```
2, Change directory to the root directory of the project
```bash
cd cluster-k8s-ansible
```
3, Edit the values of the default variables to your requirements
```bash
vi group_vars/all
```
4, Edit the Ansible inventory file to your requirements
```bash
vi inventory/hosts.ini
```
5, Run the Ansible Playbook:
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

## Test Nginx

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

## ETCD

```bash
etcdctl member list -w=table
etcdctl endpoint status -w=table --cluster
etcdctl endpoint health -w=table --cluster
```

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.pem \
  --cert=/etc/kubernetes/pki/etcd/etcd.pem \
  --key=/etc/kubernetes/pki/etcd/etcd-key.pem \
  member list -w=table
```

## Kubernetes

Gen token join master first

```bash
kubeadm token generate
```

Kubeadm create token

```bash
kubeadm token create
```

Kubeadm create hash token

```bash
openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1
```

Kubeadm create token command join

```bash
kubeadm token create --print-join-command
```

Kubeadm create certs

```bash
kubeadm init phase upload-certs --upload-certs --config kubeadm-config.yaml
```

Get hash token cluster

```bash
curl -ks https://nginx:6443/cacerts | sha256sum
```

## Uninstall Cluster

```bash
ansible-playbook -i hosts playbook.yml --tags uninstall-cluster
```

## Thanks for Reading!
- Donate: Visa Viettinbank: **103868801400**

## Reference

- https://www.haproxy.com/blog/exploring-the-haproxy-stats-page
