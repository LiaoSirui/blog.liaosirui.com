

## 简介

去创建 PV 来和 PVC 进行绑定，有的场景下面需要自动创建 PV，这个时候就需要使用到 StorageClass 了，并且需要一个对应的 provisioner 来自动创建 PV，比如这里我们使用的 NFS 存储，则可以使用 nfs-subdir-external-provisioner 这个 Provisioner

它使用现有的和已配置的NFS 服务器来支持通过 PVC 动态配置 PV，持久卷配置为 `${namespace}-${pvcName}-${pvName}`

项目地址：

- <https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner>

## 安装

添加 NFS Subdir External Provisioner 到 Helm Chart

```bash
helm repo add \
  nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
```

拉取 chart 信息

```bash
helm pull \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --version 4.0.17 \
  --untar
```

修改 values.yaml 文件，配置 NFS 服务器 IP 地址和共享目录

```yaml
nfs:
  server: 10.244.244.201
  path: /data/nfs
  mountOptions:
  volumeName: nfs-subdir-external-provisioner-root
  # Reclaim policy for the main nfs volume
  reclaimPolicy: Retain

storageClass:
  create: true

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

使用 Helm 进行安装

```bash
helm upgrade --install nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  -f ./values.yaml \
  --version 4.0.17 \
  -n nfs-provisioner \
  --create-namespace

```

上面的命令会在 `nfs-provisioner` 命名空间下安装 `nfs-subdir-external-provisioner`，并且会创建一个名为 `nfs-client` 默认的 StorageClass：

```bash
> kubectl get sc

NAME                  PROVISIONER                                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
nfs-client            cluster.local/nfs-subdir-external-provisioner   Delete          Immediate              true                   4m6s

> kubectl get sc nfs-client -o yaml

allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    meta.helm.sh/release-name: nfs-subdir-external-provisioner
    meta.helm.sh/release-namespace: nfs-provisioner
  creationTimestamp: "2023-02-06T07:02:59Z"
  labels:
    app: nfs-subdir-external-provisioner
    app.kubernetes.io/managed-by: Helm
    chart: nfs-subdir-external-provisioner-4.0.17
    heritage: Helm
    release: nfs-subdir-external-provisioner
  name: nfs-client
  resourceVersion: "2223688"
  uid: a19e6e6c-5896-463c-a3e5-c452c9ef6bbc
parameters:
  archiveOnDelete: "true"
provisioner: cluster.local/nfs-subdir-external-provisioner
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

这样当以后我们创建的 PVC 中如果没有指定具体的 `StorageClass` 的时候，则会使用上面的 SC 自动创建一个 PV。

比如我们创建一个如下所示的 PVC：

```yaml
# nfs-sc-pvc
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-sc-pvc
spec:
  storageClassName: nfs-client  # 不指定则使用默认的 SC
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

直接创建上面的 PVC 资源对象后就会自动创建一个 PV 与其进行绑定：

```bash
> kubectl get pvc nfs-sc-pvc

NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nfs-sc-pvc   Bound    pvc-7804cb00-45e6-470d-91ef-136ac38318a4   1Gi        RWO            nfs-client     6s
```

对应自动创建的 PV 如下所示：

```bash
> kubectl get pv pvc-7804cb00-45e6-470d-91ef-136ac38318a4 -o yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: cluster.local/nfs-subdir-external-provisioner
  creationTimestamp: "2023-02-06T07:10:01Z"
  finalizers:
  - kubernetes.io/pv-protection
  name: pvc-7804cb00-45e6-470d-91ef-136ac38318a4
  resourceVersion: "2224876"
  uid: a68d80b1-ab91-4dc1-ab51-cb43bf5d829d
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: nfs-sc-pvc
    namespace: default
    resourceVersion: "2224871"
    uid: 7804cb00-45e6-470d-91ef-136ac38318a4
  nfs:
    path: /data/nfs/default-nfs-sc-pvc-pvc-7804cb00-45e6-470d-91ef-136ac38318a4
    server: 10.244.244.201
  persistentVolumeReclaimPolicy: Delete
  storageClassName: nfs-client
  volumeMode: Filesystem
status:
  phase: Bound
```

挂载的 nfs 目录为 `/data/nfs/default-nfs-sc-pvc-pvc-7804cb00-45e6-470d-91ef-136ac38318a4`，和上面的 `${namespace}-${pvcName}-${pvName}` 规范一致的。

