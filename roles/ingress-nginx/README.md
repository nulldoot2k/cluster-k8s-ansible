## Validate the NGINX Ingress Controller

```bash
> kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx
NAMESPACE       NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx   ingress-nginx-admission-create-wb4rm        0/1     Completed   0          33s
ingress-nginx   ingress-nginx-admission-patch-dqsnv         0/1     Completed   0          33s
ingress-nginx   ingress-nginx-controller-74fd5565fb-lw6nq   1/1     Running     0          33s

> kubectl get services ingress-nginx-controller --namespace=ingress-nginx
NAME                       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   NodePort   10.244.200.10   <none>        80:30422/TCP,443:31811/TCP   33s
```

Case Issue: Removing the Nginx Ingress Webhook

```bash
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```
