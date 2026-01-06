## Prometheus Adapter

使用 Kubernetes 进行容器编排的主要优点之一是，它可以非常轻松地对应用程序进行水平扩展。Pod 水平自动缩放（HPA）可以根据 CPU 和内存使用量来扩展应用，在更复杂的情况下，可能还需要基于某些自定义的指标来进行扩缩容。

除了基于 CPU 和内存来进行自动扩缩容之外，还可以根据自定义的监控指标来进行。这时就需要使用 `Prometheus Adapter`，Prometheus 用于监控应用的负载和集群本身的各种指标，`Prometheus Adapter` 可以使用 Prometheus 收集的指标并使用它们来制定扩展策略，这些指标都是通过 APIServer 暴露的，而且 HPA 资源对象也可以很轻易的直接使用。

![file](./.assets/PrometheusAdapter/488581-20240604164007811-1418832613.png)

需要对 Prometheus Adapter 进行详细的配置，以确保其能够正确地与 Prometheus 和 Kubernetes 集成。配置主要通过一个 YAML 文件进行定义，其中包括 Prometheus 的地址、自定义查询规则、以及 Kubernetes API 服务器的相关设置。

Prometheus Adapter 的配置文件通常包含以下几个部分：

1. MetricMappings： 定义 Prometheus 查询规则和 Kubernetes 自定义指标的映射关系。
2. Rules： 定义自定义的 Prometheus 查询规则，包括指标名称、查询语法等。
3. ResourceRules： 定义与 Kubernetes 资源相关的查询规则，如节点、Pod 等。
4. MetricsRelabelings： 定义如何从 Prometheus 查询结果中提取和转换指标。

示例配置文件：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-metrics-config
data:
  config.yaml: |
    rules:
      default: false
      seriesQuery: 'http_requests_total{namespace!="",pod!=""}'
      resources:
        overrides:
          namespace: {resource: "namespace"}
          pod: {resource: "pod"}
      name:
        matches: "^(.*)_total"
        as: "${1}_per_second"
      metricsQuery: 'sum(rate(<<.Series>>[5m])) by (<<.GroupBy>>)'
```

在配置文件中，可以通过 rules 部分定义自定义的 Prometheus 查询规则。以下是一个详细的示例：

```yaml
rules:
  - seriesQuery: 'http_requests_total{namespace!="",pod!=""}'
    resources:
      overrides:
        namespace: {resource: "namespace"}
        pod: {resource: "pod"}
    name:
      matches: "^(.*)_total"
      as: "${1}_per_second"
    metricsQuery: 'sum(rate(<<.Series>>[5m])) by (<<.GroupBy>>)'

```

- seriesQuery：定义需要查询的 Prometheus 指标。
- resources：定义如何将 Prometheus 指标中的标签映射到 Kubernetes 资源。
- name：定义转换后的自定义指标名称。
- metricsQuery：定义具体的 Prometheus 查询语法，用于计算自定义指标的值。

除了 Prometheus，Prometheus Adapter 还可以适配其他数据源，如 Thanos、VictoriaMetrics 等。通过在配置文件中定义不同的数据源地址和查询规则，可以实现多数据源的灵活适配。例如：

```yaml
prometheus:
  url: http://thanos-query:9090/
  path: /api/v1/query

```

## 参考资料

- <https://www.cnblogs.com/xfuture/p/18231193>

- <https://www.qikqiak.com/k8strain2/monitor/adapter/>