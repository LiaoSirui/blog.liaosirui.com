## 规则分类

Prometheus 规则是一种逻辑表达式，可用于定义有关监控数据的逻辑关系和约束条件。这些规则可以用于告警条件、聚合和转换等

Prometheus 支持两种类型的规则，可以对其进行配置，然后定期进行评估：

- Recording Rules：使用 PromQL 表达式进行聚合和转换，将结果记录下来。例如计算平均响应时间。可以作为性能指标的跟踪，以便找到规律优化服务
- Alerting Rules：在满足某些条件时触发警报，例如 CPU 使用率超过 90％

官方文档：

- <https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/>
- <https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/>

## 配置规则

配置 Prometheus 使用规则文件

`prometheus.yml`

文档：<https://prometheus.io/docs/prometheus/latest/configuration/configuration/>

```yaml
...

rule_files:
  - "prometheus.rules.yml"  # 指定具体文件
  - "rules/*.yml"  # 指定 rules 目录下的所有以 .yml 结尾的文件

```

## 规则文件语法

全局

```yaml
groups:
  #  则组的名称，在当前文件中需唯一
  - name: example
    # 获取规则数据的频率，也就是每次查询规则的间隔时间，比如设置为 5s, 1m 等
    # 一般按默认，默认是安装 prometheus 配置文件中全局配置的 evaluation_interval 值
    [ interval: <duration> | default = global.evaluation_interval ]

    # 限制警报规则和记录规则可以产生的系列警报的数量。0 没有限制。一般按默认
    [ limit: <int> | default = 0 ]

    # 定义这个规则组中一个一个的规则
    rules:
      [- <rule> ...]

```

文档：<https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#rule>

记录规则允许您预先计算经常需要的或计算成本高昂的表达式，并将其结果保存为一组新的时间序列

```yaml
groups:
  - name: example
    rules:
      # record 字段： 输出到的时间序列的名称。必须是有效的度量值名称
    - record: code:prometheus_http_requests_total:sum
    
      # 要计算的PromQL表达式。每个评估周期都在当前时间进行评估，结果记录为一组新的时间序列
      # 度量名称由 "record" 给出
      expr: sum by (code) (prometheus_http_requests_total)

      # labels 下配置的是存储结果之前要添加或覆盖的标签
      labels:
        [ <labelname>: <labelvalue> ]

```

警报规则文件的语法几乎和记录规则文件语法一样，只是 rule (规则)配置中部分字段不同

```yaml
groups:
  - name: example
    rules:
      # alertname 警报的名称。必须符合有效标签名称的规则
	- alert: <string>
	
	  # 要计算的 PromQL 表达式
	  # 每个评估周期都会在当前时间进行评估，满足表达式条件后，所有生成的时间序列都会变为 pending 挂起/ firing alerts 触发警报
	  expr: <string>
	
	  # 当 expr 内书写的表达式条件满足后，警报会立刻变成 pending 状态
	  # 持续超过 for 指定的时间后，警报会被视为触发，并转为 firing 状态
	  # pending 和 firing 也会在 Prometheus Web 页面中看到
	  [ for: <duration> | default = 0s ]
	
	  # 触发警报的条件清除后，警报仍然保持触发状态多长时间
	  [ keep_firing_for: <duration> | default = 0s ]
	
	  # 要为每个警报添加或覆盖的标签。标签值可以使用 go 的模板变量
	  labels:
	    [ <labelname>: <tmpl_string> ]
	
	  # 要添加到每个警报的注释。这个信息通常用于发送告警给某个介质（邮件，钉钉等）的内容中
	  # lavelname 的值可以使用 go 的模板变量
	  annotations:
	    [ <labelname>: <tmpl_string> ]

```

## 模板化

一般来说，在告警规则文件的 annotations 中使用 summary 描述告警的概要信息，description 用于描述告警的详细信息。同时 Alertmanager 的 UI 也会根据这两个标签值，显示告警信息。为了让告警信息具有更好的可读性，Prometheus 支持模板化 label 和 annotations 的中标签的值

labels 和 annotations 字段的配置可以使用 go 语言中的模板进行模板化

- `$labels` 变量包含警报实例的标签键/值对
- 可以通过 `$externalLabels` 变量访问配置的外部标签
- `$value` 变量保存警报实例 `expr` 的计算结果值，注意不是返回条件表达式的 布尔值。例如： `up == 0` 中， `$value` 的值是 `up` 的计算结果，官方称为警报实例的评估值

示例：

```yaml
groups:
- name: example
  rules:

  # 对任何超过5分钟无法访问的实例发出警报。
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      severity: page
    annotations:
      summary: "实例: {{ $labels.instance }} 已停机"
      description: "xx 项目作业 Job:｛｛$labels.job｝｝的｛{$labels.instance}｝已停机超过5分钟。"

  # 针对请求延迟中值>1s的任何实例发出警报
  - alert: APIHighRequestLatency
    expr: api_http_request_latencies_second{quantile="0.5"} > 1
    for: 10m
    annotations:
      summary: "实例 {{ $labels.instance }} 请求延迟高"
      description: "{{ $labels.instance }} 的请求延迟超过 1 秒(当前值: {{ $value }}s)"

```

## 检查规则文件语法

在不启动 Prometheus 的情况下也可以检查规则文件中的语法是否正确。

Prometheus 安装包中的 promtool 工具可以支持规则文件语法的检查。

```bash
promtool check rules /path/to/example.rules.yml
```
