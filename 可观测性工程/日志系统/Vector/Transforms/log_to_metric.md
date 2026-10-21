## 目的

使用日志作为数据源生成 Prometheus 指标

其他用途：

- 通过处理连接日志和根据获得的数据创建指标来证明对安全审计很有用
- 解析日志以查找缓慢的数据库查询

## 创建简单的错误计数器

```yaml
# 根据过滤的日志消息创建一个指标，设置要使用的指标类型和字段
transforms:
  kttl_logs_routed:
    type: route
    inputs:
      - kttl_logs_parsed
    route:
      info: '.level == "info"'
      warning: '.level == "warning"'
  kttl_logs_metrics:
    type: log_to_metric
    inputs:
      - kttl_logs_routed.warning
    metrics:
      - type: counter
        field: warning
        name: info_total
        namespace: kttl_logs
        tags:
          level: "{{ level }}"
          process_id: "{{ process_id }}"
# 发布 exporter
sinks:
  kttl_logs_metrics_export:
    type: prometheus_exporter
    inputs:
      - kttl_logs_metrics
    address: 0.0.0.0:9598
    default_namespace: kttl_logs
```

对日志使用下面的 PromQL 进行告警指标计算：

```promql
increase(kttl_logs_info_total{level="warning"}[5m]) > 0
```

## 参考资料

- <https://blog.palark.com/vector-to-export-pgsql-logs-into-prometheus/>
- <https://vector.dev/docs/reference/configuration/transforms/log_to_metric/>

