## 为什么需要二次调度

Kubernetes 调度器的作用是将 Pod 绑定到某一个最佳的节点。为了实现这一功能，调度器会需要进行一系列的筛选和打分。

Kubernetes 的调度是基于 Request，但是每个 Pod 的实际使用值是动态变化的。经过一段时间的运行之后，节点的负载并不均衡。一些节点负载过高、而有些节点使用率很低。

因此，我们需要一种机制，让 Pod 能更健康、更均衡的动态分布在集群的节点上，而不是一次性调度之后就固定在某一台主机上。

## Descheduler 简介

从 kube-scheduler 的角度来看，它是通过一系列算法计算出最佳节点运行 Pod，当出现新的 Pod 进行调度时，调度程序会根据其当时对 Kubernetes 集群的资源描述做出最佳调度决定，但是 Kubernetes 集群是非常动态的，由于整个集群范围内的变化，比如一个节点为了维护，我们先执行了驱逐操作，这个节点上的所有 Pod 会被驱逐到其他节点去，但是当我们维护完成后，之前的 Pod 并不会自动回到该节点上来，因为 Pod 一旦被绑定了节点是不会触发重新调度的，由于这些变化，Kubernetes 集群在一段时间内就可能会出现不均衡的状态，所以需要均衡器来重新平衡集群。

当然我们可以去手动做一些集群的平衡，比如手动去删掉某些 Pod，触发重新调度就可以了，但是显然这是一个繁琐的过程，也不是解决问题的方式。

<img src=".assets/descheduler-stacked-color.png" alt="descheduler" style="zoom:25%;" />

为了解决实际运行中集群资源无法充分利用或浪费的问题，可以使用 descheduler 组件对集群的 Pod 进行调度优化，descheduler 可以根据一些规则和配置策略来帮助我们重新平衡集群状态，其核心原理是根据其策略配置找到可以被移除的 Pod 并驱逐它们，其本身并不会进行调度被驱逐的 Pod，而是依靠默认的调度器来实现，目前支持的策略有：

- [RemoveDuplicates](https://github.com/kubernetes-sigs/descheduler#removeduplicates)
- [LowNodeUtilization](https://github.com/kubernetes-sigs/descheduler#lownodeutilization)
- [HighNodeUtilization](https://github.com/kubernetes-sigs/descheduler#highnodeutilization)
- [RemovePodsViolatingInterPodAntiAffinity](https://github.com/kubernetes-sigs/descheduler#removepodsviolatinginterpodantiaffinity)
- [RemovePodsViolatingNodeAffinity](https://github.com/kubernetes-sigs/descheduler#removepodsviolatingnodeaffinity)
- [RemovePodsViolatingNodeTaints](https://github.com/kubernetes-sigs/descheduler#removepodsviolatingnodetaints)
- [RemovePodsViolatingTopologySpreadConstraint](https://github.com/kubernetes-sigs/descheduler#removepodsviolatingtopologyspreadconstraint)
- [RemovePodsHavingTooManyRestarts](https://github.com/kubernetes-sigs/descheduler#removepodshavingtoomanyrestarts)
- [PodLifeTime](https://github.com/kubernetes-sigs/descheduler#podlifetime)
- [RemoveFailedPods](https://github.com/kubernetes-sigs/descheduler#removefailedpods)

详见：[调度策略.md](调度策略.md)

## 安装

`descheduler` 可以以 `Job`、`CronJob` 或者 `Deployment` 的形式运行在 k8s 集群内，同样我们可以使用 Helm Chart 来安装 `descheduler`：

```bash
helm repo add descheduler https://kubernetes-sigs.github.io/descheduler/
```

通过 Helm Chart 我们可以配置 `descheduler` 以 `CronJob` 或者 `Deployment` 方式运行，默认情况下 `descheduler` 会以一个 `critical pod` 运行，以避免被自己或者 kubelet 驱逐了，需要确保集群中有 `system-cluster-critical` 这个 Priorityclass：

```bash
kubectl get priorityclass system-cluster-critical
```

使用 Helm Chart 安装默认情况下会以 `CronJob` 的形式运行，执行周期为 `schedule: "*/2 * * * *"`，这样每隔两分钟会执行一次 `descheduler` 任务，默认的配置策略如下所示：

## 注意事项

当使用 descheduler 驱除Pods的时候，需要注意以下几点：

- 关键性 Pod 不会被驱逐，比如 `priorityClassName` 设置为 `system-cluster-critical` 或 `system-node-critical` 的 Pod
- 不属于 RS、Deployment 或 Job 管理的 Pods 不会被驱逐
- DaemonSet 创建的 Pods 不会被驱逐
- 使用 `LocalStorage` 的 Pod 不会被驱逐，除非设置 `evictLocalStoragePods: true`
- 具有 PVC 的 Pods 不会被驱逐，除非设置 `ignorePvcPods: true`
- 在 `LowNodeUtilization` 和 `RemovePodsViolatingInterPodAntiAffinity` 策略下，Pods 按优先级从低到高进行驱逐，如果优先级相同，`Besteffort` 类型的 Pod 要先于 `Burstable` 和 `Guaranteed` 类型被驱逐
- `annotations` 中带有 `descheduler.alpha.kubernetes.io/evict` 字段的 Pod 都可以被驱逐，该注释用于覆盖阻止驱逐的检查，用户可以选择驱逐哪个Pods
- 如果 Pods 驱逐失败，可以设置 `--v=4` 从 `descheduler` 日志中查找原因，如果驱逐违反 PDB 约束，则不会驱逐这类 Pods
