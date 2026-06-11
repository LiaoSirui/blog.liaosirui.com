## HPA 与 VPA

### 手动伸缩的局限

| 方式               | 问题                                   |
| ------------------ | -------------------------------------- |
| 固定 replicas      | 峰值扛不住，低谷浪费                   |
| 定时 Cron 扩缩     | 流量不规则时仍对不上                   |
| 人工 kubectl scale | 慢、不可复现、容易忘缩                 |
| 拍脑袋写 resource  | OOM 或资源闲置，成本与稳定性两头不讨好 |

弹性伸缩的目标是在 SLA 和资源成本之间自动找平衡，而不是靠人盯。

### HPA

HPA 监听 Deployment / StatefulSet / ReplicaSet 等可伸缩控制器，根据指标把副本数在 minReplicas～maxReplicas 之间调整。

典型触发条件：

- 资源利用率：如 CPU 平均使用率超过目标 70%；
- 自定义指标：如每 Pod QPS 超过特定阈值、消息队列积压长度；
- 外部指标：如云监控、Prometheus 暴露的业务指标；

适用场景：无状态、可水平拆分的服务 ——Web API、消费者 Worker、网关等。副本多了还能配合 Cluster Autoscaler 让节点跟着涨。

### VPA

VPA 资源对象分析 Pod 历史与当前资源用量，更新定义资源对象的 resources.requests，limits 可选，必要时通过 重建 Pod 让新规格生效。

它解决的是：你根本不知道该写多少 requests。开发说 512Mb 够了，上线后真实峰值是 1.2Gi——VPA 能根据实际需求持续调整。

VPA 有四种更新模式：

| 模式     | 行为                                            |
| -------- | ----------------------------------------------- |
| Off      | 只出建议，不改 Pod，适合前期观察                |
| Initial  | 仅在 Pod 创建时写入推荐值                       |
| Recreate | 需要变更时驱逐并重建 Pod                        |
| Auto     | 与 Recreate 等价（历史命名，生产常用 Recreate） |

适用场景：有状态或不便无限加副本、JVM / 批处理等内存曲线波动大、希望降低过度预留成本的 workload。

### 怎么选

- 流量波动、服务无状态，优先 HPA；
- 单实例或副本少、消耗资源难估计，考虑 VPA，建议先从 Off 起手看推荐；
- 两者同时绑同一 Deployment 容易打架 ——VPA 调大 requests 后，同样 CPU 用量算出来的 利用率百分比会下降，HPA 可能误判为负载低了而缩副本。

## 定义 HPA

HPA 基于 Resource Metrics API 读 CPU / 内存，所以集群里要先部署 metrics-server 服务

还需准备一个可被 HPA 指向的 Deployment，设置 resources.requests，否则 HPA 无法计算其利用率

```bash
kubectl autoscale deployment nginx-demo \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

通过 YAML 文件创建

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-demo-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-demo
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    # 可选同时按内存，需注意内存伸缩易抖动，需调 behavior
    # - type: Resource
    #   resource:
    #     name: memory
    #     target:
    #       type: Utilization
    #       averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60

```

## 定义 VPA

VPA 不属于 K8s 核心组件，需要安装 kubernetes / autoscaler 里的控制器

- <https://github.com/kubernetes/autoscaler.git>

定义 VPA 所需的 YAML 文件如下

建议生产先用 Off 观察推荐值，之后根据推荐值调整。

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: nginx-demo-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-demo
  updatePolicy:
    updateMode: "Off" # 观察期估值，确认后再改为 Recreate
  resourcePolicy:
    containerPolicies:
      - containerName: nginx
        minAllowed:
          cpu: 50m
          memory: 64Mi
        maxAllowed:
          cpu: 2
          memory: 2Gi
        controlledResources: ["cpu", "memory"]
        controlledValues: RequestsAndLimits

```

Off 模式下，Recommendation 段会给出 target、lowerBound、upperBound—— 这是调优 requests 的参考，不会动正在跑的 Pod

执行如下命令查看推荐与事件：

```bash
kubectl get events --field-selector involvedObject.name=nginx-demo-vpa
```

