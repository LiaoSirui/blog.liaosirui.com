官方文档：

- filter-pods：<https://github.com/kubernetes-sigs/descheduler#filter-pods>

在驱逐 Pods 的时候，有时并不需要所有 Pods 都被驱逐，`descheduler` 提供了两种主要的方式进行过滤：命名空间过滤和优先级过滤。

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



## 优先级过滤

