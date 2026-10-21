PSI（Pressure Stall Information，压力暂缓信息）驱动的用户态 killer 是一种在系统发生严重资源紧缺前，通过内核空间上报压力指标、在用户态进行主动干预和进程终止的内存管理机制。精准评估：通过任务 “受阻塞的时长” 衡量压力，比单纯看剩余内存大小（free memory）更科学。

<https://github.com/mz1999/blog/blob/master/docs/psi.md>

压力停滞信息 (PSI) 是 Linux 内核（4.20 及更高版本）的一项功能， 它提供了一种规范化的方式来量化基础设施资源的压力， 即资源需求是否超过当前供应。 它超越了简单的资源利用率指标，而是测量任务因资源竞争而停滞的时间。 这是识别和诊断可能影响应用程序性能的资源瓶颈的强大方法。

<https://kubernetes.io/zh-cn/blog/2025/09/04/kubernetes-v1-34-introducing-psi-metrics-beta/>

```bash
grep -E 'CONFIG_PSI' /boot/config-$(uname -r) 2>/dev/null \
  || zcat /proc/config.gz 2>/dev/null | grep -E 'CONFIG_PSI'
# CONFIG_PSI=y
# CONFIG_PSI_DEFAULT_DISABLED=y

grubby --update-kernel=ALL --args="psi=1"

kubectl get --raw "/api/v1/nodes/<node-name>/proxy/metrics/cadvisor" | \
    grep 'container_pressure_cpu_waiting_seconds_total{container="cpu-stress"'
```

容器监控

```yaml
- alert: ContainerCpuPsiHigh
  expr: sum by (namespace, pod, container) (rate(container_pressure_cpu_waiting_seconds_total[5m])) > 0.20
  for: 3m
  labels:
  severity: warning
  annotations:
  summary: "容器 CPU 压力过高"
  description: "命名空间 {{ $labels.namespace }} 中的 Pod {{ $labels.pod }} (容器 {{ $labels.container }}) 在过去 5 分钟内，有超过 20% 的时间因等待 CPU 而停滞，请检查 CPU 资源分配或节点负载。"
- alert: ContainerMemoryPsiSevere
  expr: sum by (namespace, pod, container) (rate(container_pressure_memory_stalled_seconds_total[5m])) > 0.10
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "容器内存完全停滞（严重严重）"
    description: "容器 {{ $labels.container }} 所有任务有超过 10% 的时间因为等待内存而完全阻塞，可能即将触发 OOM 杀除！"
- alert: ContainerIoPsiHigh
  expr: sum by (namespace, pod, container) (rate(container_pressure_io_waiting_seconds_total[5m])) > 0.15
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "容器 I/O 压力过高"
    description: "容器 {{ $labels.container }} 出现 I/O 阻塞，过去 5 分钟等待 I/O 时间占比超过 15%。"

```

