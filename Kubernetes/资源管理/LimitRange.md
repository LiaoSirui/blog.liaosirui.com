## LimitRange 介绍

### 背景

在默认情况下，Kubernetes 不会对 Pod 做 CPU 和内存资源限制，即 Kubernetes 系统中任何 Pod 都可以使用其所在节点的所有可用的 CPU 和内存

通过配置 Pod 的计算资源 Requests 和 Limits，我们可以限制 Pod 的资源使用，配置最高要求和最低要求

但对于 Kubernetes 集群管理员而言，为每一个 Pod 配置 Requests 和 Limits 是麻烦的，同时维护特别的不方便。需要考虑如何确保一个 Pod 不会垄断命名空间内所有可用的资源

更多时候，我们需要对集群内 Requests 和 Limits 的配置做一个全局限制

这里就要用到 Limitrange，LimitRange 用来限制命名空间内适用的对象类别 (例如 Pod 或 PersistentVolumeClaim) 指定的资源分配量 (限制和请求) 的一个策略对象，对 Pod 和容器的 Requests 和 Limits 配置做进一步做出限制

### LimitRange 可以做什么

- 在一个命名空间中实施对每个 Pod 或 Container 最小和最大的资源使用量的限制
- 在一个命名空间中实施对每个 PersistentVolumeClaim 能申请的最小和最大的存储空间大小的限制
- 在一个命名空间中实施对一种资源的 申请值和限制值 的 比值的控制
- 设置一个命名空间中对计算资源的默认申请 / 限制值，并且自动的在运行时注入到多个 Container 中
- 当某命名空间中有一个 LimitRange 对象时，会在该命名空间中实施 LimitRange 限制

## 资源限制和请求的约束

首先，LimitRanger 准入控制器对所有没有设置计算资源需求的所有 Pod (及其容器) 设置默认请求值与限制值，也就是 (limits 和 Request) 

其次，LimitRange 跟踪其使用量 以保证没有超出命名空间中存在的任意 LimitRange 所定义的最小、最大资源使用量以及使用量比值

若尝试创建或更新的对象 (Pod 和 PersistentVolumeClaim) 违反了 LimitRange 的约束， 向 API 服务器的请求会失败，并返回 HTTP 状态码 403 Forbidden 以及描述哪一项约束被违反的消息

若在命名空间中添加 LimitRange 启用了对 cpu 和 memory 等计算相关资源的限制 (Max，Min)， 必须指定这些值的请求使用量 requests 与限制使用量 limits, 否则，系统将会拒绝创建 Pod, 除非在 LimitRange 定义默认的 ( limits 和 requests )

> LimitRange 的验证仅在 Pod 准入阶段进行，不对正在运行的 Pod 进行验证，如果添加或修改 LimitRange，命名空间中已存在的 Pod 将继续不变
>
> 如果命名空间中存在两个或更多 LimitRange 对象，应用哪个默认值是不确定的

### 创建 LimitRange 对象

将 LimitsRange 应用到一个 Kubernetes 的命名空间中，需要先定义一个 LimitRange ，定义最大及最小范围、Requests 和 Limits 的 默认值、Limits 与 Requests 的最大比例上限等

创建一个命名空间

```bash
kubectl create ns limitrange-example
```

编写一个 LimitRagne

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-constraint
  namespace: limitrange-example
spec:
  limits:
  - type: Pod
    min:
      cpu: 200m
      memory: 6Mi
    max:
      cpu: "4"
      memory: 2Gi
    maxLimitRequestRatio:
      cpu: 3
      memory: 2
  - type: Container
    min:
      cpu: 100m # 0.1 C
      memory: 3Mi
    max:
      cpu: "2"
      memory: 1Gi
    defaultRequest:
      cpu: 200m
      memory: 100Mi
    default:
      cpu: 300m
      memory: 200Mi
    maxLimitRequestRatio:
      cpu: 5
      memory: 4
  - type: PersistentVolumeClaim
    min:
      storage: 1Gi
    max:
      storage: 1Ti

