## 背景

Linuxs 利用 Cgroup 实现了对容器的资源限制，但在容器内部依然缺省挂载了宿主机上的 procfs 的 `/proc` 目录，其包含如：meminfo, cpuinfo，stat， uptime 等资源信息

一些监控工具如 free/top 或遗留应用还依赖上述文件内容获取资源配置和使用情况

当它们在容器中运行时，就会把宿主机的资源状态读取出来，引起错误和不便

通过 lxcfs 提供容器资源可见性的方法，可以帮助一些遗留系统更好的识别容器运行时的资源限制

## lxcfs 简介

<img src=".assets/image-20221213141917212.png" alt="image-20221213141917212" style="zoom:33%;" />

官方地址：<https://linuxcontainers.org/lxcfs/introduction/>

最新 release 地址：<https://linuxcontainers.org/lxcfs/downloads/>

Github 仓库地址：<https://github.com/lxc/lxcfs>

部署参考：

- <https://github.com/denverdino/lxcfs-admission-webhook>

- <https://github.com/cndoit18/lxcfs-on-kubernetes>

社区中常见的做法是利用 lxcfs 来提供容器中的资源可见性。lxcfs 是一个开源的 FUSE（用户态文件系统）实现来支持 LXC 容器，它也可以支持 Docker 容器。

基于 FUSE 实现的用户空间文件系统

- 站在文件系统的角度: 通过调用 libfuse 库和内核的 FUSE 模块交互实现
- 两个基本功能
  - 让每个容器有自身的 cgroup 文件系统视图,类似 Cgroup Namespace
  - 提供容器内部虚拟的 proc 文件系统

LXCFS 通过用户态文件系统，在容器中提供下列 `procfs` 的文件

```
/proc/cpuinfo
/proc/diskstats
/proc/meminfo
/proc/stat
/proc/swaps
/proc/uptime
/proc/slabinfo
/sys/devices/system/cpu
/sys/devices/system/cpu/online
```

LXCFS 的示意图如下

<img src=".assets/e1165184e7ffe5d96e4b863932c2a26f078.jpg" alt="img" style="zoom:50%;" />

比如，把宿主机的 `/var/lib/lxcfs/proc/memoinfo` 文件挂载到Docker容器的`/proc/meminfo`位置后

容器中进程读取相应文件内容时，LXCFS 的 FUSE 实现会从容器对应的 Cgroup 中读取正确的内存限制，从而使得应用获得正确的资源约束设定

## Docker 环境下 lxcfs 使用

开启方式：

```bash
modprobe fuse
```

开启 FUSE 模块支持

```bash
> lsmod | grep fuse

fuse                  172032  1
```

安装 lxcfs 的 RPM 包

``` bash
dnf install lxcfs
```

启动服务

```bash
systemctl start lxcfs
```

查看状态

```bas
systemctl status lxcfs
```

默认的启动命令是

```bash
/usr/bin/lxcfs /var/lib/lxcfs
```

测试

```bash
docker run -it --rm \
	--cpus 2 --memory 4g \
  -v /var/lib/lxcfs/proc/cpuinfo:/proc/cpuinfo:rw \
  -v /var/lib/lxcfs/proc/diskstats:/proc/diskstats:rw \
  -v /var/lib/lxcfs/proc/loadavg:/proc/loadavg:rw \
  -v /var/lib/lxcfs/proc/meminfo:/proc/meminfo:rw \
  -v /var/lib/lxcfs/proc/stat:/proc/stat:rw \
  -v /var/lib/lxcfs/proc/slabinfo:/proc/slabinfo:rw \
  -v /var/lib/lxcfs/proc/swaps:/proc/swaps:rw \
  -v /var/lib/lxcfs/proc/uptime:/proc/uptime:rw \
  -v /var/lib/lxcfs/sys/devices/system/cpu:/sys/devices/system/cpu \
  --security-opt seccomp=unconfined \
  rockylinux/rockylinux:9.1.20221123 bash
```

在容器中安装工具集

```bash
dnf install -y epel-release
dnf install -y procps-ng htop
```

测试效果

```bash
[root@5cbb01cecd60 /]# free -g
               total        used        free      shared  buff/cache   available
Mem:               4           0           3           0           0           3
Swap:              0           0           0

[root@5cbb01cecd60 /]# uptime
 05:58:40 up 2 min,  0 users,  load average: 0.18, 0.25, 0.34
```

