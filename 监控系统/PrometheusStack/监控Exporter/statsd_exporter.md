## StatsD Exporter

- Github 仓库：<https://github.com/prometheus/statsd_exporter>

```bash
+----------+                         +-------------------+                        +--------------+
|  StatsD  |---(UDP/TCP repeater)--->|  statsd_exporter  |<---(scrape /metrics)---|  Prometheus  |
+----------+                         +-------------------+                        +--------------+
```

## 使用容器运行

运行

```bash
docker run -d -p 9102:9102 -p 9125:9125 -p 9125:9125/udp \
        -v $PWD/statsd_mapping.yml:/tmp/statsd_mapping.yml \
        prom/statsd-exporter --statsd.mapping-config=/tmp/statsd_mapping.yml
```

示例配置文件

```yaml
mappings:
# ...
```

9102 端口是供 Prometheus pull 使用，9125 是供 statsd repeater 的

## 转换配置

```bash
StatsD gauge   -> Prometheus gauge

StatsD counter -> Prometheus counter

StatsD timer, histogram, distribution   -> Prometheus summary or histogram
```

示例

```yaml
mappings:
- match: "test.dispatcher.*.*.*"
  name: "dispatcher_events_total"
  labels:
    processor: "$1"
    action: "$2"
    outcome: "$3"
    job: "test_dispatcher"
- match: "*.signup.*.*"
  name: "signup_events_total"
  labels:
    provider: "$2"
    outcome: "$3"
    job: "${1}_server"
```

这将把这些示例 StatsD 指标转换为 Prometheus 指标，如下所示：

```bash
test.dispatcher.FooProcessor.send.success
 => dispatcher_events_total{processor="FooProcessor", action="send", outcome="success", job="test_dispatcher"}

foo_product.signup.facebook.failure
 => signup_events_total{provider="facebook", outcome="failure", job="foo_product_server"}

test.web-server.foo.bar
 => test_web_server_foo_bar{}
 # 转换为 Prometheus 兼容名称
```

配置文件中的每个映射都必须为指标定义一个名称，包含 `$n` 样式的引用（这些引用将被匹配行中的第 n 个匹配项替换，这允许动态重写），例如

```yaml
mappings:
- match: "test.*.*.counter"
  name: "${2}_total"
  labels:
    provider: "$1"
```

