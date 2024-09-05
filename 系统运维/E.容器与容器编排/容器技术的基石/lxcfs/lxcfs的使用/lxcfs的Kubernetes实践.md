## lxcfs 的 Kubernetes 实践

![img](.assets/d21cc9032174006d97a770ca4396a533.png)

### 启用 fuse 模块

先确保节点都开启 fuse 内核模块，并写入文件

```bash
cat << EOF > /etc/modules-load.d/fuse.conf
fuse
EOF
```

### rbac

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

### 使用 DaemonSet  启动 lxcfs

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
        - --enable-loadavg
        - -o
        - allow_other,nonempty
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

建议增加优先级，保证服务始终运行

```bash
```



### webhook

webhook 部署

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

### 测试

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

## 自动 remount 问题

故障恢复，如何自动 remount？ 如果 lxcfs 进程重启了，那么容器里的 `/proc/cpuinfo` 等等都会报`transport connected failed` 这个是因为 /var/lib/lxcfs 会删除再重建，inode 变了

```bash
[root@debug-tools /]# free -g 
Error: /proc must be mounted
  To mount /proc at boot you need an /etc/fstab line like:
      proc   /proc   proc    defaults
  In the meantime, run "mount proc /proc -t proc"
```

共享 mount 事件，重新给容器挂载

- ##### https://github.com/alibaba/pouch/issues/140

- https://github.com/lxc/lxcfs/issues/193

https://github.com/xigang/lxcfs-admission-webhook/blob/dev/script/container_remount_lxcfs.sh

```bash
#! /bin/bash

PATH=$PATH:/bin
LXCFS="/var/lib/lxc/lxcfs"
LXCFS_ROOT_PATH="/var/lib/lxc"

containers=$(docker ps | grep -v pause  | grep -v calico | awk '{print $1}' | grep -v CONTAINE)

#-v /var/lib/lxc/lxcfs/proc/cpuinfo:/proc/cpuinfo:rw
#-v /var/lib/lxc/lxcfs/proc/diskstats:/proc/diskstats:rw
#-v /var/lib/lxc/lxcfs/proc/meminfo:/proc/meminfo:rw
#-v /var/lib/lxc/lxcfs/proc/stat:/proc/stat:rw
#-v /var/lib/lxc/lxcfs/proc/swaps:/proc/swaps:rw
#-v /var/lib/lxc/lxcfs/proc/uptime:/proc/uptime:rw
#-v /var/lib/lxc/lxcfs/proc/loadavg:/proc/loadavg:rw
#-v /var/lib/lxc/lxcfs/sys/devices/system/cpu/online:/sys/devices/system/cpu/online:rw
for container in $containers;do
	mountpoint=$(docker inspect --format '{{ range .Mounts }}{{ if eq .Destination "/var/lib/lxc" }}{{ .Source }}{{ end }}{{ end }}' $container)
	if [ "$mountpoint" = "$LXCFS_ROOT_PATH" ];then
		echo "remount $container"
		PID=$(docker inspect --format '{{.State.Pid}}' $container)
		# mount /proc
		for file in meminfo cpuinfo loadavg stat diskstats swaps uptime;do
			echo nsenter --target $PID --mount --  mount -B "$LXCFS/proc/$file" "/proc/$file"
			nsenter --target $PID --mount --  mount -B "$LXCFS/proc/$file" "/proc/$file"
		done
		# mount /sys
		for file in online;do
			echo nsenter --target $PID --mount --  mount -B "$LXCFS/sys/devices/system/cpu/$file" "/sys/devices/system/cpu/$file"
			nsenter --target $PID --mount --  mount -B "$LXCFS/sys/devices/system/cpu/$file" "/sys/devices/system/cpu/$file"
		done 
	fi 
done
```

