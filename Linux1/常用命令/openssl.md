## 快速生成自签证书

生成证书

```bash
openssl req -x509 -nodes -days 700 -newkey rsa:2048 -keyout tls.key -out  ca.crt -subj "/CN=poc.com"
```

创建 kubernetes 证书

```bash
kubectl -n istio-system create secret tls istio-ingressgateway-certs --key tls.key --cert ca.crt --dry-run -o yaml | kubectl apply  -f -
```

