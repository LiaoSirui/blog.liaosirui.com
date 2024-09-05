## Crane-scheduler 简介

为推进云原生用户在确保业务稳定性的基础上做到真正的极致降本，腾讯推出了业界第一个基于云原生技术的成本优化开源项目 Crane（ Cloud Resource Analytics and Economics ）。Crane 遵循 FinOps 标准，旨在为云原生用户提供云成本优化一站式解决方案

Crane-scheduler 作为 Crane 的调度插件实现了基于真实负载的调度功能，旨在从调度层面帮助业务降本增效

原生 kubernetes 调度器只能基于资源的 resource request 进行调度，然而 Pod 的真实资源使用率，往往与其所申请资源的 request/limit 差异很大，导致集群负载不均的问题

官方：

- GitHub 仓库：<https://github.com/gocrane/crane-scheduler>
- 文档：<https://gocrane.io/zh-cn/docs/tutorials/dynamic-scheduler-plugin/>

### 解决的问题

原生 kubernetes 调度器只能基于资源的 resource request 进行调度，然而 Pod 的真实资源使用率，往往与其所申请资源的 request/limit 差异很大，这直接导致了集群负载不均的问题：

1. 集群中的部分节点，资源的真实使用率远低于 resource request，却没有被调度更多的 Pod，这造成了比较大的资源浪费；
2. 而集群中的另外一些节点，其资源的真实使用率事实上已经过载，却无法为调度器所感知到，这极大可能影响到业务的稳定性。

这些无疑都与企业上云的最初目的相悖，为业务投入了足够的资源，却没有达到理想的效果。

既然问题的根源在于 resource request 与真实使用率之间的「鸿沟」，那为什么不能让调度器直接基于真实使用率进行调度呢？这就是 Crane-scheduler 设计的初衷。Crane-scheduler 基于集群的真实负载数据构造了一个简单却有效的模型，作用于调度过程中的 Filter 与 Score 阶段，并提供了一种灵活的调度策略配置方式，从而有效缓解了 kubernetes 集群中各种资源的负载不均问题。换句话说，Crane-scheduler 着力于调度层面，让集群资源使用最大化的同时排除了稳定性的后顾之忧，真正实现「降本增效」

### 整体架构

![img](.assets/Crane-scheduler%E7%AE%80%E4%BB%8B/2041406-20220601175606866-829748152.png)

如上图所示，Crane-scheduler 依赖于 Node-exporter 与 Prometheus 两个组件，前者从节点收集负载数据，后者则对数据进行聚合

而 Crane-scheduler 本身也包含两个部分:

- Scheduler-Controller 周期性地从 Prometheus 拉取各个节点的真实负载数据， 再以 Annotation 的形式标记在各个节点上；

- Scheduler 则直接在从候选节点的 Annotation 读取负载信息，并基于这些负载信息在 Filter 阶段对节点进行过滤以及在 Score 阶段对节点进行打分；

基于上述架构，最终实现了基于真实负载对 Pod 进行有效调度

### 调度策略

下图是官方提供的 Pod 的调度上下文以及调度框架公开的扩展点：

![img](.assets/Crane-scheduler%E7%AE%80%E4%BB%8B/2041406-20220601175607171-1206409384.png)

调度过程：

1. Sort - 用于对 Pod 的待调度队列进行排序，以决定先调度哪个 Pod
2. Pre-filter - 用于对 Pod 的信息进行预处理
3. Filter - 用于排除那些不能运行该 Pod 的节点
4. Post-filter - 一个通知类型的扩展点,更新内部状态，或者产生日志
5. Scoring - 用于为所有可选节点进行打分
6. Normalize scoring - 在调度器对节点进行最终排序之前修改每个节点的评分结果
7. Reserve - 使用该扩展点获得节点上为 Pod 预留的资源，该事件发生在调度器将 Pod 绑定到节点前
8. Permit - 用于阻止或者延迟 Pod 与节点的绑定
9. Pre-bind - 用于在 Pod 绑定之前执行某些逻辑
10. Bind - 用于将 Pod 绑定到节点上
11. Post-bind - 是一个通知性质的扩展
12. Unreserve - 如果为 Pod 预留资源，又在被绑定过程中被拒绝绑定，则将被调用

Crane-scheduler 主要作用于图中的 Filter 与 Score 阶段，并对用户提供了一个非常开放的策略配置

这也是 Crane-Scheduler 与社区同类型的调度器最大的区别之一：

1. 前者提供了一个泛化的调度策略配置接口，给予了用户极大的灵活性；
2. 后者往往只能支持 cpu/memory 等少数几种指标的感知调度，且指标聚合方式，打分策略均受限

在 Crane-scheduler 中，用户可以为候选节点配置任意的评价指标类型（只要从 Prometheus 能拉到相关数据），不论是常用到的 CPU/Memory 使用率，还是 IO、Network Bandwidth 或者 GPU 使用率，均可以生效，并且支持相关策略的自定义配置

#### Filter 策略

用户可以在 Filter 策略中配置相关指标的阈值，若候选节点的当前负载数据超过了任一所配置的指标阈值，则这个节点将会被过滤，默认配置如下：

