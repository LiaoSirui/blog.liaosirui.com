## Kstone 简介

官方：

- GitHub 地址：<https://github.com/kstone-io/kstone-dashboard>
- <https://github.com/kstone-io/kstone-etcd-operator>
- <https://www.oschina.net/p/kstone>
- Kstone 部署参考：<https://blog.51cto.com/lidabai/5420054>

## Kstone 部署

创建 Kstone 命名空间

```bash
kubectl create ns kstone
```

创建 Admin TOKEN，为 dashboard-api 创建 Admin TOKEN 以访问 Kubernetes

```bash
kubectl create serviceaccount kube-admin -n kube-system

kubectl create clusterrolebinding kube-admin \
--clusterrole=cluster-admin --serviceaccount=kube-system:kube-admin
```
