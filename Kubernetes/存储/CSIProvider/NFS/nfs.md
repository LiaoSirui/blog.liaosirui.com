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