```yaml
  predicate:
    ## cpu usage
    - name: cpu_usage_avg_5m
      maxLimitPecent: 0.65
    - name: cpu_usage_max_avg_1h
      maxLimitPecent: 0.75
    ## memory usage
    - name: mem_usage_avg_5m
      maxLimitPecent: 0.65
    - name: mem_usage_max_avg_1h
      maxLimitPecent: 0.75

```

#### Score 策略

用户可以在 Score 策略中配置相关指标的权重，候选节点的最终得分为不同指标得分的加权和，默认配置如下：

```yaml
    ### score = sum((1 - usage) * weight) * MaxScore / sum(weight)
    ## cpu usage
    - name: cpu_usage_avg_5m
      weight: 0.2
    - name: cpu_usage_max_avg_1h
      weight: 0.3
    - name: cpu_usage_max_avg_1d
      weight: 0.5
    ## memory usage
    - name: mem_usage_avg_5m
      weight: 0.2
    - name: mem_usage_max_avg_1h
      weight: 0.3
    - name: mem_usage_max_avg_1d
      weight: 0.5
```

#### 调度热点

在实际生产环境中，由于 Pod 创建成功以后，其负载并不会立马上升，这就导致了一个问题：如果完全基于节点实时负载对 Pod 调度，常常会出现调度热点（短时间大量 pod 被调度到同一个节点上）。为了解决这个问题，我们设置了一个单列指标 Hot Vaule，用来评价某个节点在近段时间内被调度的频繁程度，对节点实时负载进行对冲。最终节点的 Priority 为上一小节中的 Score 减去 Hot Value。Hot Value 默认配置如下：

```yaml
  hotValue:
    - timeRange: 5m
      count: 5
    - timeRange: 1m
      count: 2

```

注：该配置表示，节点在 5 分钟内被调度 5 个 pod，或者 1 分钟内被调度 2 个 pod，HotValue 加 10 分

## 部署

如「整体架构」中所述，Crane-scheduler 所需的负载数据均是通过 Controller 异步拉取。这种数据拉取方式：

1. 一方面，保证了调度器本身的性能；
2. 另一方面，有效减轻了 Prometheus 的压力，防止了业务突增时组件被打爆的情况发生。

此外，用户可以直接 Describe 节点，查看到节点的负载信息，方便问题定位：

```bash
[root@test01 ~]# kubectl describe node test01
Name:               test01
...
Annotations:        cpu_usage_avg_5m: 0.33142,2022-04-18T00:45:18Z
                    cpu_usage_max_avg_1d: 0.33495,2022-04-17T23:33:18Z
                    cpu_usage_max_avg_1h: 0.33295,2022-04-18T00:33:18Z
                    mem_usage_avg_5m: 0.03401,2022-04-18T00:45:18Z
                    mem_usage_max_avg_1d: 0.03461,2022-04-17T23:33:20Z
                    mem_usage_max_avg_1h: 0.03425,2022-04-18T00:33:18Z
                    node.alpha.kubernetes.io/ttl: 0
                    node_hot_value: 0,2022-04-18T00:45:18Z
                    volumes.kubernetes.io/controller-managed-attach-detach: true
...
```

用户可以自定义负载数据的类型与拉取周期，默认情况下，数据拉取的配置如下：

```yaml
  syncPolicy:
    ## cpu usage
    - name: cpu_usage_avg_5m
      period: 3m
    - name: cpu_usage_max_avg_1h
      period: 15m
    - name: cpu_usage_max_avg_1d
      period: 3h
    ## memory usage
    - name: mem_usage_avg_5m
      period: 3m
    - name: mem_usage_max_avg_1h
      period: 15m
    - name: mem_usage_max_avg_1d
      period: 3h
```

### helm chart 部署

官方 helm chart：<https://github.com/gocrane/helm-charts>

监控数据源

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: crane-scheduler
  namespace: monitoring
  labels:
    prometheus: k8s
    role: alert-rules
spec:
  groups:
    - name: cpu_mem_usage_active
      interval: 30s
      rules:
        - record: cpu_usage_active
          expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[30s])) * 100)
        - record: mem_usage_active
          expr: 100*(1-node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes)
    - name: cpu-usage-5m
      interval: 5m
      rules:
        - record: cpu_usage_max_avg_1h
          expr: max_over_time(cpu_usage_avg_5m[1h])
        - record: cpu_usage_max_avg_1d
          expr: max_over_time(cpu_usage_avg_5m[1d])
    - name: cpu-usage-1m
      interval: 1m
      rules:
        - record: cpu_usage_avg_5m
          expr: avg_over_time(cpu_usage_active[5m])
    - name: mem-usage-5m
      interval: 5m
      rules:
        - record: mem_usage_max_avg_1h
          expr: max_over_time(mem_usage_avg_5m[1h])
        - record: mem_usage_max_avg_1d
          expr: max_over_time(mem_usage_avg_5m[1d])
    - name: mem-usage-1m
      interval: 1m
      rules:
        - record: mem_usage_avg_5m
          expr: avg_over_time(mem_usage_active[5m])

```

> The sampling interval of Prometheus must be less than 30 seconds, otherwise the above rules(such as cpu_usage_active) may not take effect.
