## Kubernetes Create token and cert join cluster

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

