# <center> Ansible-Kubernetes Repository </center>

<center>Automate the provisioning of a new bare-metal multi-node Kubernetes cluster with Ansible. Uses all the industry-standard tools for an enterprise-grade cluster.</center>

## Stack

- Ansible: An open source IT automation engine.
- ContainerD: An industry-standard container runtime.
- Kubernetes: An open-source system for automating deployment, scaling, and management of containerized applications.
- Plannel: An open source networking and network security solution for containers (CNI).
- MetalLB: A bare metal load-balancer for Kubernetes.
- Nginx: An Ingress controller.

## Requirements

1. A Linux machine with a superuser privileges and pre-installed Ansible.
2. Ubuntu machines that are intended to become part of the new Kubernetes cluster. 

Make sure that your SSH key is already installed on the machines by running the following command:

```sh
ssh-copy-id <The remote username>@<The IPv4 address of the remote machine>
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
vi defaults/main.yaml
```
4, Edit the Ansible inventory file to your requirements
```bash
vi inventory/hosts.ini
```
5, Run the Ansible Playbook:
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

## Uninstall Cluster

```bash
ansible-playbook -i hosts playbook.yml --tags uninstall-cluster
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
kubectl create service loadbalancer nginx --tcp=80:80
```

Check service

```bash
kubectl get svc
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
nginx        LoadBalancer   10.96.163.143   192.168.101.1   80:31451/TCP   106s
```

## Checking

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
