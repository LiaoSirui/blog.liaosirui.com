## DownwardAPI 简介

`DownwardAPI`，它不是为了存放容器的数据也不是用来进行容器和宿主机的数据交换的，而是让 Pod 里的容器能够直接获取到这个 Pod 对象本身的一些信息。

官方：

- 文档：<https://kubernetes.io/docs/concepts/workloads/pods/downward-api/>

目前 `Downward API` 提供了两种方式用于将 Pod 的信息注入到容器内部：

- 环境变量：用于单个变量，可以将 Pod 信息和容器信息直接注入容器内部
- Volume 挂载：将 Pod 信息生成为文件，直接挂载到容器内部中去

通过环境变量获取这些信息的方式，不具备自动更新的能力。所以，一般情况下，都建议使用 Volume 文件的方式获取这些信息，因为通过 Volume 的方式挂载的文件在 Pod 中会进行热更新。

需要注意的是，`Downward API` 能够获取到的信息，一定是 Pod 里的容器进程启动之前就能够确定下来的信息。而如果你想要获取 Pod 容器运行后才会出现的信息，比如，容器进程的 PID，那就肯定不能使用 `Downward API` 了，而应该考虑在 Pod 里定义一个 sidecar 容器来获取了。

## 使用

valueFrom 字段内嵌 filedRef 字段引用的信息包括如下：

- `metadata.name`：pod 对象的名称
- `metadata.namespace`：pod 对象隶属的名称空间
- `metadata.uid`：pod 对象的 UID
- `metadata.lables['<KEY>']`：pod 对象标签中的指定键的值，例如 `metadata.labels['mylable']`
- `metadata.annotations['<KEY>']`：pod 对象注解信息中的指定键的值

可通过环境变量引用，但不能通过卷引用的信息有如下几个

- `status.podIP`：pod 对象的 IP 地址
- `status.hostIP`：节点 IP 地址
- `spec.nodeName`：节点名称
- `spec.serviceAccountName`：pod 对象使用的 ServiceAccount 资源名称

容器上的计算资源和资源限制相关的信息，以及临时存储资源需求和资源限制相关的信息可通过容器规范中的 resourceFieldRef 字段引用，相关字段包括

- `requests.cpu`
- `limits.cpu`
- `requests.memory`
- `limits.memory`
- `requests.hugepages-*`
- `limits.hugepages-*`
- `requests.ephemeral-storage`
- `limits.ephemeral-storage`

downwardAPI 存储卷能够以文件方式向容器注入元数据，将配置的字段数据映射为文件并可通过容器中的挂载点访问。事实上通过环境变量方式注入的元数据信息也都可以使用存储卷方式进行信息暴露，但除此之外，我们还能够在 downwardAPI 存储卷中使用 fieldRef 引用下面两个数据源。

- `metadata.lables`：pod 对象的所有标签信息，每行一个，格式为 `label-key="escaped-label-value"`
- `metadata.annotations`：pod 对象的所有注解信息，每行一个，格式为 `annotation-key="escaped-annotation-value"`

### 环境变量

通过 `Downward API` 来将 Pod 的 IP、名称以及所对应的 namespace 注入到容器的环境变量中去，然后在容器中打印全部的环境变量来进行验证，对应资源清单文件如下：

```yaml
# env-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-pod
  labels:
    app: demo-app
spec:
  containers:
  - name: env-pod
    resources:
      requests:
        memory: "32Mi"
        cpu: "250m"
      limits:
        memory: "64Mi"
        cpu: "500m"
    image: busybox
    command: ["/bin/sh", "-c", "env | grep POD_"]
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: POD_APP_LABEL
      valueFrom:
        fieldRef:
          fieldPath: metadata.labels['app']
    - name: POD_CPU_LIMIT
      valueFrom:
        resourceFieldRef:
          resource: limits.cpu
    - name: POD_MEM_REQUEST
      valueFrom:
        resourceFieldRef:
          resource: requests.memory
          divisor: 1Mi

```

进入 Pod 后查看环境变量

```bash
POD_IP=10.4.1.60
POD_CPU_LIMIT=1
POD_APP_LABEL=demo-app
POD_MEM_REQUEST=32
POD_NAME=env-pod
POD_NAMESPACE=default
```

该示例最后一个环境变量的定义中还额外指定一个 `divisor` 字段，它用于引用的值指定一个除数，以对引用的数据进行单位换算。

- CPU 资源的 divisor 字段默认值为 1，它表示为 1 个核心，相除的结果不足 1 个单位则向上调整，它的另一个可用单位为 1m，即标识 1 个微核心。

- 内存资源的divisor字段默认值也是1，它指 1 个字节，此时 32MiB 的内存资源则要换算为 33553321 输出。其它可用的单位还有 1KiB、1MiB、1GiB 等，于是将 `divisor` 字段的值设置为 1MiB 时，32MiB 的内存资源换算的结果即为 32。 

### Volume 挂载

`Downward API`除了提供环境变量的方式外，还提供了通过 Volume 挂载的方式去获取 Pod 的基本信息。

接下来通过 `Downward API` 将 Pod 的 Label、Annotation 等信息通过 Volume 挂载到容器的某个文件中去，然后在容器中打印出该文件的值来验证，对应的资源清单文件如下所示：

```yaml
# volume-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-pod
  labels:
    app: demo-app
  annotations:
    build: test
spec:
  volumes:
  - name: pod-info
    downwardAPI:
      items:
      - path: labels
        fieldRef:
          fieldPath: metadata.labels
      - path: annotations
        fieldRef:
          fieldPath: metadata.annotations
      - path: pod_name
        fieldRef:
          fieldPath: metadata.name
  containers:
  - name: volume-pod
    image: busybox
    resources:
      requests:
        memory: "32Mi"
        cpu: "250m"
      limits:
        memory: "64Mi"
        cpu: "500m"
    command: ["/bin/sh", "-c", "tail -100 /etc/pod-info/*"]
    volumeMounts:
    - name: pod-info
      mountPath: /etc/pod-info

```

输出如下：

```
==> /etc/pod-info/annotations <==
build="test"
kubernetes.io/config.seen="2023-02-21T16:13:06.825394401+08:00"
kubernetes.io/config.source="api"
==> /etc/pod-info/labels <==
app="demo-app"
==> /etc/pod-info/pod_name <==
volume-pod
```

## 示例

Golang 程序的常用变量：

```yaml
- name: GOMEMLIMIT
  valueFrom:
    resourceFieldRef:
      divisor: "0"
      resource: limits.memory
- name: GOMAXPROCS
  valueFrom:
    resourceFieldRef:
      divisor: "0"
      resource: limits.cpu
```

