## 使用 nfs 类型的 pv

创建一个如下所示 nfs 类型的 PV 资源对象：

```yaml
---
# nfs-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  nfs:
    # 指定 nfs 的挂载点
    path: /data/nfs/tmp
    # 指定 nfs 服务地址
    server: 10.244.244.201

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

```

Pod 真正使用的是 PVC，而要使用 PVC 的前提就是必须要先和某个符合条件的 PV 进行一一绑定，比如存储容器、访问模式，以及 PV 和 PVC 的 storageClassName 字段必须一样，这样才能够进行绑定，当 PVC 和 PV 绑定成功后就可以直接使用这个 PVC 对象了：

```yaml
# nfs-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-volumes
spec:
  volumes:
  - name: nfs
    persistentVolumeClaim:
      claimName: nfs-pvc
  containers:
  - name: web
    image: nginx
    ports:
    - name: web
      containerPort: 80
    volumeMounts:
    - name: nfs
      subPath: test-volumes
      mountPath: "/usr/share/nginx/html"

```

直接创建上面的资源对象即可：

```bash
> kubectl apply -f volume.yaml
> kubectl apply -f pod.yaml
> kubectl get pv nfs-pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
nfs-pv   1Gi        RWO            Retain           Bound    default/nfs-pvc   manual                  119s
> kubectl get pvc nfs-pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nfs-pvc   Bound    nfs-pv   1Gi        RWO            manual         2m5s
> kubectl get pods test-volumes -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP          NODE	NOMINATED NODE   READINESS GATES
test-volumes   1/1     Running   0          51s   10.4.2.63   devnode2   <none>           <none>

```

由于这里 PV 中的数据为空，所以挂载后会将 nginx 容器中的 `/usr/share/nginx/html` 目录覆盖，那么访问应用的时候就没有内容了：

```bash
> curl http://10.4.2.63
<html>
<head><title>403 Forbidden</title></head>
<body>
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.23.3</center>
</body>
</html>
```

可以在 PV 目录中添加一些内容：

```bash
# 在 nfs 服务器上面执行
> echo "nfs pv content" > /data/nfs/tmp/test-volumes/index.html
> curl http://10.4.2.63
nfs pv content
```

然后重新访问就有数据了，而且当 Pod 应用挂掉或者被删掉重新启动后数据还是存在的，因为数据已经持久化了。

## 原理

### 存储的整体架构

整个存储的架构可以用下图来说明： 

<img src=".assets/20220213172357.png" alt="存储架构" style="zoom:50%;" />

- PV Controller：负责 PV/PVC 的绑定，并根据需求进行数据卷的 Provision/Delete 操作
- AD Controller：负责存储设备的 Attach/Detach 操作，将设备挂载到目标节点
- Volume Manager：管理卷的 Mount/Unmount 操作、卷设备的格式化等操作
- Volume Plugin：扩展各种存储类型的卷管理能力，实现第三方存储的各种操作能力和 Kubernetes 存储系统结合

上面使用的 NFS 就属于 `In-Tree` 这种方式

- `In-Tree` 就是在 Kubernetes 源码内部实现的，和 Kubernetes 一起发布、管理的，但是更新迭代慢、灵活性比较差
- 另外一种方式 `Out-Of-Tree` 是独立于 Kubernetes 的，目前主要有 `CSI` 和 `FlexVolume` 两种机制，开发者可以根据自己的存储类型实现不同的存储插件接入到 Kubernetes 中去，其中 `CSI` 是现在也是以后主流的方式。

### 挂载流程

- （1）PV Controller 绑定 PV / PVC

`PersistentVolumeController` 会不断地循环去查看每一个 PVC，是不是已经处于 Bound（已绑定）状态。如果不是，那它就会遍历所有的、可用的 PV，并尝试将其与未绑定的 PVC 进行绑定，这样，Kubernetes 就可以保证用户提交的每一个 PVC，只要有合适的 PV 出现，它就能够很快进入绑定状态。而所谓将一个 PV 与 PVC 进行**绑定**，其实就是将这个 PV 对象的名字，填在了 PVC 对象的 `spec.volumeName` 字段上。

