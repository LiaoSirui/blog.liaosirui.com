## 为什么需要二次调度

Kubernetes 调度器的作用是将 Pod 绑定到某一个最佳的节点。为了实现这一功能，调度器会需要进行一系列的筛选和打分。

Kubernetes 的调度是基于 Request，但是每个 Pod 的实际使用值是动态变化的。经过一段时间的运行之后，节点的负载并不均衡。一些节点负载过高、而有些节点使用率很低。

因此，我们需要一种机制，让 Pod 能更健康、更均衡的动态分布在集群的节点上，而不是一次性调度之后就固定在某一台主机上。

## Descheduler 简介

从 kube-scheduler 的角度来看，它是通过一系列算法计算出最佳节点运行 Pod，当出现新的 Pod 进行调度时，调度程序会根据其当时对 Kubernetes 集群的资源描述做出最佳调度决定，但是 Kubernetes 集群是非常动态的，由于整个集群范围内的变化，比如一个节点为了维护，我们先执行了驱逐操作，这个节点上的所有 Pod 会被驱逐到其他节点去，但是当我们维护完成后，之前的 Pod 并不会自动回到该节点上来，因为 Pod 一旦被绑定了节点是不会触发重新调度的，由于这些变化，Kubernetes 集群在一段时间内就可能会出现不均衡的状态，所以需要均衡器来重新平衡集群。

当然我们可以去手动做一些集群的平衡，比如手动去删掉某些 Pod，触发重新调度就可以了，但是显然这是一个繁琐的过程，也不是解决问题的方式。

![img](.assets/descheduler-stacked-color.png)

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

## PDB

由于使用 `descheduler` 会将 Pod 驱逐进行重调度，但是如果一个服务的所有副本都被驱逐的话，则可能导致该服务不可用

如果服务本身存在单点故障，驱逐的时候肯定就会造成服务不可用了，这种情况我们强烈建议使用反亲和性和多副本来避免单点故障，但是如果服务本身就被打散在多个节点上，这些 Pod 都被驱逐的话，这个时候也会造成服务不可用了，这种情况下我们可以通过配置 `PDB（PodDisruptionBudget）` 对象来避免所有副本同时被删除，比如我们可以设置在驱逐的时候某应用最多只有一个副本不可用，则创建如下所示的资源清单即可：

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: pdb-demo
spec:
  maxUnavailable: 1  # 设置最多不可用的副本数量，或者使用 minAvailable，可以使用整数或百分比
  selector:
    matchLabels:    # 匹配Pod标签
      app: demo

```

关于 PDB 的更多详细信息可以查看官方文档：https://kubernetes.io/docs/tasks/run-application/configure-pdb/

所以如果我们使用 `descheduler` 来重新平衡集群状态，那么我们强烈建议给应用创建一个对应的 `PodDisruptionBudget` 对象进行保护

## descheduler 的几种运行方式

https://mp.weixin.qq.com/s/Q5VrLxR3IzvlsYquwVzDOw

`descheduler` 可以以 `Job`、`CronJob` 或者 `Deployment` 的形式运行在 k8s 集群内

descheduler 是 kubernetes-sigs 下的子项目，先将代码克隆到本地，进入项目目录:

```bash
git clone https://github.com/kubernetes-sigs/descheduler

git checkout v0.25.1

cd descheduler
```

如果运行环境无法拉取 gcr 的镜像，可以将 `k8s.gcr.io/descheduler/descheduler` 替换为 `k8simage/descheduler`

### 一次性 Job

```bash
kubectl create -f kubernetes/base/rbac.yaml
kubectl create -f kubernetes/base/configmap.yaml
kubectl create -f kubernetes/job/job.yaml
```

### 定时任务 CronJob

默认是 `*/2 * * * *` 每隔 2 分钟执行一次

```bash
kubectl create -f kubernetes/base/rbac.yaml
kubectl create -f kubernetes/base/configmap.yaml
kubectl create -f kubernetes/cronjob/cronjob.yaml
```

### 常驻任务 Deployment

默认是 `--descheduling-interval 5m` 每隔 5 分钟执行一次

```bash
kubectl create -f kubernetes/base/rbac.yaml
kubectl create -f kubernetes/base/configmap.yaml
kubectl create -f kubernetes/deployment/deployment.yaml
```

## CLI 命令行

编译 cli

```bash
make
```

将文件移动到 PATH 目录下

```bash
mv _output/bin/descheduler /usr/local/bin/
```

先在本地生成策略文件，然后执行 `descheduler` 命令

```bash
descheduler -v=3 --evict-local-storage-pods --policy-config-file=pod-life-time.yml
```

descheduler 有 `--help` 参数可以查看相关帮助文档。

```bash
descheduler --help
The descheduler evicts pods which may be bound to less desired nodes

Usage:
  descheduler [flags]
  descheduler [command]

Available Commands:
  completion  generate the autocompletion script for the specified shell
  help        Help about any command
  version     Version of descheduler