```

上述文件对应的限制为：

![image-20221216175102615](.assets/image-20221216175102615.png)

使用命令可以查看：

```bash
> kubectl describe limitRange resource-constraint -n limitrange-example

Name:                  resource-constraint
Namespace:             limitrange-example
Type                   Resource  Min   Max  Default Request  Default Limit  Max Limit/Request Ratio
----                   --------  ---   ---  ---------------  -------------  -----------------------
Pod                    cpu       200m  4    -                -              3
Pod                    memory    6Mi   2Gi  -                -              2
Container              cpu       100m  2    200m             300m           5
Container              memory    3Mi   1Gi  100Mi            200Mi          4
PersistentVolumeClaim  storage   1Gi   1Ti  -                -              -
```

在定义 LimitRange 时，当 LimitRange 中 container 类型限制没有指定 Limits 和 Requests 的默认值时，会使用 Max 作为默认值

### 参数释义

```bash
kubectl explain LimitRange.spec.limits.type
```

官方文档对 `LimitRange.spec.limits.type` 的描述如下：

```bash
FIELDS:
   default	<map[string]string>
     Default resource requirement limit value by resource name if resource limit
     is omitted.

   defaultRequest	<map[string]string>
     DefaultRequest is the default resource requirement request value by
     resource name if resource request is omitted.

   max	<map[string]string>
     Max usage constraints on this kind by resource name.

   maxLimitRequestRatio	<map[string]string>
     MaxLimitRequestRatio if specified, the named resource must have a request
     and limit that are both non-zero where limit divided by request is less
     than or equal to the enumerated value; this represents the max burst for
     the named resource.

   min	<map[string]string>
     Min usage constraints on this kind by resource name.

   type	<string> -required-
     Type of resource that this limit applies to.
```

### 容器

对于同一资源类型，这 4 个参数必须满足以下关系：`Min ≤ Default Request ≤ Default Limit ≤ Max`

对于约束

```bash
> kubectl describe limitRange resource-constraint -n limitrange-example

Type                   Resource  Min   Max  Default Request  Default Limit  Max Limit/Request Ratio
----                   --------  ---   ---  ---------------  -------------  -----------------------
Container              cpu       100m  2    200m             300m           5
Container              memory    3Mi   1Gi  100Mi            200Mi          4
```

必须符合以下：

- Container 的 Min (100m 和 3Mi)是 Pod 中所有容器的 Requests 值下限,即创建 pod 等资源时，申请值 Requests 的值不能低于 Min 的值，否则提示违反约束
- Container 的 Max (2C 和 1Gi)是 Pod 中所有容器的 Limits 值上限，同理， 限制 资源使用 Limits 不能超过 2000m、 1Gi( 二进制的字节表示) ；
- Container 的 Default Request (200m 和 100Mi)是 Pod 中所有未指定 Requests 值的容器的默认 Requests 值；
- Container 的 Default Limit (300m 和 200Mi)是 Pod 中所有未指定 Limits 值的容器的默认 Limits 值。
- Container 的 Max Limit/Requests Ratio (5 和 4)限制了 Pod 中所有容器的 Limits 值与 Requests 值的比例上限；

当创建的容器未指定 Requests 值或者 Limits 值时，将使用 Container 的 `Default Request` 值或者 `Default Limit` 值

例如：

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod-demo
  name: pod-demo
  namespace: limitrange-example
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: pod-demo
    resources:
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

没有指定时，会使用默认值

```bash
kubectl get pods pod-demo -n limitrange-example -o json | jq '.spec.containers[0].resources'
```

得到输出

```json
{
  "limits": {
    "cpu": "300m",
    "memory": "200Mi"
  },
  "requests": {
    "cpu": "200m",
    "memory": "100Mi"
  }
}
```

### Pod

Pod 和 Container 都可以设置 Min、Max 和 Max Limit/Requests Ratio 参数

不同的是 Container 还可以设置 Default Request 和 Default Limit 参数，而 Pod 不能设置 Default Request 和 Default Limit 参数

这里需要注意的是容器的总和:

- Pod 的 Min(200m 和 6Mi)是 Pod 中所有容器的 Requests 值的 `总和` 下限；
- Pod 的 Max(4 和 2Gi)是 Pod 中所有容器的 Limits 值的 `总和` 上限；
- Pod 的 Max Limit/Requests Ratio (3 和 2)限制了 Pod 中所有容器的 Limits 值总和与 Requests 值总和的比例上限

对于约束

```bash
> kubectl describe limitRange resource-constraint -n limitrange-example

