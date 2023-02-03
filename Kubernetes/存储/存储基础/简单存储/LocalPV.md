## LocalPV

在 hostPath 的基础上，Kubernetes 依靠 PV、PVC 实现了一个新的特性：`Local Persistent Volume`，也就是 `Local PV`

其实 `Local PV` 实现的功能就非常类似于 `hostPath` 加上 `nodeAffinity`，比如，一个 Pod 可以声明使用类型为 Local 的 PV，而这个 PV 其实就是一个 hostPath 类型的 Volume。

- “一个 PV 一块盘”

如果这个 hostPath 对应的目录，已经在节点 A 上被事先创建好，那么，只需要再给这个 Pod 加上一个 `nodeAffinity=nodeA`，不就可以使用这个 Volume 了吗？理论上确实是可行的，但是事实上，绝不应该把一个宿主机上的目录当作 PV 来使用，因为本地目录的存储行为是完全不可控，它所在的磁盘随时都可能被应用写满，甚至造成整个宿主机宕机。所以，一般来说 `Local PV` 对应的存储介质是一块额外挂载在宿主机的磁盘或者块设备，可以认为就是 `“一个 PV 一块盘”`

- 在调度的时候考虑 Volume 的分布

另外一个 `Local PV` 和普通的 PV 有一个很大的不同在于 `Local PV` 可以保证 Pod 始终能够被正确地调度到它所请求的 `Local PV` 所在的节点上面，对于普通的 PV 来说，Kubernetes 都是先调度 Pod 到某个节点上，然后再持久化节点上的 Volume 目录，进而完成 Volume 目录与容器的绑定挂载，但是对于 `Local PV` 来说，节点上可供使用的磁盘必须是提前准备好的，因为它们在不同节点上的挂载情况可能完全不同，甚至有的节点可以没这种磁盘，所以，这时候，调度器就必须能够知道所有节点与 `Local PV` 对应的磁盘的关联关系，然后根据这个信息来调度 Pod，实际上就是在调度的时候考虑 Volume 的分布。

## 示例

### 创建 PV

接下来测试下 `Local PV` 的使用，当然按照上面的分析应该给宿主机挂载并格式化一个可用的磁盘，这里就暂时将 node1 节点上的 `/data/k8s/localpv` 这个目录看成是挂载的一个独立的磁盘

现在声明一个 `Local PV` 类型的 PV，如下所示：

```yaml
# pv-local.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-local
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /data/k8s/localpv  # node1节点上的目录
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - devnode1

```

和前面定义的 PV 不同，这里定义了一个 `local` 字段，表明它是一个 `Local PV`，而 path 字段，指定的正是这个 PV 对应的本地磁盘的路径，即：`/data/k8s/localpv`，这也就意味着如果 Pod 要想使用这个 PV，那它就必须运行在 devnode1 节点上。

所以，在这个 PV 的定义里，添加了一个节点亲和性 `nodeAffinity` 字段指定 node1 这个节点。这样，调度器在调度 Pod 的时候，就能够知道一个 PV 与节点的对应关系，从而做出正确的选择。

直接创建上面的资源对象：

```yaml
> kubectl apply -f pv-local.yaml
persistentvolume/pv-local created
> kubectl get pv
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS  CLAIM      STORAGECLASS      REASON   AGE
pv-local  5Gi        RWO            Delete           Available          local-storage              24s

```

可以看到，这个 PV 创建后，进入了 `Available`（可用）状态。

### 创建 PVC 绑定 PV

要使用这个 `Local PV` 的话就需要去创建一个 PVC 和他进行绑定：

```yaml
# pvc-local.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-local
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-storage

```

同样要注意声明的这些属性需要和上面的 PV 对应，直接创建这个资源对象：

```yaml
> kubectl apply -f pvc-local.yaml
persistentvolumeclaim/pvc-local created
> kubectl get pvc
NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    AGE
pvc-local      Bound    pv-local      5Gi        RWO            local-storage   38s

```

可以看到现在 PVC 和 PV 已经处于 `Bound` 绑定状态了。但实际上这是不符合我们的需求的，比如现在我们的 Pod 声明使用这个 pvc-local，并且也明确规定，这个 Pod 只能运行在 devnode2 这个节点上，如果按照上面我们这里的操作，这个 pvc-local 是不是就和我们这里的 pv-local 这个 `Local PV` 绑定在一起了，但是这个 PV 的存储卷又在 devnode1 这个节点上，显然就会出现冲突了，那么这个 Pod 的调度肯定就会失败了，所以我们在使用 `Local PV` 的时候，必须想办法延迟这个`“绑定”`操作。

