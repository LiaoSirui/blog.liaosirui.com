使用 PromQL 除了能够方便的按照查询和过滤时间序列以外，PromQL还支持丰富的操作符，用户可以使用这些操作符对进一步的对事件序列进行二次加工。这些操作符包括：数学运算符，逻辑运算符，布尔运算符等等

官方文档：

- <https://prometheus.io/docs/prometheus/latest/querying/operators/#binary-operators>
- <https://prometheus.io/docs/prometheus/latest/querying/operators/#vector-matching>
- <https://prometheus.io/docs/prometheus/latest/querying/operators/#aggregation-operators>

## 数学运算

例如，我们可以通过指标 node_memory_free_bytes_total 获取当前主机可用的内存空间大小，其样本单位为 Bytes。这是如果客户端要求使用 MB 作为单位响应数据，那只需要将查询到的时间序列的样本值进行单位换算即可：

```promql
node_memory_free_bytes_total / (1024 * 1024)
```

node_memory_free_bytes_total 表达式会查询出所有满足表达式条件的时间序列，该表达式为瞬时向量表达式，而返回的结果成为瞬时向量。当瞬时向量与标量之间进行数学运算时，数学运算符会依次作用域瞬时向量中的每一个样本值，从而得到一组新的时间序列。

而如果是瞬时向量与瞬时向量之间进行数学运算时，过程会相对复杂一点。 例如，如果想根据 node_disk_bytes_written 和 node_disk_bytes_read 获取主机磁盘 IO 的总量，可以使用如下表达式：

```promql
node_disk_bytes_written + node_disk_bytes_read
```

那这个表达式是如何工作的呢？依次找到与左边向量元素匹配（标签完全一致）的右边向量元素进行运算，如果没找到匹配元素，则直接丢弃。同时新的时间序列将不会包含指标名称。 该表达式返回结果的示例如下所示：

```promql
{device="sda",instance="localhost:9100",job="node_exporter"}=>1634967552@1518146427.807 + 864551424@1518146427.807
{device="sdb",instance="localhost:9100",job="node_exporter"}=>0@1518146427.807 + 1744384@1518146427.807
```

PromQL 支持的所有数学运算符如下所示：

- `+` (加法)
- `-` (减法)
- `*` (乘法)
- `/` (除法)
- `%` (求余)
- `^` (幂运算)

## 布尔运算过滤时间序列

在 PromQL 通过标签匹配模式，用户可以根据时间序列的特征维度对其进行查询。而布尔运算则支持用户根据时间序列中样本的值，对时间序列进行过滤。

例如，通过数学运算符我们可以很方便的计算出，当前所有主机节点的内存使用率：

```promql
(node_memory_bytes_total - node_memory_free_bytes_total) / node_memory_bytes_total
```

而系统管理员在排查问题的时候可能只想知道当前内存使用率超过 95% 的主机呢？通过使用布尔运算符可以方便的获取到该结果：

```promql
(node_memory_bytes_total - node_memory_free_bytes_total) / node_memory_bytes_total > 0.95
```

瞬时向量与标量进行布尔运算时，PromQL 依次比较向量中的所有时间序列样本的值，如果比较结果为 true 则保留，反之丢弃。

瞬时向量与瞬时向量直接进行布尔运算时，同样遵循默认的匹配模式：依次找到与左边向量元素匹配（标签完全一致）的右边向量元素进行相应的操作，如果没找到匹配元素，则直接丢弃。

支持以下布尔运算符如下：

- `==` (相等)
- `!=` (不相等)
- `>` (大于)
- `<` (小于)
- `>=` (大于等于)
- `<=` (小于等于)

## bool 修饰符

布尔运算符的默认行为是对时序数据进行过滤。而在其它的情况下我们可能需要的是真正的布尔结果。例如，只需要知道当前模块的 HTTP 请求量是否 >=1000，如果大于等于 1000 则返回 1（true）否则返回 0（false）。这时可以使用 bool 修饰符改变布尔运算的默认行为。 例如：

```promql
http_requests_total > bool 1000
```

使用 bool 修改符后，布尔运算不会对时间序列进行过滤，而是直接依次瞬时向量中的各个样本数据与标量的比较结果 0 或者 1。从而形成一条新的时间序列

```promql
http_requests_total{code="200",handler="query",instance="localhost:9090",job="prometheus",method="get"}  1
http_requests_total{code="200",handler="query_range",instance="localhost:9090",job="prometheus",method="get"}  0
```

同时需要注意的是，如果是在两个标量之间使用布尔运算，则必须使用 bool 修饰符

```promql
2 == bool 2
# 结果为1
```

## 集合运算符

使用瞬时向量表达式能够获取到一个包含多个时间序列的集合，称为瞬时向量；通过集合运算，可以在两个瞬时向量与瞬时向量之间进行相应的集合操作

目前，Prometheus 支持以下集合运算符：

- `and` (并且)
- `or` (或者)
- `unless` (排除)

```promql
vector1 and vector2
```

and 会产生一个由 vector1 的元素组成的新的向量。该向量包含 vector1 中完全匹配 vector2 中的元素组成。

```promql
vector1 or vector2
```

or 会产生一个新的向量，该向量包含 vector1 中所有的样本数据，以及 vector2 中没有与 vector1 匹配到的样本数据。

```promql
vector1 unless vector2
```

unless 会产生一个新的向量，新向量中的元素由 vector1 中没有与 vector2 匹配的元素组成

## 操作符优先级

对于复杂类型的表达式，需要了解运算操作的运行优先级

例如，查询主机的 CPU 使用率，可以使用表达式：

```promql
100 * (1 - avg (irate(node_cpu{mode='idle'}[5m])) by(job) )
```

