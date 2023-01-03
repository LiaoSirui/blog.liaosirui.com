官方文档：

- filter-pods：<https://github.com/kubernetes-sigs/descheduler#filter-pods>

在驱逐 Pods 的时候，有时并不需要所有 Pods 都被驱逐，`descheduler` 提供了两种主要的方式进行过滤：命名空间过滤和优先级过滤

## 命名空间过滤

该策略可以配置是包含还是排除某些名称空间。可以使用该策略的有：

- `PodLifeTime`
- `RemovePodsHavingTooManyRestarts`
- `RemovePodsViolatingNodeTaints`
- `RemovePodsViolatingNodeAffinity`
- `RemovePodsViolatingInterPodAntiAffinity`
- `RemoveDuplicates`
- `RemovePodsViolatingTopologySpreadConstraint`
- `RemoveFailedPods`
- `LowNodeUtilization` and `HighNodeUtilization` (Only filtered right before eviction)

比如只驱逐某些命令空间下的 Pods，则可以使用 `include` 参数进行配置，如下所示：

```yaml
apiVersion: "descheduler/v1alpha1"
kind: "DeschedulerPolicy"
strategies:
  "PodLifeTime":
     enabled: true
     params:
        podLifeTime:
          maxPodLifeTimeSeconds: 86400
        namespaces:
          include:
          - "namespace1"
          - "namespace2"

```

又或者要排除掉某些命令空间下的 Pods，则可以使用 `exclude` 参数配置，如下所示：

```yaml
apiVersion: "descheduler/v1alpha1"
kind: "DeschedulerPolicy"
strategies:
  "PodLifeTime":
     enabled: true
     params:
        podLifeTime:
          maxPodLifeTimeSeconds: 86400
        namespaces:
          exclude:
          - "namespace1"
          - "namespace2"

```

## 优先级过滤

所有策略都可以配置优先级阈值，只有在该阈值以下的 Pod 才会被驱逐，我们可以通过设置 `thresholdPriorityClassName`（将阈值设置为指定优先级类别的值）或 `thresholdPriority`（直接设置阈值）参数来指定该阈值

默认情况下，该阈值设置为 `system-cluster-critical` 这个 PriorityClass 类的值

比如使用 `thresholdPriority`：

```yaml
apiVersion: "descheduler/v1alpha1"
kind: "DeschedulerPolicy"
strategies:
  "PodLifeTime":
     enabled: true
     params:
        podLifeTime:
          maxPodLifeTimeSeconds: 86400
        thresholdPriority: 10000

```

或者使用 `thresholdPriorityClassName` 进行过滤：

```yaml
apiVersion: "descheduler/v1alpha1"
kind: "DeschedulerPolicy"
strategies:
  "PodLifeTime":
     enabled: true
     params:
        podLifeTime:
          maxPodLifeTimeSeconds: 86400
        thresholdPriorityClassName: "priorityclass1"

```

不过需要注意不能同时配置 `thresholdPriority` 和 `thresholdPriorityClassName`

如果指定的优先级类不存在，则 descheduler 不会创建它，并且会引发错误

