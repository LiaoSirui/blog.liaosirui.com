Promtail 是Loki 官方支持的日志采集端，在需要采集日志的节点上运行采集代理，再统一发送到 Loki 进行处理

除了使用 Promtail，社区还有很多采集日志的组件，比如 fluentd、fluent bit、logstash 等，也都支持发送到 Loki。