可以看到 total 的内存为 4g，配置已经生效

## lxcfs 的 Kubernetes实践

<img src=".assets/d21cc9032174006d97a770ca4396a533.png" alt="图片" style="zoom: 67%;" />

先确保节点都开启 fuse 内核模块，并写入文件

```bash
cat << EOF > /etc/modules-load.d/fuse.conf
fuse
EOF
```

准备 rbac

```yaml
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: lxcfs-manager-sa
  namespace: lxcfs
  labels:
    app.kubernetes.io/name: lxcfs-manager
imagePullSecrets:
  - name: lxcfs-image-pull-secrets

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: 'lxcfs-manager-cr'
  labels:
    app.kubernetes.io/name: lxcfs-manager
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - events
  verbs:
  - '*'
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - '*'

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: 'lxcfs-manager-crb'
  labels:
    app.kubernetes.io/name: lxcfs-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: 'lxcfs-manager-cr'
subjects:
- kind: ServiceAccount
  name: lxcfs-manager-sa
  namespace: "lxcfs"

```

要在集群节点上安装并启动 lxcfs，将用 Kubernetes 的方式，用利用容器和 DaemonSet 方式来运行 lxcfs FUSE 文件系统

由于 lxcfs FUSE 需要共享系统的 PID 名空间以及需要特权模式，所以配置了相应的容器启动参数

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: 'lxcfs-controller-manager-daemonset'
  namespace: "lxcfs"
  labels:
    app.kubernetes.io/name: lxcfs-manager
    app.kubernetes.io/compose: lxcfs
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: lxcfs-manager
      app.kubernetes.io/compose: lxcfs
  template:
    metadata:
      annotations:
        {}
      labels:
        app.kubernetes.io/name: lxcfs-manager
        app.kubernetes.io/compose: lxcfs
    spec:
      serviceAccountName: lxcfs-manager-sa
      imagePullSecrets:
        - name: lxcfs-image-pull-secrets
      containers:
      - name: agent
        args:
        - -l
        - --enable-cfs
        - --enable-pidfd
        - /var/lib/lxcfs
        image: ghcr.io/cndoit18/lxcfs-agent:v0.1.4
        imagePullPolicy: "IfNotPresent"
        resources:
          limits:
            cpu: 500m
            memory: 300Mi
          requests:
            cpu: 300m
            memory: 200M
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /var/lib/lxcfs
          mountPropagation: Bidirectional
          name: lxcfs
        - mountPath: /sys/fs/cgroup
          name: cgroup
      hostPID: true
      volumes:
      - hostPath:
          path: /var/lib/lxcfs
          type: DirectoryOrCreate
        name: lxcfs
      - hostPath:
          path: /sys/fs/cgroup
        name: cgroup

```

部署

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: 'lxcfs-webhook-service'
  namespace: "lxcfs"
  labels:
    app.kubernetes.io/name: lxcfs-manager
    app.kubernetes.io/compose: manager
spec:
  type: ClusterIP
  ports:
    - port: 443
      targetPort: webhook-server
      protocol: TCP
      name: https
  selector:
    app.kubernetes.io/name: lxcfs-manager
    app.kubernetes.io/compose: manager

---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: 'lxcfs-selfsigned-issuer'
  namespace: "lxcfs"
  labels:
    app.kubernetes.io/name: lxcfs-manager
spec:
  selfSigned: {}
  
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: 'lxcfs-serving-cert'
  namespace: "lxcfs"
  labels:
    app.kubernetes.io/name: lxcfs-manager
spec:
  dnsNames:
  - 'lxcfs-webhook-service.lxcfs.svc'
  - 'lxcfs-webhook-service.lxcfs.svc.cluster.local'
  issuerRef:
    kind: Issuer
    name: 'lxcfs-selfsigned-issuer'
  secretName: 'lxcfs-certificate'

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: 'lxcfs-controller-manager'
  namespace: "lxcfs"
  labels:
    app.kubernetes.io/name: lxcfs-manager
    app.kubernetes.io/compose: manager
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: lxcfs-manager
      app.kubernetes.io/compose: manager
  template:
    metadata:
      annotations:
        {}
      labels:
        app.kubernetes.io/name: lxcfs-manager
        app.kubernetes.io/compose: manager
    spec:
      serviceAccountName: lxcfs-manager-sa
      imagePullSecrets:
        - name: lxcfs-image-pull-secrets
      containers:
      - name: manager
        args:
        - --lxcfs-path=/var/lib/lxcfs
        - --v=4
        - --leader-election=true
        - --leader-election-namespace=aipaas-system
        - --leader-election-id=lxcfs-on-kubernetes-leader-election
        image: ghcr.io/cndoit18/lxcfs-manager:v0.1.4
        imagePullPolicy: "IfNotPresent"
        ports:
        - containerPort: 9443
          name: webhook-server
          protocol: TCP
        resources:
          limits:
            cpu: 500m
            memory: 300Mi
          requests:
            cpu: 300m
            memory: 200Mi
        volumeMounts:
        - mountPath: /tmp/k8s-webhook-server/serving-certs
          name: cert
          readOnly: true
      terminationGracePeriodSeconds: 10
      volumes:
      - name: cert
        secret:
          defaultMode: 420
          secretName: 'lxcfs-certificate'

```

