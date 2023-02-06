## 安装 NFS CSI 驱动

首先需要在 Kubernetes 集群中安装 NFS CSI 的驱动，https://github.com/kubernetes-csi/csi-driver-nfs 就是一个 NFS 的 CSI 驱动实现的项目。

直接使用下面的命令一键安装 NFS CSI 驱动程序：

```bash
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh | bash -s master --
```

也可以本地安装：

```bash
git clone https://github.com/kubernetes-csi/csi-driver-nfs.git && cd csi-driver-nfs

./deploy/install-driver.sh master local
```

和上面介绍的部署方式基本上也是一致的，首先会用 DaemonSet 的形式在每个节点上运行了一个包含 `Driver registra` 容器的 Pod，当然和节点相关的操作比如 Mount/Unmount 也是在这个 Pod 里面执行的，其他的比如 Provision、Attach 都是在另外的 `csi-nfs-controller-xxx` Pod 中执行的。

```bash
> kubectl -n kube-system get pod -o wide -l app=csi-nfs-controller

NAME                                  READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
csi-nfs-controller-7dd749b445-99nrs   3/3     Running   0          56s   10.244.244.201   devmaster   <none>           <none>

> kubectl -n kube-system get pod -o wide -l app=csi-nfs-node

NAME                 READY   STATUS    RESTARTS   AGE    IP               NODE        NOMINATED NODE   READINESS GATES
csi-nfs-node-5mldq   3/3     Running   0          2m8s   10.244.244.212   devnode2    <none>           <none>
csi-nfs-node-8xpzf   3/3     Running   0          2m8s   10.244.244.201   devmaster   <none>           <none>
csi-nfs-node-9xqh2   3/3     Running   0          2m8s   10.244.244.211   devnode1    <none>           <none>

```

还可以通过 helm 进行安装

官网 <https://github.com/kubernetes-csi/csi-driver-nfs> 按 helm 模式下载源码:

```bash
helm repo add csi-driver-nfs \
  https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

helm pull csi-driver-nfs/csi-driver-nfs --untar
```

修改模板文件中 `dnsPolicy: ClusterFirst`

## 通过 CSI 创建 NFS 存储

当 csi 的驱动安装完成后我们就可以通过 csi 的方式来使用我们的 nfs 存储了。

比如创建：

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  mountOptions:
    - hard
    - nfsvers=4.1
  csi:
    driver: nfs.csi.k8s.io
    readOnly: false
    volumeHandle: unique-volumeid  # make sure it's a unique id in the cluster
    volumeAttributes:
      server: 10.244.244.101
      share: /data/nfs
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-nfs-static
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  volumeName: pv-nfs
  storageClassName: ""

```

直接创建上面的资源对象后我们的 PV 和 PVC 就绑定在一起了：

```bash
> kubectl get pv pv-nfs

NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS   REASON   AGE
pv-nfs   10Gi       RWX            Retain           Bound    default/pvc-nfs-static                           48s

> kubectl get pvc pvc-nfs-static

NAME             STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-nfs-static   Bound    pv-nfs   10Gi       RWX                           50s

```

这里的核心配置是 PV 中的 `csi` 属性的配置，需要通过 `csi.driver` 来指定我们要使用的驱动名称，比如我们这里使用 nfs 的名称为 `nfs.csi.k8s.io`，然后就是根据具体的驱动配置相关的参数。

同样还可以创建一个用于动态创建 PV 的 StorageClass 对象：

```yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.244.244.101
  share: /mnt/nfs
  # csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
  # csi.storage.k8s.io/provisioner-secret-name: "mount-options"
  # csi.storage.k8s.io/provisioner-secret-namespace: "default"
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - hard
  - nfsvers=4.1

```

对于普通用户来说使用起来都是一样的，只需要管理员提供何时的 PV 或 StorageClass 即可，这里就使用的 CSI 的形式来提供 NFS 的存储。

