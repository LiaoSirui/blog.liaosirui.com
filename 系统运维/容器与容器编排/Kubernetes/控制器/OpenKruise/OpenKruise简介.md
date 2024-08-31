## OpenKruise 简介

OpenKruise 是一个基于 Kubernetes 的扩展套件，主要聚焦于云原生应用的自动化，比如部署、发布、运维以及可用性防护

OpenKruise 提供的绝大部分能力都是基于 CRD 扩展来定义的，它们不存在于任何外部依赖，可以运行在任意纯净的 Kubernetes 集群中；Kubernetes 自身提供的一些应用部署管理功能，对于大规模应用与集群的场景这些功能是远远不够的，OpenKruise 弥补了 Kubernetes 在应用部署、升级、防护、运维等领域的不足

官方：

- GitHub 仓库：<https://github.com/openkruise/kruise>
- Chart 仓库 GitHub 地址：<https://github.com/openkruise/charts>
- 文档地址：<https://openkruise.io/>

OpenKruise 提供了以下的一些核心能力：

- 增强版本的 Workloads

OpenKruise 包含了一系列增强版本的工作负载，比如 CloneSet、Advanced StatefulSet、Advanced DaemonSet、BroadcastJob 等

它们不仅支持类似于 Kubernetes 原生 Workloads 的基础功能，还提供了如原地升级、可配置的扩缩容/发布策略、并发操作等

其中，原地升级是一种升级应用容器镜像甚至环境变量的全新方式，它只会用新的镜像重建 Pod 中的特定容器，整个 Pod 以及其中的其他容器都不会被影响

因此它带来了更快的发布速度，以及避免了对其他 Scheduler、CNI、CSI 等组件的负面影响

- 应用的旁路管理

OpenKruise 提供了多种通过旁路管理应用 sidecar 容器、多区域部署的方式，“旁路” 意味着你可以不需要修改应用的 Workloads 来实现它们

比如，SidecarSet 能帮助你在所有匹配的 Pod 创建的时候都注入特定的 sidecar 容器，甚至可以原地升级已经注入的 sidecar 容器镜像、并且对 Pod 中其他容器不造成影响

而 WorkloadSpread 可以约束无状态 Workload 扩容出来 Pod 的区域分布，赋予单一 workload 的多区域和弹性部署的能力

- 高可用性防护

OpenKruise 可以保护你的 Kubernetes 资源不受级联删除机制的干扰，包括 CRD、Namespace、以及几乎全部的 Workloads 类型资源

相比于 Kubernetes 原生的 PDB 只提供针对 Pod Eviction 的防护，PodUnavailableBudget 能够防护 Pod Deletion、Eviction、Update 等许多种 voluntary disruption 场景

- 高级的应用运维能力

OpenKruise 也提供了很多高级的运维能力来帮助你更好地管理应用，比如可以通过 ImagePullJob 来在任意范围的节点上预先拉取某些镜像，或者指定某个 Pod 中的一个或多个容器被原地重启

## 安装

OpenKruise 要求在 Kubernetes >= 1.16 以上版本的集群中安装和使用

首先添加 charts 仓库：

```bash
helm repo add openkruise https://openkruise.github.io/charts

helm repo update
```