创建 webhook，可以用于对资源创建进行拦截和注入处理，可以借助它优雅地完成对 lxcfs 文件的自动化挂载

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  annotations:
    cert-manager.io/inject-ca-from: 'lxcfs/lxcfs-serving-cert'
  name: 'lxcfs-mutating-webhook-configuration'
webhooks:
- name: club.cndoit18.lxcfs
  namespaceSelector:
    matchLabels:
      mount-lxcfs: enabled
  admissionReviewVersions:
  - v1
  clientConfig:
    service:
      name: 'lxcfs-webhook-service'
      namespace: "lxcfs"
      path: /mount-lxcfs
  failurePolicy: Ignore
  rules:
  - apiGroups:
    - ""
    apiVersions:
    - v1
    operations:
    - CREATE
    resources:
    - pods
  sideEffects: NoneOnDryRun

```

给指定的命名空间加上 label

```bash
kubectl label namespace default mount-lxcfs=enabled
```

创建一个测试 pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-tools
  namespace: default
spec:
  volumes:
    - hostPath:
        path: /mnt/beegfs/quant-data
        type: DirectoryOrCreate
      name: beegfs-test
  containers:
  - name: demo
    image: docker.io/rockylinux/rockylinux:9.1.20221123
    resources:
      requests:
        cpu: "1"
        memory: "2048Mi"
      limits:
        cpu: "1"
        memory: "2048Mi"
    command: ["sh"]
    args: ["-c", "sleep 1000d"]
    volumeMounts:
      - mountPath: /data
        name: beegfs-test

```

安装工具

```bash
dnf install -y epel-release
dnf install -y procps-ng htop
```

可以看到 `free` 命令返回的 total memory 就是我们设置的容器资源容量

```bash
[root@debug-tools /]# free -m
               total        used        free      shared  buff/cache   available
Mem:            2048           4        1980           0          62        2043
Swap:              0           0           0
```

可以检查上述 Pod 的配置，果然相关的 procfs 文件都已经挂载正确

```bash
> kubectl describe pod -n default debug-tools

...
Volumes:
  kube-api-access-qr5vn:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
  lxcfs-proc-cpuinfo:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/proc/cpuinfo
    HostPathType:
  lxcfs-proc-diskstats:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/proc/diskstats
    HostPathType:
  lxcfs-proc-loadavg:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/proc/loadavg
    HostPathType:
  lxcfs-proc-meminfo:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/proc/meminfo
    HostPathType:
  lxcfs-proc-stat:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/proc/stat
    HostPathType:
  lxcfs-proc-swaps:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/proc/swaps
    HostPathType:
  lxcfs-proc-uptime:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/proc/uptime
    HostPathType:
  lxcfs-sys-devices-system-cpu:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/sys/devices/system/cpu
    HostPathType:
  lxcfs-sys-devices-system-cpu-online:
    Type:          HostPath (bare host directory volume)
    Path:          /var/lib/lxcfs/sys/devices/system/cpu/online
    HostPathType:
```

故障恢复，如何自动 remount？ 如果 lxcfs 进程重启了，那么容器里的 `/proc/cpuinfo` 等等都会报`transport connected failed` 这个是因为 /var/lib/lxcfs 会删除再重建，inode 变了

共享 mount 事件，重新给容器挂载

- https://github.com/alibaba/pouch/issues/140
- https://github.com/lxc/lxcfs/issues/193
