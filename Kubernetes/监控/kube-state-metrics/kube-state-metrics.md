## kube-state-metrics 简介

kube-state-metrics 通过监听 Kubernetes API 服务器来生成不同资源的状态的 Metrics 数据。用来获取 Kubernetes 集群中各种资源对象的组件，例如 Deployment、Daemonset、Nodes 和 Pods 等

官方文档：<https://github.com/kubernetes/kube-state-metrics/tree/main/docs>

## 常用指标

- 节点

| 指标名称                     | 类型  | 含义                                                         |
| ---------------------------- | ----- | ------------------------------------------------------------ |
| kube_node_info               | Gauge | 查询集群内所有的节点信息，可以通过 sum() 函数获得集群中的所有节点数目。 |
| kube_node_spec_unschedulable | Gauge | 查询节点是否可以被调度新的 Pod。可以通过 sum() 函数获得集群中可以调度的 Pod 总数。 |
| kube_node_status_allocatable | Gauge | 查询节点可用于调度的资源总数。包括：CPU、内存、Pods 等。允许通过标签筛选，查看节点具体的资源容量。 |
| kube_node_status_capacity    | Gauge | 查询节点的全部资源总数，包括：CPU、内存、Pods 等。允许通过标签筛选，查看节点具体的资源容量。 |
| kube_node_status_condition   | Gauge | 查询节点的状态，可以基于 OutOfDisk、MemoryPressure、DiskPressure 等状态找到状态不正常的节点。 |

- Pod

| 指标名称                  | 类型  | 含义                                                         |
| ------------------------- | ----- | ------------------------------------------------------------ |
| ube_pod_info              | Gauge | 查询所有的 Pod 信息，可以通过 sum() 函数获得集群中的所有 Pod 数目。 |
| kube_pod_status_phase     | Gauge | 查询所有的 Pod 启动状态。状态包括：True：启动成功。Failed：启动失败。Unknown：状态未知。 |
| kube_pod_status_ready     | Gauge | 查询所有处于 Ready 状态的 Pod。可以通过 sum() 函数获得集群中的所有 Pod 数目。 |
| kube_pod_status_scheduled | Gauge | 查询所有处于 scheduled 状态的 Pod。可以通过 sum() 函数获得集群中的所有 Pod 数目。 |

- 容器

| 指标名称                                 | 类型  | 含义                                                         |
| ---------------------------------------- | ----- | ------------------------------------------------------------ |
| kube_pod_container_info                  | Gauge | 查询所有 Container 的信息。可以通过 sum() 函数获得集群中的所有 Container 数目。 |
| kube_pod_container_status_ready          | Gauge | 查询所有状态为 Ready 的 Container 信息。可以通过 sum() 函数获得集群中的所有 Container 数目。 |
| kube_pod_container_status_restarts_total | Count | 查询集群中所有 Container 的重启累计次数。可以通过 irate() 函数获得集群中 Container 的重启率。 |
| kube_pod_container_status_running        | Gauge | 查询所有状态为 Running 的 Container 信息。可以通过 sum() 函数获得集群中的所有 Container 数目。 |
| kube_pod_container_status_terminated     | Gauge | 查询所有状态为 Terminated 的 Container 信息。可以通过 sum() 函数获得集群中的所有 Container 数目。 |
| kube_pod_container_status_waiting        | Gauge | 查询所有状态为 Waiting 的 Container 信息。可以通过 sum() 函数获得集群中的所有 Container 数目。 |
| kube_pod_container_resource_requests     | Gauge | 查询容器的资源需求量。允许通过标签筛选，查看容器具体的资源需求量。 |
| kube_pod_container_resource_limits       | Gauge | 查询容器的资源限制量。允许通过标签筛选，查看容器具体的资源限制量。 |

## Pod Metrics

官方文档：<https://github.com/kubernetes/kube-state-metrics/blob/main/docs/pod-metrics.md>

- kube_pod_status_ready

下面的查询将过滤出所有具有失败的就绪状态的 Pod

```
kube_pod_status_ready{condition="false"} == 1
```

示例，警报将等待10分钟后触发，以过滤掉误触发情况，并返回遇到故障的 Pod 的名称

```yaml
### ALert Configuration

      - alert: KubePodReadinessFailure
        annotations:
          description: Readiness probe for the Pod {{ $labels.pod }} is failing for last 10 minutes
        expr: sum by(pod)( kube_pod_info{created_by_kind!="Job"} AND ON (pod, namespace) kube_pod_status_ready{condition="false"} == 1) > 0
        for: 10m
        labels:
          severity: warning
```