```

## 安装

同样可以使用 Helm Chart 来安装 `descheduler`：

```bash
helm repo add descheduler https://kubernetes-sigs.github.io/descheduler/
```

通过 Helm Chart 我们可以配置 `descheduler` 以 `CronJob` 或者 `Deployment` 方式运行，默认情况下 `descheduler` 会以一个 `critical pod` 运行，以避免被自己或者 kubelet 驱逐了，需要确保集群中有 `system-cluster-critical` 这个 Priorityclass：

```bash
kubectl get priorityclass system-cluster-critical
```

使用 Helm Chart 安装默认情况下会以 `CronJob` 的形式运行，执行周期为 `schedule: "*/2 * * * *"`，这样每隔两分钟会执行一次 `descheduler` 任务，默认的配置策略如下所示：

## 测试调度效果

- cordon 部分节点，仅允许一个节点参与调度

```bash
kubectl get node

NAME    STATUS                     ROLES                         AGE   VERSION
node2   Ready,SchedulingDisabled   worker                        69d   v1.23.0
node3   Ready                      control-plane,master,worker   85d   v1.23.0
node4   Ready,SchedulingDisabled   worker                        69d   v1.23.0
node5   Ready,SchedulingDisabled   worker                        85d   v1.23.0
```

- 运行一个 40 副本数的应用

可以观察到这个应用的副本全都在 node3 节点上。

```bash
kubectl get pod -o wide|grep nginx-645dcf64c8|grep node3|wc -l 
      40
```

- 集群中部署 descheduler

这里使用的是 Deployment 方式。

```bash
kubectl -n kube-system get pod |grep descheduler

descheduler-8446895b76-7vq4q               1/1     Running     0              6m9s
```

- 放开节点调度

调度前，所有副本都集中在 node3 节点

```bash
kubectl top node 

NAME    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
node2   218m         6%     3013Mi          43%       
node3   527m         14%    4430Mi          62%       
node4   168m         4%     2027Mi          28%       
node5   93m          15%    785Mi           63%       
```

放开节点调度

```bash
kubectl get node      

NAME    STATUS   ROLES                         AGE   VERSION
node2   Ready    worker                        69d   v1.23.0
node3   Ready    control-plane,master,worker   85d   v1.23.0
node4   Ready    worker                        69d   v1.23.0
node5   Ready    worker                        85d   v1.23.0
```

- 查看 descheduler 相关日志

当满足定时要求时，descheduler 就会开始根据策略驱逐 Pod。

```bash
kubectl -n kube-system logs descheduler-8446895b76-7vq4q  -f

I0610 10:00:26.673573       1 event.go:294] "Event occurred" object="default/nginx-645dcf64c8-z9n8k" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerLowNodeUtilization"
I0610 10:00:26.798506       1 evictions.go:163] "Evicted pod" pod="default/nginx-645dcf64c8-2qm5c" reason="RemoveDuplicatePods" strategy="RemoveDuplicatePods" node="node3"
I0610 10:00:26.799245       1 event.go:294] "Event occurred" object="default/nginx-645dcf64c8-2qm5c" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerRemoveDuplicatePods"
I0610 10:00:26.893932       1 evictions.go:163] "Evicted pod" pod="default/nginx-645dcf64c8-9ps2g" reason="RemoveDuplicatePods" strategy="RemoveDuplicatePods" node="node3"
I0610 10:00:26.894540       1 event.go:294] "Event occurred" object="default/nginx-645dcf64c8-9ps2g" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerRemoveDuplicatePods"
I0610 10:00:26.992410       1 evictions.go:163] "Evicted pod" pod="default/nginx-645dcf64c8-kt7zt" reason="RemoveDuplicatePods" strategy="RemoveDuplicatePods" node="node3"
I0610 10:00:26.993064       1 event.go:294] "Event occurred" object="default/nginx-645dcf64c8-kt7zt" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerRemoveDuplicatePods"
I0610 10:00:27.122106       1 evictions.go:163] "Evicted pod" pod="default/nginx-645dcf64c8-lk9pd" reason="RemoveDuplicatePods" strategy="RemoveDuplicatePods" node="node3"
I0610 10:00:27.122776       1 event.go:294] "Event occurred" object="default/nginx-645dcf64c8-lk9pd" fieldPath="" kind="Pod" apiVersion="v1" type="Normal" reason="Descheduled" message="pod evicted by sigs.k8s.io/deschedulerRemoveDuplicatePods"
I0610 10:00:27.225304       1 evictions.go:163] "Evicted pod" pod="default/nginx-645dcf64c8-mztjb" reason="RemoveDuplicatePods" strategy="RemoveDuplicatePods" node="node3"
```

- 二次调度之后的 Pod 分布

节点的负载情况，node3 下降，其他节点都上升了一些。

```bash
kubectl top node 

