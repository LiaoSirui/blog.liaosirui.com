DIND

如下所示，我们有一个名为 `clean-ci` 的容器，会该容器添加一个 Sidecar 容器，配合 emptyDir，让 `clean-ci` 容器可以通过 UNIX Socket 访问 DinD 容器：

```
apiVersion: v1
kind: Pod
metadata:
  name: clean-ci
spec:
  containers:
  - name: dind
    image: 'docker:stable-dind'
    command:
    - dockerd
    - --host=unix:///var/run/docker.sock
    - --host=tcp://0.0.0.0:8000
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /var/run
      name: cache-dir
  - name: clean-ci
    image: 'docker:stable'
    command: ["/bin/sh"]
    args: ["-c", "docker info >/dev/null 2>&1; while [ $? -ne 0 ] ; do sleep 3; docker info >/dev/null 2>&1; done; docker pull library/busybox:latest; docker save -o busybox-latest.tar library/busybox:latest; docker rmi library/busybox:latest; while true; do sleep 86400; done"]
    volumeMounts:
    - mountPath: /var/run
      name: cache-dir
  volumes:
  - name: cache-dir
    emptyDir: {}
```

通过上面添加的 `dind` 容器来提供 dockerd 服务，然后在业务构建容器中通过 `emptyDir{}` 来共享 `/var/run` 目录，业务容器中的 docker 客户端就可以通过 `unix:///var/run/docker.sock` 来与 dockerd 进行通信。

使用 DaemonSet 在每个 containerd 节点上部署 Docker

除了上面的 Sidecar 模式之外，还可以直接在 containerd 集群中通过 DaemonSet 来部署 Docker，然后业务构建的容器就和之前使用的模式一样，直接通过 hostPath 挂载宿主机的 `unix:///var/run/docker.sock` 文件即可。

使用以下 YAML 部署 DaemonSet。示例如下：

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: docker-ci
spec:
  selector:
    matchLabels:
      app: docker-ci
  template:
    metadata:
      labels:
        app: docker-ci
    spec:
      containers:
      - name: docker-ci
        image: 'docker:stable-dind'
        command:
        - dockerd
        - --host=unix:///var/run/docker.sock
        - --host=tcp://0.0.0.0:8000
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /var/run
          name: host
      volumes:
      - name: host
        hostPath:
          path: /var/run
```

上面的 DaemonSet 会在每个节点上运行一个 `dockerd` 服务，这其实就类似于将以前的 docker 服务放入到了 Kubernetes 集群中进行管理，然后其他的地方和之前没什么区别，甚至都不需要更改以前方式的任何东西。将业务构建 Pod 与 DaemonSet 共享同一个 hostPath，如下所示：

```
apiVersion: v1
kind: Pod
metadata:
  name: clean-ci
spec:
  containers:
  - name: clean-ci
    image: 'docker:stable'
    command: ["/bin/sh"]
    args: ["-c", "docker info >/dev/null 2>&1; while [ $? -ne 0 ] ; do sleep 3; docker info >/dev/null 2>&1; done; docker pull library/busybox:latest; docker save -o busybox-latest.tar library/busybox:latest; docker rmi library/busybox:latest; while true; do sleep 86400; done"]
    volumeMounts:
    - mountPath: /var/run
      name: host
  volumes:
  - name: host
    hostPath:
      path: /var/run
```