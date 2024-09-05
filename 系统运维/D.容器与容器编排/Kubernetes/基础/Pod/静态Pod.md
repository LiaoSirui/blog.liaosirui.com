## 静态 Pod 简介

在 Kubernetes 集群中除了我们经常使用到的普通的 Pod 外，还有一种特殊的 Pod，叫做 Static Pod，也就是我们说的静态 Pod

静态 Pod 直接由节点上的 kubelet 进程来管理，不通过 master 节点上的 apiserver。无法与我们常用的控制器 Deployment 或者 DaemonSet 进行关联，它由 kubelet 进程自己来监控，当 pod 崩溃时会重启该 pod，kubelet 也无法对他们进行健康检查。静态 pod 始终绑定在某一个 kubelet 上，并且始终运行在同一个节点上。kubelet 会自动为每一个静态 pod 在 Kubernetes 的 apiserver 上创建一个镜像 Pod，因此我们可以在 apiserver 中查询到该 pod，但是不能通过 apiserver 进行控制（例如不能删除）。

## 创建静态 Pod

创建静态 Pod 有两种方式：`配置文件`和 `HTTP` 两种方式

### 配置文件

配置文件就是放在特定目录下的标准的 JSON 或 YAML 格式的 pod 定义文件。

用 `kubelet --pod-manifest-path=<the directory>` 来启动 kubelet 进程，kubelet 定期的去扫描这个目录，根据这个目录下出现或消失的 YAML/JSON 文件来创建或删除静态 pod。

比如我们在 devmaster 这个节点上用静态 pod 的方式来启动一个 nginx 的服务，配置文件路径为：

```bash
> cat /var/lib/kubelet/config.yaml  | yq .staticPodPath
/etc/kubernetes/manifests

# 和命令行的 pod-manifest-path 参数一致
```

打开这个文件可以看到其中有一个属性为 `staticPodPath` 的配置，其实和命令行的 `--pod-manifest-path` 配置是一致的，所以如果通过 kubeadm 的方式来安装的集群环境，对应的 kubelet 已经配置了静态 Pod 文件的路径，默认地址为 `/etc/kubernetes/manifests`，所以只需要在该目录下面创建一个标准的 Pod 的 JSON 或者 YAML 文件即可，如果 kubelet 启动参数中没有配置上面的`--pod-manifest-path` 参数的话，那么添加上这个参数然后重启 kubelet 即可：

```
cat << _EOF_ >/etc/kubernetes/manifests/static-web.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    app: static
spec:
  containers:
    - name: web
      image: nginx
      ports:
        - name: web
          containerPort: 80
_EOF_
```

### 通过 HTTP 创建静态 Pods

kubelet 周期地从 `--manifest-url=` 参数指定的地址下载文件，并且把它翻译成 JSON/YAML 格式的 pod 定义。

此后的操作方式与`–-pod-manifest-path=` 相同，kubelet 会不时地重新下载该文件，当文件变化时对应地终止或启动静态 pod。

## 静态 Pod 的启动

kubelet 启动时，由 `--pod-manifest-path=` 或 `--manifest-url=` 参数指定的目录下定义的所有 pod 都会自动创建，例如，示例中的 `static-web`：

```
> nerdctl -n k8s.io ps
CONTAINER ID    IMAGE                                              COMMAND                   CREATED           STATUS    PORTS    NAMES
6add7aa53969    docker.io/library/nginx:latest                     "/docker-entrypoint.…"    43 seconds ago    Up
......
```

现在通过 kubectl 工具可以看到这里创建了一个新的镜像 Pod：

```
> kubectl get pods
NAME               READY   STATUS    RESTARTS   AGE
static-web-node1   1/1     Running   0          109s
```

静态 pod 的标签会传递给镜像 Pod，可以用来过滤或筛选。需要注意的是，不能通过 API 服务器来删除静态 pod（例如，通过 kubectl 命令），kubelet 不会删除它。

```
> kubectl delete pod static-web-node1
pod "static-web-node1" deleted

> kubectl get pods
NAME               READY   STATUS    RESTARTS   AGE
static-web-node1   1/1     Running   0          4s
```

## 静态 Pod 的动态增加和删除

运行中的 kubelet 周期扫描配置的目录（我们这个例子中就是 /etc/kubernetes/manifests）下文件的变化，当这个目录中有文件出现或消失时创建或删除 pods：

```
> mv /etc/kubernetes/manifests/static-web.yaml /tmp
# sleep 20

> nerdctl -n k8s.io ps
// no nginx container is running

> mv /tmp/static-web.yaml  /etc/kubernetes/manifests
# sleep 20

> nerdctl -n k8s.io ps
CONTAINER ID    IMAGE                                              COMMAND                   CREATED           STATUS    PORTS    NAMES
902be9190538    docker.io/library/nginx:latest                     "/docker-entrypoint.…"    14 seconds ago    Up
......
```

其实用 kubeadm 安装的集群，master 节点上面的几个重要组件都是用静态 Pod 的方式运行的，登录到 master 节点上查看 `/etc/kubernetes/manifests` 目录：

```
> ls /etc/kubernetes/manifests/
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
```

这种方式也为将集群的一些组件容器化提供了可能