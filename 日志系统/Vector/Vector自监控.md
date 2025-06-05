## 指标（Metrics）

Vector `internal_metrics source` 用于收集和导出 Vector 自身的内部指标。这些指标可以帮助监控 Vector 的性能和健康状态：

```yaml
role: "Agent"

tolerations:
  - operator: Exists

service:
  ports:
    - name: prom-exporter
      port: 9598

containerPorts:
  - name: prom-exporter
    containerPort: 9598
    protocol: TCP  

customConfig:
  data_dir: /vector-data-dir  
  sources:
    vector_metrics:
      type: internal_metrics
      scrape_interval_secs: 10

  sinks:
    prom-exporter:
      type: prometheus_exporter
      inputs:
        - vector_metrics
      address: 0.0.0.0:9598
```

以下为指标（Metrics）参考：

| 指标名称                             | 指标类型  | 描述                                                         |
| :----------------------------------- | :-------: | :----------------------------------------------------------- |
| adaptive_concurrency_averaged_rtt    | Histogram | 当前窗口的平均往返时间 (RTT)。                               |
| adaptive_concurrency_in_flight       | Histogram | 当前等待响应的出站请求数量。                                 |
| adaptive_concurrency_limit           | Histogram | 自适应并发功能为当前窗口决定的并发限制。                     |
| adaptive_concurrency_observed_rtt    | Histogram | 观察到的请求往返时间 (RTT)。                                 |
| aggregate_events_recorded_total      |  Counter  | 聚合转换记录的事件数量。                                     |
| aggregate_failed_updates             |  Counter  | 聚合转换遇到的失败指标更新和添加的数量。                     |
| aggregate_flushes_total              |  Counter  | 聚合转换完成的刷新次数。                                     |
| api_started_total                    |  Counter  | Vector GraphQL API 启动的次数。                              |
| buffer_byte_size                     |   Gauge   | 当前缓冲区中的字节数。                                       |
| buffer_discarded_events_total        |  Counter  | 非阻塞缓冲区丢弃的事件数。                                   |
| buffer_events                        |   Gauge   | 缓冲区中当前的事件数量。                                     |
| buffer_received_event_bytes_total    |  Counter  | 缓冲区接收到的字节总数。                                     |
| buffer_received_events_total         |  Counter  | 缓冲区接收到的事件总数。                                     |
| buffer_send_duration_seconds         | Histogram | 发送负载到缓冲区所花费的时间。                               |
| buffer_sent_event_bytes_total        |  Counter  | 缓冲区发送的字节总数。                                       |
| buffer_sent_events_total             |  counter  | 缓冲区发送的事件总数。                                       |
| build_info                           |   Gauge   | 构建版本信息。                                               |
| checkpoints_total                    |  Counter  | Checkpoint 文件数。                                          |
| checksum_errors_total                |  Counter  | 通过校验和识别文件的错误总数。                               |
| collect_completed_total              |  Counter  | 组件完成的指标收集总次数。                                   |
| collect_duration_seconds             | Histogram | 收集此组件的指标所花费的时长。                               |
| command_executed_total               |  Counter  | 执行命令的总次数。                                           |
| command_execution_duration_seconds   | Histogram | 命令执行的持续时间（以秒为单位）。                           |
| component_discarded_events_total     |  Counter  | 组件丢弃的事件总数。                                         |
| component_errors_total               |  Counter  | 组件遇到的错误总数。                                         |
| component_received_bytes             | Histogram | 源接收的每个事件的字节大小。                                 |
| component_received_bytes_total       |  Counter  | 组件从源接受的原始字节总数。                                 |
| component_received_event_bytes_total |  Counter  | 该组件从标记来源（如文件和 uri）或从其他来源累计接受的事件字节数。 |
| component_received_events_count      | Histogram | Vector 内部拓扑中每个内部批次中传递的事件数量的直方图。      |
| component_received_events_total      |  Counter  | 组件从标记来源（如文件和 uri）或从其他来源累计接受的事件数。 |
| component_sent_bytes_total           |  Counter  | 组件发送到目标接收器的原始字节数。                           |
| component_sent_event_bytes_total     |  Counter  | 组件发出的事件字节总数。                                     |
| component_sent_events_total          |  Counter  | 组件发出的事件总数。                                         |
| connection_established_total         |  Counter  | 建立连接的总次数。                                           |
| connection_read_errors_total         |  Counter  | 读取数据报时遇到的错误总数。                                 |
| connection_send_errors_total         |  Counter  | 通过连接发送数据时的错误总数。                               |
| connection_shutdown_total            |  Counter  | 连接关闭的总次数。                                           |
| container_processed_events_total     |  Counter  | 处理的容器事件总数。                                         |
| containers_unwatched_total           |  Counter  | Vector 停止监视容器日志的总次数。                            |
| containers_watched_total             |  Counter  | Vector 开始监视容器日志的总次数。                            |
| events_discarded_total               |  Counter  | 组件丢弃的事件总数。                                         |
| files_added_total                    |  Counter  | Vector 监视文件总数。                                        |
| files_deleted_total                  |  Counter  | 删除的文件总数。                                             |
| files_resumed_total                  |  Counter  | Vector 恢复监视文件的总次数。                                |
| files_unwatched_total                |  Counter  | Vector 停止监视文件的总次数。                                |
| grpc_server_handler_duration_seconds | Histogram | 处理 gRPC 请求所花费的时间。                                 |
| grpc_server_messages_received_total  |  Counter  | 接收到的 gRPC 消息总数。                                     |
| grpc_server_messages_sent_total      |  Counter  | 发送的 gRPC 消息总数。                                       |
| http_client_requests_sent_total      |  Counter  | 发送的 HTTP 请求总数，按请求方法标记。                       |
| http_client_response_rtt_seconds     | Histogram | HTTP 请求的往返时间 (RTT)。                                  |
| http_client_responses_total          |  Counter  | HTTP 请求的总数。                                            |
| http_client_rtt_seconds              | Histogram | HTTP 请求的往返时间 (RTT)。                                  |
| http_requests_total                  |  Counter  | 组件发出的 HTTP 请求总数。                                   |
| http_server_handler_duration_seconds | Histogram | 处理 HTTP 请求所花费的时间。                                 |
| http_server_requests_received_total  |  Counter  | 接收到的 HTTP 请求总数。                                     |
| http_server_responses_sent_total     |  Counter  | 发送的 HTTP 响应总数。                                       |
| internal_metrics_cardinality         |   Gauge   | 从内部指标注册表发出的指标总数。                             |
| invalid_record_total                 |  Counter  | 被丢弃的无效记录总数。                                       |

