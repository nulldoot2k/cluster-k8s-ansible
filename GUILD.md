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
