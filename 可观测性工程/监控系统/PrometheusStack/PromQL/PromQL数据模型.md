
## 样本

Prometheus 会将所有采集到的样本数据以时间序列（time-series）的方式保存在内存数据库中，并且定时保存到硬盘上。

time-series 是按照时间戳和值的序列顺序存放的，我们称之为向量(vector)。

每条 time-series 通过指标名称（metrics name）和一组标签集（labelset）命名。

如下所示，可以将 time-series 理解为一个以时间为 Y 轴的数字矩阵：

```plain
  ^
  │   . . . . . . . . . . . . . . . . .   . .   node_cpu{cpu="cpu0",mode="idle"}
  │     . . . . . . . . . . . . . . . . . . .   node_cpu{cpu="cpu0",mode="system"}
  │     . . . . . . . . . .   . . . . . . . .   node_load1{}
  │     . . . . . . . . . . . . . . . .   . .  
  v
    <------------------ 时间 ---------------->
```

在 time-series 中的每一个点称为一个样本（sample），样本由以下三部分组成：

- 指标（metric）：metric name 和描述当前样本特征的 labelsets
- 时间戳（timestamp）：一个精确到毫秒的时间戳
- 样本值（value）： 一个 float64 的浮点型数据表示当前样本的值

```plain
<--------------- metric ---------------------><-timestamp -><-value->
http_request_total{status="200", method="GET"}@1434417560938 => 94355
http_request_total{status="200", method="GET"}@1434417561287 => 94334

http_request_total{status="404", method="GET"}@1434417560938 => 38473
http_request_total{status="404", method="GET"}@1434417561287 => 38544

http_request_total{status="200", method="POST"}@1434417560938 => 4748
http_request_total{status="200", method="POST"}@1434417561287 => 4785
```

## 指标 Metric

在形式上，所有的指标（Metric）都通过如下格式表示：

```plain
<metric name>{<label name>=<label value>, ...}
```

### 指标名称 Metric Name

指标的名称（metric name）可以反映被监控样本的含义；比如，`http_request_total` - 表示当前系统接收到的HTTP请求总量。

指标名称只能由 ASCII 字符、数字、下划线以及冒号组成并必须符合正则表达式 `[a-zA-Z_:][a-zA-Z0-9_:]*`

### 标签 Label

标签（label）反映了当前样本的特征维度，通过这些维度 Prometheus 可以对样本数据进行过滤，聚合等。

标签的名称只能由 ASCII 字符、数字以及下划线组成并满足正则表达式 `[a-zA-Z_][a-zA-Z0-9_]*`。其中以 `__` 作为前缀的标签，是系统保留的关键字，只能在系统内部使用。

标签的值则可以包含任何 Unicode 编码的字符。

在 Prometheus 的底层实现中指标名称实际上是以 `__name__=<metric name>` 的形式保存在数据库中的，因此以下两种方式均表示的同一条 time-series：

```plain
api_http_requests_total{method="POST", handler="/messages"}

{__name__="api_http_requests_total"，method="POST", handler="/messages"}
```

在 Prometheus 源码中也可以找到指标（Metric）对应的数据结构，如下所示：

```go
type Metric LabelSet

type LabelSet map[LabelName]LabelValue

type LabelName string

type LabelValue string
```

## 实例

通过 Node Exporter 暴露的 HTTP 服务，Prometheus 可以采集到当前主机所有监控指标的样本数据。例如：

```bash
# HELP node_cpu Seconds the cpus spent in each mode.
# TYPE node_cpu counter
node_cpu{cpu="cpu0",mode="idle"} 362812.7890625
# HELP node_load1 1m load average.
# TYPE node_load1 gauge
node_load1 3.0703125
```

其中非 `#` 开头的每一行表示当前 Node Exporter 采集到的一个监控样本：

- node_cpu 和 node_load1 表明了当前指标的名称
- 大括号中的标签则反映了当前样本的一些特征和维度
- 浮点数则是该监控样本的具体值