## 日志（Logs）

Vector `internal_logs` 用于收集和处理 Vector 自身生成的内部日志，可以帮助了解 Vector 的运行状态，以及诊断故障问题等

```yaml
role: "Agent"

tolerations:
  - operator: Exists

service:
  ports:
    - name: prom-exporter
      port: 9598

containerPorts:
  - name: prom-exporter
    containerPort: 9598
    protocol: TCP  

customConfig:
  data_dir: /vector-data-dir
  sources:
    vector_logs:
      type: internal_logs
      
  sinks:
    stdout:
      type: console
      inputs:
        - vector_logs
      encoding:
        codec: json
```

## 告警

通过暴露 Vector 的 `internal_metrics`，可以获取 Vector 自身的指标并编写 Prometheus 规则实现告警

- 发送中断

数据发送发生中断并持续一分钟后，则按规则判定为发送中断，将产生告警：

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: vector-sink-down
spec:
  groups:
    - name: vector
      rules:
        - alert: "VectorSinkDown"
          annotations:
            summary: "Vector sink down"
            description: "Vector sink down, sinks: {{ $labels.component_id }}"
          expr: |
            rate(vector_buffer_sent_events_total{component_type="${SINK_NAME}"}[30s]) == 0
          for: 1m
          labels:
            severity: critical
```

- 延时

系统计算最近五分钟的 95th 百分位延迟，如果大于 0.5 秒并且持续一分钟，则产生告警：

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: vector-high-latency
spec:
  groups:
    - name: vector
      rules:
        - alert: "VectorHighLatency"
          annotations:
            summary: "High latency in Vector"
            description: "The 95th percentile latency for HTTP client responses is above 0.5 seconds."
          expr: |
            histogram_quantile(0.95, rate(vector_http_client_response_rtt_seconds_bucket[5m])) > 0.5
          for: 1m
          labels:
            severity: warning
```

- 错误率

计算最近五分钟 HTTP 请求发生 5xx 错误率大于 5%并且持续两分钟，则产生告警：

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: vector-high-error
spec:
  groups:
    - name: vector
      rules:
        - alert: "VectorHighERROR"
          annotations:
            summary: "High error rate in Vector"
            description: "The error rate for HTTP client responses exceeds 5% over the last 5 minutes."
          expr: |
            rate(vector_http_client_responses_total{status=~"5.*"}[5m]) / rate(vector_http_client_responses_total[5m]) > 0.05
          for: 2m
          labels:
            severity: warning
```

