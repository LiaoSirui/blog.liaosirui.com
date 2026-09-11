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

