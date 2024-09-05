## hostpath

- 缺陷

使用 hostPath 有一个局限性就是，Pod 不能随便漂移，需要固定到一个节点上，因为一旦漂移到其他节点上去了宿主机上面就没有对应的数据了，所以我们在使用 hostPath 的时候都会搭配 nodeSelector 来进行使用

Kubernetes 支持 hostPath 类型的 PersistentVolume 使用节点上的文件或目录来模拟附带网络的存储，但是需要注意的是在生产集群中，我们不会使用 hostPath，集群管理员会提供网络存储资源，比如 NFS 共享卷或 Ceph 存储卷，集群管理员还可以使用 `StorageClasses` 来设置动态提供存储

因为 Pod 并不是始终固定在某个节点上面的，所以要使用 hostPath 的话我们就需要将 Pod 固定在某个节点上，这样显然就大大降低了应用的容错性

- 好处

但是使用 hostPath 明显也有一些好处的，因为 PV 直接使用的是本地磁盘，尤其是 SSD 盘，它的读写性能相比于大多数远程存储来说，要好得多，所以对于一些对磁盘 IO 要求比较高的应用比如 etcd 就非常实用

## 示例

### 创建 PV

首先来创建一个 `hostPath` 类型的 `PersistentVolume`

比如这里将测试的应用固定在节点 devnode1 上面，首先在该节点上面创建一个 `/data/k8s/test/hostpath` 的目录，然后在该目录中创建一个 `index.html` 的文件：

```bash
mkdir -p /data/k8s/test/hostpath

echo 'Hello from Kubernetes hostpath storage' > /data/k8s/test/hostpath/index.html
```

然后接下来创建一个 hostPath 类型的 PV 资源对象：（pv-hostpath.yaml）

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/k8s/test/hostpath"

```

配置文件中指定了

- 该卷位于集群节点上的 `/data/k8s/test/hostpath` 目录
- 指定了 10G 大小的空间和 `ReadWriteOnce` 的访问模式，这意味着该卷可以在单个节点上以读写方式挂载
- 另外还定义了名称为 `manual` 的 `StorageClass`，该名称用来将 `PersistentVolumeClaim` 请求绑定到该 `PersistentVolum`

直接创建上面的资源对象：

```bash
> kubectl apply -f pv-hostpath.yaml
persistentvolume/pv-hostpath created
```

创建完成后查看 PersistentVolume 的信息，输出结果显示该 `PersistentVolume` 的状态（STATUS） 为 `Available`

这意味着它还没有被绑定给 `PersistentVolumeClaim`：

```bash
> kubectl get pv pv-hostpath
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv-hostpath   10Gi       RWO            Retain           Available           manual                  58s

```

### 创建 PVC 绑定 PV

现在创建完成了 PV，如果需要使用这个 PV 的话，就需要创建一个对应的 PVC 来进行绑定，就类似于服务是通过 Pod 来运行的，而不是 Node，只是 Pod 跑在 Node 上而已。

现在创建一个 `PersistentVolumeClaim`，Pod 使用 PVC 来请求物理存储，这里创建的 PVC 请求至少 3G 容量的卷，该卷至少可以为一个节点提供读写访问，下面是 PVC 的配置文件：

```yaml
# pvc-hostpath.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-hostpath
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi

```

创建 PVC 之后，Kubernetes 就会去查找满足我们声明要求的 PV，比如 `storageClassName`、`accessModes` 以及容量这些是否满足要求，如果满足要求就会将 PV 和 PVC 绑定在一起。

再次查看 PV 的信息：

```bash
> kubectl get pv -l type=local
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
pv-hostpath   10Gi       RWO            Retain           Bound    default/pvc-hostpath   manual                  81m

```

现在输出的 STATUS 为 `Bound`，查看 PVC 的信息：

```bash
> kubectl get pvc pvc-hostpath
NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-hostpath   Bound    pv-hostpath   10Gi       RWO            manual         6m47s

```

输出结果表明该 PVC 绑定了到了上面创建的 `pv-hostpath` 这个 PV 上面了，这里虽然声明的3G的容量，但是由于 PV 里面是 10G，所以显然也是满足要求的。

### 创建 Pod 使用 PVC

PVC 准备好过后，接下来我们就可以来创建 Pod 了，该 Pod 使用上面声明的 PVC 作为存储卷：

```bash
# pv-hostpath-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pv-hostpath-pod
spec:
  volumes:
  - name: pv-hostpath
    persistentVolumeClaim:
      claimName: pvc-hostpath
  nodeSelector:
    kubernetes.io/hostname: devnode1
  containers:
  - name: task-pv-container
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: "/usr/share/nginx/html"
      name: pv-hostpath

```

这里需要注意的是，由于创建的 PV 真正的存储在节点 devnode1 上面，所以这里必须把 Pod 固定在这个节点下面

另外可以注意到 Pod 的配置文件指定了 `PersistentVolumeClaim`，但没有指定 `PersistentVolume`，对 Pod 而言，`PVC` 就是一个存储卷

直接创建这个 Pod 对象即可：

```bash
> kubectl create -f pv-hostpath-pod.yaml
pod/pv-hostpath-pod created

> kubectl get pod pv-hostpath-pod
NAME              READY   STATUS    RESTARTS   AGE
pv-hostpath-pod   1/1     Running   0          105s

```

运行成功后，可以打开一个 shell 访问 Pod 中的容器：

```bash
kubectl exec -it pv-hostpath-pod -- /bin/bash

```

在 shell 中，我们可以验证 nginx 的数据 是否正在从 hostPath 卷提供 index.html 文件：

```bash
root@pv-hostpath-pod:/# apt-get update
root@pv-hostpath-pod:/# apt-get install curl -y
root@pv-hostpath-pod:/# curl localhost
Hello from Kubernetes hostpath storage

```

