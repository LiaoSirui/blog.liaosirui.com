

## 简介

去创建 PV 来和 PVC 进行绑定，有的场景下面需要自动创建 PV，这个时候就需要使用到 StorageClass 了，并且需要一个对应的 provisioner 来自动创建 PV，比如这里我们使用的 NFS 存储，则可以使用 nfs-subdir-external-provisioner 这个 Provisioner

它使用现有的和已配置的NFS 服务器来支持通过 PVC 动态配置 PV，持久卷配置为 `${namespace}-${pvcName}-${pvName}`

项目地址：

- <https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner>

## 安装

使用 Helm 进行安装

```bash
> helm repo add \
  nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

> helm upgrade --install nfs-subdir-external-provisioner \
nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--set nfs.server=10.244.244.201 \
--set nfs.path=/data/nfs \
--set image.repository=cnych/nfs-subdir-external-provisioner \
--set storageClass.defaultClass=true \
-n kube-system

```

上面的命令会在 `kube-system` 命名空间下安装 `nfs-subdir-external-provisioner`，并且会创建一个名为 `nfs-client` 默认的 StorageClass：