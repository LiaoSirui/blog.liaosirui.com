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

安装 crd

```bash
kubectl apply -f \
	https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.crds.yaml
```

安装 cert-manger

```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.10.1 \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=4
```