使用 `values.yaml`，可配置的 values 值可以参考 charts 文档 [https://github.com/openkruise/charts](https://github.com/openkruise/charts/tree/master/versions/1.0.1) 进行定制

```yaml
manager:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution: 
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - devmaster
                - devnode1
                - devnode2
  podAntiAffinity:
  tolerations:
    - operator: "Exists"
  resources:
    limits:
      cpu: 200m
      memory: 1024Mi
    requests:
      cpu: 100m
      memory: 256Mi
```

查看最新版本：

```bash
> helm search repo openkruise

NAME                           	CHART VERSION	APP VERSION	DESCRIPTION
openkruise/kruise              	1.3.0        	1.3.0      	Helm chart for kruise components
openkruise/kruise-game         	0.2.0        	0.2.0      	Helm chart for kruise-game components
openkruise/kruise-rollout      	0.3.0        	0.3.0      	Helm chart for kruise-rollout components
openkruise/kruise-state-metrics	0.1.0        	1.16.0     	Install kruise-state-metrics to generate and ex...
```

然后执行下面的命令安装最新版本的应用：

```bash
helm upgrade --install kruise openkruise/kruise --version 1.3.0 -f ./values.yaml
```

应用部署完成后会在 `kruise-system` 命名空间下面运行 2 个 `kruise-manager` 的 Pod，同样它们之间采用 leader-election 的方式选主，同一时间只有一个提供服务，达到高可用的目的

此外还会以 DaemonSet 的形式启动 `kruise-daemon` 组件：

```bash
> kubectl get pods -n kruise-system

NAME                                         READY   STATUS    RESTARTS   AGE
kruise-controller-manager-7947597486-qx8x4   1/1     Running   0          6m29s
kruise-controller-manager-7947597486-xhf65   1/1     Running   0          6m29s
kruise-daemon-q6gmn                          1/1     Running   0          6m28s
kruise-daemon-sqm96                          1/1     Running   0          6m28s
kruise-daemon-vfmvw                          1/1     Running   0          6m28s
```

## 架构

OpenKruise 的整体架构：

![img](.assets/OpenKruise%E7%AE%80%E4%BB%8B/20220224101357.png)

- `Kruise-manager` 

其中 `Kruise-manager` 是一个运行控制器和 webhook 的中心组件，它通过 Deployment 部署在 `kruise-system` 命名空间中

从逻辑上来看，如 `cloneset-controller`、`sidecarset-controller` 这些的控制器都是独立运行的，不过为了减少复杂度，它们都被打包在一个独立的二进制文件、并运行在 `kruise-controller-manager-xxx` 这个 Pod 中

除了控制器之外，`kruise-controller-manager-xxx` 中还包含了针对 Kruise CRD 以及 Pod 资源的 admission webhook；`Kruise-manager` 会创建一些 webhook configurations 来配置哪些资源需要感知处理、以及提供一个 Service 来给 kube-apiserver 调用

- `Kruise-daemon`

从 v0.8.0 版本开始提供了一个新的 `Kruise-daemon` 组件，它通过 DaemonSet 部署到每个节点上，提供镜像预热、容器重启等功能。

## CRD

所有 OpenKruise 的功能都是通过 Kubernetes CRD 来提供的：

```bash
> kubectl get crd | grep kruise.io

advancedcronjobs.apps.kruise.io              2023-03-10T12:50:41Z
broadcastjobs.apps.kruise.io                 2023-03-10T12:50:41Z
clonesets.apps.kruise.io                     2023-03-10T12:50:41Z
containerrecreaterequests.apps.kruise.io     2023-03-10T12:50:41Z
daemonsets.apps.kruise.io                    2023-03-10T12:50:41Z
imagepulljobs.apps.kruise.io                 2023-03-10T12:50:41Z
nodeimages.apps.kruise.io                    2023-03-10T12:50:41Z
nodepodprobes.apps.kruise.io                 2023-03-10T12:50:41Z
persistentpodstates.apps.kruise.io           2023-03-10T12:50:41Z
podprobemarkers.apps.kruise.io               2023-03-10T12:50:41Z
podunavailablebudgets.policy.kruise.io       2023-03-10T12:50:41Z
resourcedistributions.apps.kruise.io         2023-03-10T12:50:41Z
sidecarsets.apps.kruise.io                   2023-03-10T12:50:41Z
statefulsets.apps.kruise.io                  2023-03-10T12:50:41Z
uniteddeployments.apps.kruise.io             2023-03-10T12:50:41Z
workloadspreads.apps.kruise.io               2023-03-10T12:50:41Z
```

提供了如下 CRD：

（1）[TypicalWorkloads](Kruise控制器/TypicalWorkloads.md)

- `CloneSet` 

对原生 Deployment 的增强控制器

- `DaemonSet（Advanced）` 

原生 DaemonSet 上增强了发布能力

- `StatefulSet（Advanced）` 

原生的 StatefulSet 基础上增强了发布能力

（2）Job Workloads


- `AdvancedCronJob` 

AdvancedCronJob 是对于原生 CronJob 的扩展版本，根据用户设置的 schedule 规则，周期性创建 Job 执行任务

- `BroadcastJob` 

BroadcastJob 管理的 Pod 并不是长期运行的 daemon 服务，而是类似于 Job 的任务类型 Pod，在每个节点上的 Pod 都执行完成退出后

（3）Sidecar Management

- `SidecarSet` 

SidecarSet 将 sidecar 容器的定义和生命周期与业务容器解耦，它主要用于管理无状态的 sidecar 容器，比如监控、日志等 agent

（4）Multi-domain Management



（5）Enhanced Operations

- `ImagePullJob` 

NodeImage 和 ImagePullJob

（6）Application Protection

- `ContainerLaunchPriority` 

提供了控制一个 Pod 中容器启动顺序的方法

- `ContainerRestart` 

ContainerRecreateRequest 控制器可以帮助用户重启/重建存量 Pod 中一个或多个容器
