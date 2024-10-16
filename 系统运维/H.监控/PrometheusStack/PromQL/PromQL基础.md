
## 嵌套结构

与 SQL 查询语言（`SELECT * FROM ...`）不同，PromQL 是一种嵌套的函数式语言，就是要把需要查找的数据描述成一组嵌套的表达式，每个表达式都会评估为一个中间值，每个中间值都会被用作它上层表达式中的参数，而查询的最外层表达式表示你可以在表格、图形中看到的最终返回值。

比如下面的查询语句：

```promsql
histogram_quantile(  # 查询的根，最终结果表示一个近似分位数。
  0.9,  # histogram_quantile() 的第一个参数，分位数的目标值
  sum by(le, method, path) ( # histogram_quantile() 的第二个参数，聚合的直方图
    rate( # sum() 的参数，直方图过去 5 分钟每秒增量。
      # rate() 的参数，过去 5 分钟的原始直方图序列
      demo_api_request_duration_seconds_bucket{job="demo"}[5m]
    )
  )
)
```

PromQL 表达式不仅仅是整个查询，而是查询的任何嵌套部分（比如上面的 `rate(...)` 部分），你可以把它作为一个查询本身来运行。

在上面的例子中，每行注释代表一个表达式。

## 结果类型

- 抓取目标报告的指标类型：counter、gauge、histogram、summary。
- PromQL 表达式的结果数据类型：字符串、标量、瞬时向量或区间向量。

PromQL 实际上没有直接的指标类型的概念，只关注表达式的结果类型。每个 PromQL 表达式都有一个类型，每个函数、运算符或其他类型的操作都要求其参数是某种表达式类型。

例如，`rate()` 函数要求它的参数是一个区间向量，但是 `rate()` 本身评估为一个瞬时向量输出，所以 `rate()` 的结果只能用在期望是瞬时向量的地方。

### 字符串

字符串（string）只会作为某些函数（如 `label_join()` 和 `label_replace()`）的参数出现。

### 标量

标量（scalar）：一个单一的数字值，如 1.234，这些数字可以作为某些函数的参数，如 `histogram_quantile(0.9, ...)` 或 `topk(3, ...)`，也会出现在算术运算中。

### 瞬时向量

瞬时向量（instant vector）：一组标记的时间序列，每个序列有一个样本，都在同一个时间戳，瞬时向量可以由 TSDB 时间序列选择器直接产生，如 node_cpu_seconds_total，也可以由任何函数或其他转换来获取。

```plain
node_cpu_seconds_total{cpu="0", mode="idle"}   → 19165078.75 @ timestamp_1
node_cpu_seconds_total{cpu="0", mode="system"} →   381598.72 @ timestamp_1
node_cpu_seconds_total{cpu="0", mode="user"}   → 23211630.97 @ timestamp_1
```

### 区间向量

区间向量（range vector）：一组标记的时间序列，每个序列都有一个随时间变化的样本范围。

在 PromQL 中只有两种方法可以生成区间向量：

- 在查询中使用字面区间向量选择器（如 `node_cpu_seconds_total[5m]`）
- 或使用子查询表达式（如 `<expression>[5m:10s]`）

当想要在指定的时间窗口内聚合一个序列的行为时，区间向量非常有用，就像 `rate(node_cpu_seconds_total[5m])` 计算每秒增加率一样，在 node_cpu_seconds_total 指标的最后 5 分钟内求平均值。

```plain
node_cpu_seconds_total{cpu="0", mode="idle"}   → 19165078.75 @ timestamp_1,  19165136.3 @ timestamp_2, 19165167.72 @ timestamp_3
node_cpu_seconds_total{cpu="0", mode="system"} → 381598.72   @ timestamp_1,   381599.98 @ timestamp_2,   381600.58 @ timestamp_3
node_cpu_seconds_total{cpu="0", mode="user"}   → 23211630.97 @ timestamp_1, 23211711.34 @ timestamp_2, 23211748.64 @ timestamp_3
```

## 查询类型和评估时间

PromQL 查询中对时间的引用只有相对引用，比如 `[5m]`，表示过去 5 分钟

在 PromQL 中，这样的时间参数是与表达式分开发送到 Prometheus 查询 API 的，确切的时间参数取决于你发送的查询类型，Prometheus 有两种类型的 PromQL 查询：瞬时查询和区间查询。

### 瞬时查询

### 区间查询

## 聚合操作

提供了下列内置的聚合操作符，这些操作符作用域瞬时向量。可以将瞬时表达式返回的样本数据进行聚合，形成一个新的时间序列。

- `sum` (求和)
- `min` (最小值)
- `max` (最大值)
- `avg` (平均值)
- `stddev` (标准差)
- `stdvar` (标准方差)
- `count` (计数)
- `count_values` (对 value 进行计数)
- `bottomk` (后 n 条时序)
- `topk` (前 n 条时序)
- `quantile` (分位数)

使用聚合操作的语法如下：

```
<aggr-op>([parameter,] <vector expression>) [without|by (<label list>)]
```

其中只有`count_values`, `quantile`, `topk`, `bottomk`支持参数(parameter)。

without 用于从计算结果中移除列举的标签，而保留其它标签。by 则正好相反，结果向量中只保留列出的标签，其余标签则移除。通过 without 和 by 可以按照样本的问题对数据进行聚合

例如：

```
sum(http_requests_total) without (instance)
```

等价于

```
sum(http_requests_total) by (code, handler, job, method)
```

## 参考文档

- <https://www.volcengine.com/docs/6731/177124>
- <https://www.volcengine.com/docs/6731/177125>
- <https://www.volcengine.com/docs/6731/177123>