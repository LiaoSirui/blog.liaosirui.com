
为了能够帮助用户理解和区分这些不同监控指标之间的差异，Prometheus 定义了 4 种不同的指标类型（metric type）：

- Counter（计数器）
- Gauge（仪表盘）
- Histogram（直方图）
- Summary（摘要）

在 Exporter 返回的样本数据中，其注释中也包含了该样本的类型。例如：

```plain
# HELP node_cpu Seconds the cpus spent in each mode.
# TYPE node_cpu counter
node_cpu{cpu="cpu0",mode="idle"} 362812.7890625
```

## Counter

只增不减的计数器

Counter 类型的指标其工作方式和计数器一样，只增不减（除非系统发生重置）。常见的监控指标，如 http_requests_total，node_cpu 都是 Counter 类型的监控指标。

一般在定义 Counter 类型指标的名称时推荐使用 `_total` 作为后缀。

Counter 是一个简单但有强大的工具，例如我们可以在应用程序中记录某些事件发生的次数，通过以时序的形式存储这些数据，可以轻松的了解该事件产生速率的变化。

### 示例

PromQL 内置的聚合操作和函数可以让用户对这些数据进行进一步的分析；例如，通过 `rate()` 函数获取 HTTP 请求量的增长率：

```promql
rate(http_requests_total[5m])
```

查询当前系统中，访问量前 10 的 HTTP 地址：

```promql
topk(10, http_requests_total)
```

## Gauge

与 Counter 不同，Gauge 类型的指标侧重于反应系统的当前状态。因此这类指标的样本数据可增可减。

常见指标如：node_memory_MemFree（主机当前空闲的内容大小）、node_memory_MemAvailable（可用内存大小）都是 Gauge 类型的监控指标。

### Gauge 示例

通过 Gauge 指标，用户可以直接查看系统的当前状态：

```promql
node_memory_MemFree
```

对于 Gauge 类型的监控指标，通过 PromQL 内置函数 `delta()` 可以获取样本在一段时间返回内的变化情况。例如，计算 CPU 温度在两个小时内的差异：

```promql
delta(cpu_temp_celsius{host="zeus"}[2h])
```

还可以使用 `deriv()` 计算样本的线性回归模型，甚至是直接使用 `predict_linear()` 对数据的变化趋势进行预测。例如，预测系统磁盘空间在 4 个小时之后的剩余情况：

```promql
predict_linear(node_filesystem_free{job="node"}[1h], 4 * 3600)
```

## Histogram 和 Summary

Histogram 和 Summary 主用用于统计和分析样本的分布情况。

在大多数情况下人们都倾向于使用某些量化指标的平均值，例如 CPU 的平均使用率、页面的平均响应时间。这种方式的问题很明显，以系统 API 调用的平均响应时间为例：如果大多数 API请求都维持在 100ms 的响应时间范围内，而个别请求的响应时间需要 5s，那么就会导致某些 WEB 页面的响应时间落到中位数的情况，而这种现象被称为长尾问题。为了区分是平均的慢还是长尾的慢，最简单的方式就是按照请求延迟的范围进行分组。例如，统计延迟在 `0~10ms` 之间的请求数有多少而 `10~20ms` 之间的请求数又有多少。通过这种方式可以快速分析系统慢的原因。

Histogram 和 Summary 都是为了能够解决这样问题的存在，通过 Histogram 和 Summary 类型的监控指标，可以快速了解监控样本的分布情况。

### Histogram 和 Summary 示例

例如，指标 `prometheus_tsdb_wal_fsync_duration_seconds` 的指标类型为 Summary。 它记录了 Prometheus Server 中 wal_fsync 处理的处理时间，通过访问 Prometheus Server 的 `/metrics` 地址，可以获取到以下监控样本数据：

```plain
# HELP prometheus_tsdb_wal_fsync_duration_seconds Duration of WAL fsync.
# TYPE prometheus_tsdb_wal_fsync_duration_seconds summary
prometheus_tsdb_wal_fsync_duration_seconds{quantile="0.5"} 0.012352463
prometheus_tsdb_wal_fsync_duration_seconds{quantile="0.9"} 0.014458005
prometheus_tsdb_wal_fsync_duration_seconds{quantile="0.99"} 0.017316173
prometheus_tsdb_wal_fsync_duration_seconds_sum 2.888716127000002
prometheus_tsdb_wal_fsync_duration_seconds_count 216
```

从上面的样本中可以得知当前 Prometheus Server 进行 wal_fsync 操作的总次数为 216 次，耗时 `2.888716127000002s`。

其中

- 中位数（quantile=0.5）的耗时为0.012352463
- 9 分位数（quantile=0.9）的耗时为 0.014458005s。

在 Prometheus Server 自身返回的样本数据中，还能找到类型为 Histogram 的监控指标 `prometheus_tsdb_compaction_chunk_range_bucket`。

```plain
# HELP prometheus_tsdb_compaction_chunk_range Final time range of chunks on their first compaction
# TYPE prometheus_tsdb_compaction_chunk_range histogram
prometheus_tsdb_compaction_chunk_range_bucket{le="100"} 0
prometheus_tsdb_compaction_chunk_range_bucket{le="400"} 0
prometheus_tsdb_compaction_chunk_range_bucket{le="1600"} 0
prometheus_tsdb_compaction_chunk_range_bucket{le="6400"} 0
prometheus_tsdb_compaction_chunk_range_bucket{le="25600"} 0
prometheus_tsdb_compaction_chunk_range_bucket{le="102400"} 0
prometheus_tsdb_compaction_chunk_range_bucket{le="409600"} 0
prometheus_tsdb_compaction_chunk_range_bucket{le="1.6384e+06"} 260
prometheus_tsdb_compaction_chunk_range_bucket{le="6.5536e+06"} 780
prometheus_tsdb_compaction_chunk_range_bucket{le="2.62144e+07"} 780
prometheus_tsdb_compaction_chunk_range_bucket{le="+Inf"} 780
prometheus_tsdb_compaction_chunk_range_sum 1.1540798e+09
prometheus_tsdb_compaction_chunk_range_count 780
```

与 Summary 类型的指标相似之处在于 Histogram 类型的样本同样会反应当前指标的记录的总数（以 `_count`作为后缀）以及其值的总量（以 `_sum` 作为后缀）。

不同在于 Histogram 指标直接反应了在不同区间内样本的个数，区间通过标签 le 进行定义。

### 分位数的计算选择 Sumamry / Histogram

同时对于 Histogram 的指标，还可以通过 `histogram_quantile()` 函数计算出其值的分位数。

不同在于 Histogram 通过 histogram_quantile 函数是在服务器端计算的分位数。 而 Sumamry 的分位数则是直接在客户端计算完成。

因此对于分位数的计算而言，Summary 在通过 PromQL 进行查询时有更好的性能表现，而 Histogram 则会消耗更多的资源。反之对于客户端而言 Histogram 消耗的资源更少。

在选择这两种方式时用户应该按照自己的实际场景进行选择。