要怎么来实现这个延迟绑定呢？可以通过创建 `StorageClass` 来指定这个动作，在 StorageClass 种有一个 `volumeBindingMode=WaitForFirstConsumer` 的属性，就是告诉 Kubernetes 在发现这个 StorageClass 关联的 PVC 与 PV 可以绑定在一起，但不要现在就立刻执行绑定操作（即：设置 PVC 的 VolumeName 字段），而是要等到第一个声明使用该 PVC 的 Pod 出现在调度器之后，调度器再综合考虑所有的调度规则，当然也包括每个 PV 所在的节点位置，来统一决定，这个 Pod 声明的 PVC，到底应该跟哪个 PV 进行绑定。通过这个延迟绑定机制，原本实时发生的 PVC 和 PV 的绑定过程，就被延迟到了 Pod 第一次调度的时候在调度器中进行，从而保证了这个绑定结果不会影响 Pod 的正常调度。

所以需要创建对应的 `StorageClass` 对象：

```yaml
# local-storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer

```

这个 `StorageClass` 的名字，叫作 local-storage，也就是我们在 PV 中声明的，需要注意的是，在它的 `provisioner` 字段，我们指定的是 `no-provisioner`。

这是因为我们这里是手动创建的 PV，所以不需要动态来生成 PV，另外这个 StorageClass 还定义了一个 `volumeBindingMode=WaitForFirstConsumer` 的属性，它是 `Local PV` 里一个非常重要的特性，即：**延迟绑定**。

通过这个延迟绑定机制，原本实时发生的 PVC 和 PV 的绑定过程，就被延迟到了 Pod 第一次调度的时候在调度器中进行，从而保证了这个绑定结果不会影响 Pod 的正常调度。

现在我们来创建这个 StorageClass 资源对象：

```bash
> kubectl apply -f local-storageclass.yaml
storageclass.storage.k8s.io/local-storage created

```

现在重新删除上面声明的 PVC 对象，重新创建：

```bash
> kubectl delete -f pvc-local.yaml
persistentvolumeclaim "pvc-local" deleted
> kubectl create -f pvc-local.yaml
persistentvolumeclaim/pvc-local created
> kubectl get pvc
NAME           STATUS    VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    AGE
pvc-local      Pending                                           local-storage   3s

```

可以发现这个时候，集群中即使已经存在了一个可以与 PVC 匹配的 PV 了，但这个 PVC 依然处于 `Pending` 状态，也就是等待绑定的状态，这就是因为上面配置的是延迟绑定，需要在真正的 Pod 使用的时候才会来做绑定。

### 创建 Pod 使用 PVC

声明一个 Pod 来使用这里的 pvc-local 这个 PVC，资源对象如下所示：

```yaml
# pv-local-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pv-local-pod
spec:
  volumes:
  - name: example-pv-local
    persistentVolumeClaim:
      claimName: pvc-local
  containers:
  - name: example-pv-local
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: example-pv-local

```

直接创建这个 Pod：

```yaml
> kubectl apply -f pv-local-pod.yaml
pod/pv-local-pod created

```

创建完成后查看前面声明的 PVC，会立刻变成 `Bound` 状态，与前面定义的 PV 绑定在了一起：

```
> kubectl get pvc
NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS    AGE
pvc-local      Bound    pv-local      5Gi        RWO            local-storage   4m59s

```

这时候，可以尝试在这个 Pod 的 Volume 目录里，创建一个测试文件，比如：

```
> kubectl exec -it pv-local-pod /bin/sh

# cd /usr/share/nginx/html
# echo "Hello from Kubernetes local pv storage" > test.txt

```

然后，登录到 devnode1 这台机器上，查看一下它的 `/data/k8s/localpv` 目录下的内容，就可以看到刚刚创建的这个文件：

```
# 在 devnode1 节点上

> ls /data/k8s/localpv
test.txt

> cat /data/k8s/localpv/test.txt
Hello from Kubernetes local pv storage
```

如果重新创建这个 Pod 的话，就会发现，之前创建的测试文件，依然被保存在这个持久化 Volume 当中：

```
> kubectl delete -f pv-local-pod.yaml
> kubectl apply -f pv-local-pod.yaml
> kubectl exec -it pv-local-pod /bin/sh
# ls /usr/share/nginx/html
test.txt
# cat /usr/share/nginx/html/test.txt
Hello from Kubernetes local pv storage

```

