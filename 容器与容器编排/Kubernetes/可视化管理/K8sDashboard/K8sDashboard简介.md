## 简介

Kubernetes Dashboard 是 Kubernetes 集群通用的、基于 Web 的 UI。它允许用户管理集群中运行的应用程序并对其进行故障排除，以及管理集群本身。

官方：

- GitHub 仓库：<https://github.com/kubernetes/dashboard>

## 安装

官方的安装指南，运行如下命令：

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

安装指南：<https://github.com/kubernetes/dashboard#install>

也可以使用 Chart 安装：<https://github.com/kubernetes/dashboard/tree/master/charts/helm-chart/kubernetes-dashboard>

```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
```

查看最新的版本

```bash
> helm search repo kubernetes-dashboard                                     

NAME                                            CHART VERSION   APP VERSION     DESCRIPTION                                   
kubernetes-dashboard/kubernetes-dashboard       6.0.0           2.7.0           General-purpose web UI for Kubernetes clusters
```

下载 Chart

```bash
helm pull kubernetes-dashboard/kubernetes-dashboard --version 6.0.0

# 下载并解压
helm pull kubernetes-dashboard/kubernetes-dashboard --version 6.0.0 --untar
```

使用如下的 values.yaml 进行部署

```bash
tolerations:
  - operator: "Exists"

nodeSelector:
  kubernetes.io/hostname: devmaster

protocolHttp: true

extraArgs:
  - --token-ttl=360000

ingress:
  enabled: true
  hosts:
    - kubernetes-dashboard.alpha-quant.tech
  tls:
    - secretName: kubernetes-dashboard-https-tls
      hosts:
        - kubernetes-dashboard.alpha-quant.tech
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: cert-http01
    # nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: "true" # 强制跳转 https
    # nginx.ingress.kubernetes.io/secure-backends: "true"
    # nginx.ingress.kubernetes.io/rewrite-target: /

```

部署 dashboard

```bash
helm upgrade --install \
  --version 6.0.0 \
  -n kubernetes-dashboard \
  --create-namespace \
  -f ./values.yaml \
  kubernetes-dashboard \
  kubernetes-dashboard/kubernetes-dashboard
```

Kubernetes Dashboard 需要较大的权限才能够访问所有资源，需要使得 ServiceAccount 来获取对应的 token。

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin-kubernetes-dashboard
  labels:
    # kubernetes.io/bootstrapping: rbac-defaults
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin-kubernetes-dashboard
subjects:
  - kind: ServiceAccount
    name: kubernetes-dashboard
    namespace: kubernetes-dashboard

```

配置后需要重启 Kubernetes Dashboard 的 Pod
