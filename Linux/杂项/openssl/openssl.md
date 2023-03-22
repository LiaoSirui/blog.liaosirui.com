## 快速生成自签证书

生成证书

```bash
openssl req -x509 -nodes -days 700 -newkey rsa:2048 -keyout tls.key -out  ca.crt -subj "/CN=poc.com"
```

创建 kubernetes 证书

```bash
kubectl -n istio-system create secret tls istio-ingressgateway-certs --key tls.key --cert ca.crt --dry-run -o yaml | kubectl apply  -f -
```

## 生成带 subjectAltName 的证书

```bash
domainName=domain.com
consoleNS=ns
k8sSecretName=sso-x509-https-secret

# 支持 addext 参数需要将 OpenSSL 更新到 1.1.1d
openssl req -x509 -nodes -days 700 -newkey rsa:2048 -keyout ${consoleNS}-tls.key -out ${consoleNS}-ca.crt -subj "/CN=${domainName}" -addext "subjectAltName = DNS:${domainName}"

kubectl -n $consoleNS  create secret tls ${k8sSecretName}  --key ${consoleNS}-tls.key --cert ${consoleNS}-ca.crt --dry-run -o yaml |kubectl apply  -f -

```

