官方文档：

- 使用 helm 安装 cert-manager：<https://cert-manager.io/docs/installation/helm/>

## 使用 Helm 安装

添加仓库

```bash
helm repo add jetstack https://charts.jetstack.io
```

更新仓库

```bash
helm repo update
```

查看最新的版本

```bash
> helm search repo jetstack                                         

NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                                       
jetstack/cert-manager                   v1.11.0         v1.11.0         A Helm chart for cert-manager                     
jetstack/cert-manager-approver-policy   v0.6.1          v0.6.1          A Helm chart for cert-manager-approver-policy     
jetstack/cert-manager-csi-driver        v0.5.0          v0.5.0          A Helm chart for cert-manager-csi-driver          
jetstack/cert-manager-csi-driver-spiffe v0.2.2          v0.2.0          A Helm chart for cert-manager-csi-driver-spiffe   
jetstack/cert-manager-google-cas-issuer v0.6.2          v0.6.2          A Helm chart for jetstack/google-cas-issuer       
jetstack/cert-manager-istio-csr         v0.5.0          v0.5.0          istio-csr enables the use of cert-manager for i...
jetstack/cert-manager-trust             v0.2.0          v0.2.0          A Helm chart for cert-manager-trust               
jetstack/trust-manager                  v0.4.0          v0.4.0          trust-manager is the easiest way to manage TLS ...
```

下载 helm chart

```bash
helm pull jetstack/cert-manager --version v1.11.0

# 下载并解压
helm pull jetstack/cert-manager --version v1.11.0 --untar
```

使用如下的 values.yaml

```bash
installCRDs: true

tolerations:
  - operator: "Exists"

webhook:
  tolerations:
    - operator: "Exists"

cainjector:
  tolerations:
    - operator: "Exists"

startupapicheck:
  tolerations:
    - operator: "Exists"

prometheus:
  enabled: false

```

crd 的 Manifest：<https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml>

安装 cert-manger

```bash
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.11.0 \
  -f ./values.yaml
```

## 使用 manifests 部署

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-5d495db6fc-6rtxx              1/1     Running   0          9m56s
cert-manager-cainjector-5f9c9d977f-bxchd   1/1     Running   0          9m56s
cert-manager-webhook-57bd45f9c-89q87       1/1     Running   0          9m56s

```

## cmctl

使用 cmctl 命令行工具检查 cert-manager 是否正常

```bash
cmctl check api
```

## 安装后检查

安装完成后，Cert-manager 将自动创建 CRD（Custom Resource Definitions）和相关的资源，如证书、密钥

检查 cert-manager 的`webhook`是否正常

```bash
cat <<EOF > 02-test-resources.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-cert
  namespace: cert-manager-test
spec:
  dnsNames:
    - example.com
  secretName: selfsigned-cert-tls
  issuerRef:
    name: test-selfsigned
EOF

kubectl apply -f 02-test-resources.yaml
kubectl delete -f 02-test-resources.yaml
```