Type                   Resource  Min   Max  Default Request  Default Limit  Max Limit/Request Ratio
----                   --------  ---   ---  ---------------  -------------  -----------------------
Pod                    cpu       200m  4    -                -              3
Pod                    memory    6Mi   2Gi  -                -              2

```

对于任意一个 Pod 而言，该 Pod 中所有容器的 Requests 总和必须大于或等于 6MiB，而且所有容器的 Limits 总和必须小于或等于 2GiB；

同样，所有容器的 CPU Requests 总和必须大于或等于 200m，而且所有容器的 CPU Limits 总和必须小于或等于 4

- Pod 里任何容器的 Limits 与 Requests 的比例都不能超过 `Container 的 Max Limit/Requests Ratio`
- Pod 里所有容器的 Limits 总和与 Requests 的总和的比例不能超过 `Pod 的 Max Limit/Requests Ratio`

## 准入检查 Demo

使用限制：

```bash
> kubectl describe limitRange resource-constraint -n limitrange-example

Type                   Resource  Min   Max  Default Request  Default Limit  Max Limit/Request Ratio
----                   --------  ---   ---  ---------------  -------------  -----------------------
Pod                    cpu       200m  4    -                -              3
Pod                    memory    6Mi   2Gi  -                -              2
Container              cpu       100m  2    200m             300m           5
Container              memory    3Mi   1Gi  100Mi            200Mi          4
```

当容器中定义的申请的最小 request 值 大于 LimitRange 默认定义的限制资源 limits 的值时，是无法调度的

没有指定 limits 所以使用默认的 limits 值，但是默认的 limits 值 300m 小于当前容器的值

申请的最小值大于默认的最大值，显然不符合逻辑，所以 pod 无法调度创建

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-demo
  name: pod-demo
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: pod-demo
    resources:
      requests:
        cpu:  500m
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

报错如下：

```bash
Error "Invalid value: "500m": must be less than or equal to cpu limit" for field "spec.containers[0].resources.requests".
```

如果同时设置了 `requests` 和 `limits`，那么 `limits` 不使用默认值

新 Pod 会被成功调度，但是这里需要注意的是， requests 和 limits 要符合 LimitRange 中 容器的 MAX,MIN 配置

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-demo
  name: pod-demo
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: pod-demo
    resources:
      requests:
        cpu:  500m
      limits:
        cpu: 800m
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

`Max ` 限制，当 Limits 大于 Max 值时，Pod 不会创建成功，定义如下一个 LimiRange 的资源对象

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-demo
  name: pod-demo
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: pod-demo
    resources:
      limits:
        cpu: '3'
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

报错如下：

```bash
pods "pod-demo" is forbidden: maximum cpu usage per Container is 2, but limit is 3
```

**`Max Limit/Request Ratio` 限制** ，当 `Limit/Request` 的比值 超过 `Max Limit/Request Ratio` 时调度失败

可以看到 限制 pod 中 cpu 的 `Max Limit/Request Ratio` 比值 为 3，即 Requests 是 Limits 的 3 倍，最大和小之间最多可以相差 2 个单位

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-demo
  name: pod-demo
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: pod-demo
    resources:
      limits:
        cpu: '1600m'
      requests:
        cpu: '400m'
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

报错如下
```bash
pods "pod-demo" is forbidden: cpu max limit to request ratio per Pod is 3, but provided ratio is 4.000000
```

https://mp.weixin.qq.com/s/_a-OPwN-jCn_hjs_wM78zA

## 资源约束 Demo