在 PromQL 操作符中优先级由高到低依次为：

1. `^`
2. `*, /, %`
3. `+, -`
4. `==, !=, <=, <, >=, >`
5. `and, unless`
6. `or`

## 匹配模式

向量与向量之间进行运算操作时会基于默认的匹配规则：依次找到与左边向量元素匹配（标签完全一致）的右边向量元素进行运算，如果没找到匹配元素，则直接丢弃。

PromQL 中匹配模式：一对一（one-to-one），多对一（many-to-one）或一对多（one-to-many）

### 一对一匹配

一对一匹配模式会从操作符两边表达式获取的瞬时向量依次比较并找到唯一匹配(标签完全一致)的样本值。默认情况下，使用表达式：

```promql
vector1 <operator> vector2
```

在操作符两边表达式标签不一致的情况下，可以使用 on (label list) 或者 ignoring (label list）来修改便签的匹配行为。使用 ignoreing 可以在匹配时忽略某些便签。而 on 则用于将匹配行为限定在某些便签之内

```promql
<vector expr> <bin-op> ignoring(<label list>) <vector expr>
<vector expr> <bin-op> on(<label list>) <vector expr>
```

例如当存在样本：

```promql
method_code:http_errors:rate5m{method="get", code="500"}  24
method_code:http_errors:rate5m{method="get", code="404"}  30
method_code:http_errors:rate5m{method="put", code="501"}  3
method_code:http_errors:rate5m{method="post", code="500"} 6
method_code:http_errors:rate5m{method="post", code="404"} 21

method:http_requests:rate5m{method="get"}  600
method:http_requests:rate5m{method="del"}  34
method:http_requests:rate5m{method="post"} 120
```

使用 PromQL 表达式：

```promql
method_code:http_errors:rate5m{code="500"} / ignoring(code) method:http_requests:rate5m
```

该表达式会返回在过去 5 分钟内，HTTP 请求状态码为 500 的在所有请求中的比例。如果没有使用 ignoring (code)，操作符两边表达式返回的瞬时向量中将找不到任何一个标签完全相同的匹配项

因此结果如下：

```promql
{method="get"}  0.04            //  24 / 600
{method="post"} 0.05            //   6 / 120
```

同时由于 method 为 put 和 del 的样本找不到匹配项，因此不会出现在结果当中

### 多对一和一对多

多对一和一对多两种匹配模式指的是 “一” 侧的每一个向量元素可以与 "多" 侧的多个元素匹配的情况。在这种情况下，必须使用 group 修饰符：group_left 或者 group_right 来确定哪一个向量具有更高的基数（充当 “多” 的角色）

```promql
<vector expr> <bin-op> ignoring(<label list>) group_left(<label list>) <vector expr>
<vector expr> <bin-op> ignoring(<label list>) group_right(<label list>) <vector expr>
<vector expr> <bin-op> on(<label list>) group_left(<label list>) <vector expr>
<vector expr> <bin-op> on(<label list>) group_right(<label list>) <vector expr>
```

多对一和一对多两种模式一定是出现在操作符两侧表达式返回的向量标签不一致的情况。因此需要使用 ignoring 和 on 修饰符来排除或者限定匹配的标签列表

例如使用表达式：

```promql
method_code:http_errors:rate5m / ignoring(code) group_left method:http_requests:rate5m
```

该表达式中，左向量 `method_code:http_errors:rate5m` 包含两个标签 method 和 code；而右向量 `method:http_requests:rate5m` 中只包含一个标签 method，因此匹配时需要使用 ignoring 限定匹配的标签为 code。

在限定匹配标签后，右向量中的元素可能匹配到多个左向量中的元素 因此该表达式的匹配模式为多对一，需要使用 group 修饰符 group_left 指定左向量具有更好的基数

最终的运算结果如下：

```promql
{method="get", code="500"}  0.04            //  24 / 600
{method="get", code="404"}  0.05            //  30 / 600
{method="post", code="500"} 0.05            //   6 / 120
{method="post", code="404"} 0.175           //  21 / 120
```

group 修饰符只能在比较和数学运算符中使用。在逻辑运算 and,unless 和 or 才注意操作中默认与右向量中的所有元素进行匹配。

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

### 聚合操作的语法

使用聚合操作的语法如下：

```promql
<aggr-op>([parameter,] <vector expression>) [without|by (<label list>)]
```

其中只有 `count_values`, `quantile`, `topk`, `bottomk`支持参数(parameter)。

通过 without 和 by 可以按照样本的问题对数据进行聚合

- without 用于从计算结果中移除列举的标签，而保留其它标签
- by 则正好相反，结果向量中只保留列出的标签，其余标签则移除

例如：

```promql
sum(http_requests_total) without (instance)
```

等价于

```promql
sum(http_requests_total) by (code, handler, job, method)
```

如果只需要计算整个应用的 HTTP 请求总量，可以直接使用表达式：

```promql
sum(http_requests_total)
```

### count_values

count_values 用于时间序列中每一个样本值出现的次数。count_values 会为每一个唯一的样本值输出一个时间序列，并且每一个时间序列包含一个额外的标签

例如：

```promql
count_values("count", http_requests_total)
```

### topk 和 bottomk

topk 和 bottomk 则用于对样本值进行排序，返回当前样本值前 n 位，或者后 n 位的时间序列。

获取 HTTP 请求数前 5 位的时序样本数据，可以使用表达式：

```promql
topk(5, http_requests_total)
```

### quantile

quantile 用于计算当前样本数据值的分布情况 `quantile(φ, express)` 其中0 ≤ `φ` ≤ 1

例如，当 `φ` 为 0.5 时，即表示找到当前样本数据中的中位数：

```promql
quantile(0.5, http_requests_total)
```