NAME    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
node2   300m         8%     3158Mi          45%       
node3   450m         12%    3991Mi          56%       
node4   190m         5%     2331Mi          32%       
node5   111m         18%    910Mi           73%  
```

Pod 在节点上的分布，这是在没有配置任何亲和性、反亲和性的场景下。

| 节点  | Pod数量(共40副本) |
| :---- | :---------------- |
| node2 | 11                |
| node3 | 10                |
| node4 | 11                |
| node5 | 8                 |

Pod 的数量分布非常均衡，其中 node2-4 虚拟机配置一样，node5 配置较低。如下图是整个过程的示意图：

![img](.assets/V6icG3TMUkiazNVnPWYNnd7Z3VeBqM8T8dyMotKSsxT67TfUFIJQ6k9dyfhUU2XYfypicazfC3EnA3TiaYEB1OFY4Q.png)

## 其他

### 有哪些不足

- 基于 Request 计算节点负载并不能反映真实情况

在源码 <https://github.com/kubernetes-sigs/descheduler/blob/v0.25.1/pkg/descheduler/node/node.go#L255> 中可以看到，descheduler 是通过合计 Node 上 Pod 的 Request 值来计算使用情况的

```go
// NodeUtilization returns the resources requested by the given pods. Only resources supplied in the resourceNames parameter are calculated.
func NodeUtilization(pods []*v1.Pod, resourceNames []v1.ResourceName) map[v1.ResourceName]*resource.Quantity {
	totalReqs := map[v1.ResourceName]*resource.Quantity{
		v1.ResourceCPU:    resource.NewMilliQuantity(0, resource.DecimalSI),
		v1.ResourceMemory: resource.NewQuantity(0, resource.BinarySI),
		v1.ResourcePods:   resource.NewQuantity(int64(len(pods)), resource.DecimalSI),
	}
	for _, name := range resourceNames {
		if !IsBasicResource(name) {
			totalReqs[name] = resource.NewQuantity(0, resource.DecimalSI)
		}
	}

	for _, pod := range pods {
		req, _ := utils.PodRequestsAndLimits(pod)
		for _, name := range resourceNames {
			quantity, ok := req[name]
			if ok && name != v1.ResourcePods {
				// As Quantity.Add says: Add adds the provided y quantity to the current value. If the current value is zero,
				// the format of the quantity will be updated to the format of y.
				totalReqs[name].Add(quantity)
			}
		}
	}

	return totalReqs
}
```

这种方式可能并不太适合真实场景

如果能直接拿 metrics-server 或者 Prometheus 中的数据，会更有意义，因为很多情况下 Request、Limit 设置都不准确

有时，为了节约成本提高部署密度，Request 甚至会设置为 50m，甚至 10m

- 驱逐 Pod 导致应用不稳定

descheduler 通过策略计算出一系列符合要求的 Pod，进行驱逐。好的方面是，descheduler 不会驱逐没有副本控制器的 Pod，不会驱逐带本地存储的 Pod 等，保障在驱逐时，不会导致应用故障

但是使用 `client.PolicyV1beta1().Evictions` 驱逐 Pod 时，会先删掉 Pod 再重新启动，而不是滚动更新

在一个短暂的时间内，在集群上可能没有 Pod 就绪，或者因为故障新的 Pod 起不来，服务就会报错，有很多细节参数需要调整

- 依赖于 Kubernetes 的调度策略

descheduler 并没有实现调度器，而是依赖于 Kubernetes 的调度器

这也意味着，descheduler 能做的事情只是驱逐 Pod，让 Pod 重新走一遍调度流程

如果节点数量很少，descheduler 可能会频繁的驱逐 Pod

### 使用场景

descheduler 的视角在于动态，其中包括两个方面：Node 和 Pod

- Node 动态的含义在于，Node 的标签、污点、配置、数量等发生变化时

- Pod 动态的含义在于，Pod 在 Node 上的分布等

根据这些动态特征，可以归纳出如下适用场景：

- 新增了节点
- 节点重启之后
- 修改节点拓扑域、污点之后，希望存量的 Pod 也能满足拓扑域、污点
- Pod 没有均衡分布在不同节点

### 注意事项

当使用 descheduler 驱除Pods的时候，需要注意以下几点：

- 关键性 Pod 不会被驱逐，比如 `priorityClassName` 设置为 `system-cluster-critical` 或 `system-node-critical` 的 Pod
- 不属于 RS、Deployment 或 Job 管理的 Pods 不会被驱逐
- DaemonSet 创建的 Pods 不会被驱逐
- 使用 `LocalStorage` 的 Pod 不会被驱逐，除非设置 `evictLocalStoragePods: true`
- 具有 PVC 的 Pods 不会被驱逐，除非设置 `ignorePvcPods: true`
- 在 `LowNodeUtilization` 和 `RemovePodsViolatingInterPodAntiAffinity` 策略下，Pods 按优先级从低到高进行驱逐，如果优先级相同，`Besteffort` 类型的 Pod 要先于 `Burstable` 和 `Guaranteed` 类型被驱逐
- `annotations` 中带有 `descheduler.alpha.kubernetes.io/evict` 字段的 Pod 都可以被驱逐，该注释用于覆盖阻止驱逐的检查，用户可以选择驱逐哪个Pods
- 如果 Pods 驱逐失败，可以设置 `--v=4` 从 `descheduler` 日志中查找原因，如果驱逐违反 PDB 约束，则不会驱逐这类 Pods
