1. 直接创建 NFS 的 Volume

直接创建 PV：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-imagenet
spec:
  capacity:
    storage: 150Gi
  volumeMode: Filesystem
  accessModes:
  - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  mountOptions:
  - vers=3
  - nolock
  - proto=tcp
  - rsize=1048576
  - wsize=1048576
  - hard
  - timeo=600
  - retrans=2
  - noresvport
  - nfsvers=4.1
  nfs:
    path: <YOUR_PATH_TO_DATASET>
    server: <YOUR_NFS_SERVER>
```

通过挂载 PVC 使用此 PV：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-imagenet
spec:
  accessModes:
  - ReadOnlyMany
  resources:
    requests:
      storage: 150Gi
  storageClassName: nfs
```

## sig-storage-lib-external-provisioner

使用 sig-storage-lib-external-provisioner <https://github.com/kubernetes-sigs/sig-storage-lib-external-provisioner> 库开发 external provisioners

### nfs-subdir-external-provisioner

（1）nfs-subdir-external-provisioner（nfs-client-provisioner）

是一个自动配置 P V程序，它必须使用已配置的 NFS 服务器来支持通过 PVC 动态配置 PV。

配置的 PV 名为 `${namespace-pvcname}-{$pvname}`。

仓库地址：<https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner>

SC 配置：

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: fuseim.pri/ifs     # 动态卷分配者名称，必须和上面创建的"provisioner"变量中设置的Name一致
parameters:
  archiveOnDelete: "false"
```

创建的 PVC 后，会自动创建 PV 并将其 `.spec.nfs.path` 配置成 `NFS_PATH/${namespace-pvcname}-{$pvname}`

如果不额外配置，PVC 删除后的回收策略默认是 Delete。此时会给 Pod 对应的文件夹名字前面加一个 archived 做归档。

通过给 nfs-client-provisioner 传送参数 `archiveOnDelete: "false"`，不会做归档而是直接删除文件夹。

### nfs-ganesha-server-and-external-provisioner

（2）nfs-ganesha-server-and-external-provisioner（nfs-provisioner）

仓库地址：<https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner>

nfs-provisioner 是一个 out-of-tree 的动态 provisioner

可以将主机上某个 Volume（必须是支持的文件系统）挂载到它的 `/export` 目录

StorageClass 中指定 provisioner 为 `example.com/nfs` 即可

SC 配置：

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: example-nfs
provisioner: example.com/nfs   
mountOptions:
  - vers=4.1
```

## NFS CSI Driver

NFS CSI Driver 是 K8s 官方提供的 CSI 示例程序，只实现了 CSI 的最简功能

要求已经有配置完成的 NFS 服务器

- Controller 由 CSI Plugin + csi-provisioner + liveness-probe 组成

- node-server 由 CSI Plugin + liveness-probe + node-driver-registrar 组成

## Fluid

通过 Fluid 项目来使用 NFS

不但可以像读取本地文件一样读取 NFS 中的文件，还可以享受内存加速效果。

详情可参考 <https://github.com/fluid-cloudnative/fluid>