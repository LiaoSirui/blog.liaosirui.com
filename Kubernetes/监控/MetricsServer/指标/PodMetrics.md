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