- （2）持久化目录创建

PV 和 PVC 绑定上了，那么又是如何将容器里面的数据进行持久化的呢，Docker 的 Volume 挂载其实就是**将一个宿主机上的目录和一个容器里的目录绑定挂载在了一起**，具有持久化功能当然就是指的宿主机上面的这个目录了，当容器被删除或者在其他节点上重建出来以后，这个目录里面的内容依然存在，所以一般情况下实现持久化是需要一个远程存储的，比如 NFS、Ceph 或者云厂商提供的磁盘等等。所以接下来需要做的就是持久化宿主机目录这个过程。

当 Pod 被调度到一个节点上后，节点上的 kubelet 组件就会为这个 Pod 创建它的 Volume 目录，默认情况下 kubelet 为 Volume 创建的目录在 kubelet 工作目录下面：

```bash
/var/lib/kubelet/pods/<Pod的ID>/volumes/kubernetes.io~<Volume类型>/<Volume名字>
```

比如上面我们创建的 Pod 对应的 Volume 目录完整路径为：

```bash
/var/lib/kubelet/pods/30dfc6f7-ba8a-400e-882f-8695d8c50c81/volumes/kubernetes.io~nfs/nfs-pv
```

> 要获取 Pod 的唯一标识 uid，可通过命令 `kubectl get pod -o jsonpath={.metadata.uid} <pod名>` 获取。

- （3）Attach 阶段

然后就需要根据我们的 Volume 类型来决定需要做什么操作了，假如后端存储使用的 Ceph RBD，那么 kubelet 就需要先将 Ceph 提供的 RBD 挂载到 Pod 所在的宿主机上面，这个阶段在 Kubernetes 中被称为 **Attach 阶段**。

- （4）Mount 阶段

Attach 阶段完成后，为了能够使用这个块设备，kubelet 还要进行第二个操作，即：**格式化**这个块设备，然后将它**挂载**到宿主机指定的挂载点上。这个挂载点，也就是上面我们提到的 Volume 的宿主机的目录。

将块设备格式化并挂载到 Volume 宿主机目录的操作，在 Kubernetes 中被称为 **Mount 阶段**。但是对于我们这里使用的 NFS 就更加简单了， 因为 NFS 存储并没有一个设备需要挂载到宿主机上面，所以这个时候 kubelet 就会直接进入第二个 `Mount` 阶段，相当于直接在宿主机上面执行如下的命令：

```bash
mount -t nfs 10.244.244.201:/data/nfs/tmp \
  /var/lib/kubelet/pods/30dfc6f7-ba8a-400e-882f-8695d8c50c81/volumes/kubernetes.io~nfs/nfs-pv
```

同样可以在测试的 Pod 所在节点查看 Volume 的挂载信息：

```bash
> findmnt /var/lib/kubelet/pods/30dfc6f7-ba8a-400e-882f-8695d8c50c81/volumes/kubernetes.io~nfs/nfs-pv

TARGET                                                                                      SOURCE                       FSTYPE OPTIONS
/var/lib/kubelet/pods/30dfc6f7-ba8a-400e-882f-8695d8c50c81/volumes/kubernetes.io~nfs/nfs-pv 10.244.244.201:/data/nfs/tmp nfs4   rw,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.244.244.21

```

可以看到这个 Volume 被挂载到了 NFS 下面，以后在这个目录里写入的所有文件，都会被保存在远程 NFS 服务器上。

这样在经过了上面的阶段过后，就得到了一个持久化的宿主机上面的 Volume 目录了，接下来 kubelet 只需要把这个 Volume 目录挂载到容器中对应的目录即可，这样就可以为 Pod 里的容器挂载这个持久化的 Volume 了，这一步其实也就相当于执行了如下所示的命令：

```bash
# docker 或者 nerdctl
docker run \
  -v /var/lib/kubelet/pods/<Pod的ID>/volumes/kubernetes.io~<Volume类型>/<Volume名字>:/<容器内的目标目录> \
  <我的镜像> ...
```

