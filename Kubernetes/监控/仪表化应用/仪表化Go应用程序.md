## 创建应用

首先从一个最简单的 Go 应用程序开始，在端口 8080 的 `/metrics` 端点上暴露客户端库的默认指标。

先创建一个名为 `metrics-go-demo` 的目录，在该目录下面初始化项目：

```bash
mkcd metrics-go-demo
go mod init code.liaosirui.com/demo/metrics-go-demo
```

上面的命令会在 `metrics-go-demo` 目录下面生成一个 `go.mod` 文件，在同目录下面新建一个 `main.go` 的入口文件，内容如下所示：

```go
package main

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// Serve the default Prometheus metrics registry over HTTP on /metrics.
	http.Handle("/metrics", promhttp.Handler())
	http.ListenAndServe(":8080", nil)
}

```

将 prometheus 指标集成到你的服务中的第一步是初始化 HTTP 服务器以提供 Prometheus 指标，这里使用 prometheus 的 go sdk 提供的 `promhttp.Handler()` 方法来提供默认的 metrics 数据。

然后执行下面的命令下载 Prometheus 客户端库依赖：

```bash
go mod tidy
go mod vendor
```

然后直接执行 `go run` 命令启动服务：

```bash
go run ./main.go
```

请求监控指标数据：

```bash
> curl http://127.0.0.1:8080/metrics

# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0
go_gc_duration_seconds{quantile="0.25"} 0
go_gc_duration_seconds{quantile="0.5"} 0
go_gc_duration_seconds{quantile="0.75"} 0
go_gc_duration_seconds{quantile="1"} 0
go_gc_duration_seconds_sum 0
go_gc_duration_seconds_count 0
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 6
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.18.9"} 1
# HELP go_memstats_alloc_bytes Number of bytes allocated and still in use.
# TYPE go_memstats_alloc_bytes gauge
go_memstats_alloc_bytes 1.971264e+06
# HELP go_memstats_alloc_bytes_total Total number of bytes allocated, even if freed.
# TYPE go_memstats_alloc_bytes_total counter
go_memstats_alloc_bytes_total 1.971264e+06
# HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table.
# TYPE go_memstats_buck_hash_sys_bytes gauge
go_memstats_buck_hash_sys_bytes 4263
# HELP go_memstats_frees_total Total number of frees.
# TYPE go_memstats_frees_total counter
go_memstats_frees_total 0
# HELP go_memstats_gc_sys_bytes Number of bytes used for garbage collection system metadata.
# TYPE go_memstats_gc_sys_bytes gauge
go_memstats_gc_sys_bytes 3.524216e+06
# HELP go_memstats_heap_alloc_bytes Number of heap bytes allocated and still in use.
# TYPE go_memstats_heap_alloc_bytes gauge
go_memstats_heap_alloc_bytes 1.971264e+06
# HELP go_memstats_heap_idle_bytes Number of heap bytes waiting to be used.
# TYPE go_memstats_heap_idle_bytes gauge
go_memstats_heap_idle_bytes 1.777664e+06
# HELP go_memstats_heap_inuse_bytes Number of heap bytes that are in use.
# TYPE go_memstats_heap_inuse_bytes gauge
go_memstats_heap_inuse_bytes 1.990656e+06
# HELP go_memstats_heap_objects Number of allocated objects.
# TYPE go_memstats_heap_objects gauge
go_memstats_heap_objects 14624
# HELP go_memstats_heap_released_bytes Number of heap bytes released to OS.
# TYPE go_memstats_heap_released_bytes gauge
go_memstats_heap_released_bytes 1.777664e+06
# HELP go_memstats_heap_sys_bytes Number of heap bytes obtained from system.
# TYPE go_memstats_heap_sys_bytes gauge
go_memstats_heap_sys_bytes 3.76832e+06
# HELP go_memstats_last_gc_time_seconds Number of seconds since 1970 of last garbage collection.
# TYPE go_memstats_last_gc_time_seconds gauge
go_memstats_last_gc_time_seconds 0
# HELP go_memstats_lookups_total Total number of pointer lookups.
# TYPE go_memstats_lookups_total counter
go_memstats_lookups_total 0
# HELP go_memstats_mallocs_total Total number of mallocs.
# TYPE go_memstats_mallocs_total counter
go_memstats_mallocs_total 14624
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures.
# TYPE go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_inuse_bytes 38400
# HELP go_memstats_mcache_sys_bytes Number of bytes used for mcache structures obtained from system.
# TYPE go_memstats_mcache_sys_bytes gauge
go_memstats_mcache_sys_bytes 46800
# HELP go_memstats_mspan_inuse_bytes Number of bytes in use by mspan structures.
# TYPE go_memstats_mspan_inuse_bytes gauge
go_memstats_mspan_inuse_bytes 40896
# HELP go_memstats_mspan_sys_bytes Number of bytes used for mspan structures obtained from system.
# TYPE go_memstats_mspan_sys_bytes gauge
go_memstats_mspan_sys_bytes 48816
# HELP go_memstats_next_gc_bytes Number of heap bytes when next garbage collection will take place.
# TYPE go_memstats_next_gc_bytes gauge
go_memstats_next_gc_bytes 4.194304e+06
# HELP go_memstats_other_sys_bytes Number of bytes used for other system allocations.
# TYPE go_memstats_other_sys_bytes gauge
go_memstats_other_sys_bytes 655217
# HELP go_memstats_stack_inuse_bytes Number of bytes in use by the stack allocator.
# TYPE go_memstats_stack_inuse_bytes gauge
go_memstats_stack_inuse_bytes 425984
# HELP go_memstats_stack_sys_bytes Number of bytes obtained from system for stack allocator.
# TYPE go_memstats_stack_sys_bytes gauge
go_memstats_stack_sys_bytes 425984
# HELP go_memstats_sys_bytes Number of bytes obtained from system.
# TYPE go_memstats_sys_bytes gauge
go_memstats_sys_bytes 8.473616e+06
# HELP go_threads Number of OS threads created.
# TYPE go_threads gauge
go_threads 8
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0
# HELP process_max_fds Maximum number of open file descriptors.
# TYPE process_max_fds gauge
process_max_fds 524288
# HELP process_open_fds Number of open file descriptors.
# TYPE process_open_fds gauge
process_open_fds 14
# HELP process_resident_memory_bytes Resident memory size in bytes.
# TYPE process_resident_memory_bytes gauge
process_resident_memory_bytes 2.0893696e+07
# HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
process_start_time_seconds 1.67627500178e+09
# HELP process_virtual_memory_bytes Virtual memory size in bytes.
# TYPE process_virtual_memory_bytes gauge
process_virtual_memory_bytes 1.11161344e+09
# HELP process_virtual_memory_max_bytes Maximum amount of virtual memory available in bytes.
# TYPE process_virtual_memory_max_bytes gauge
process_virtual_memory_max_bytes 1.8446744073709552e+19
# HELP promhttp_metric_handler_requests_in_flight Current number of scrapes being served.
# TYPE promhttp_metric_handler_requests_in_flight gauge
promhttp_metric_handler_requests_in_flight 1
# HELP promhttp_metric_handler_requests_total Total number of scrapes by HTTP status code.
# TYPE promhttp_metric_handler_requests_total counter
promhttp_metric_handler_requests_total{code="200"} 0
promhttp_metric_handler_requests_total{code="500"} 0
promhttp_metric_handler_requests_total{code="503"} 0
```

并没有在代码中添加什么业务逻辑，但是可以看到依然有一些指标数据输出，这是因为 Go 客户端库默认在暴露的全局默认指标注册表中注册了一些关于 `promhttp` 处理器和运行时间相关的默认指标，根据不同指标名称的前缀可以看出：

- `go_*`：以 `go_` 为前缀的指标是关于 Go 运行时相关的指标，比如垃圾回收时间、goroutine 数量等，这些都是 Go 客户端库特有的，其他语言的客户端库可能会暴露各自语言的其他运行时指标。
- `promhttp_*`：来自 `promhttp` 工具包的相关指标，用于跟踪对指标请求的处理。

这些默认的指标是非常有用，但是更多的时候需要自己控制，来暴露一些自定义指标。

## 添加自定义指标

接下来来自定义一个的 `gauge` 指标来暴露当前的温度。创建一个新的文件 `custom-metric/main.go`，内容如下所示：

```go
package main

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// 创建一个没有任何 label 标签的 gauge 指标
	temp := prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "home_temperature_celsius",
		Help: "The current temperature in degrees Celsius.",
	})

	// 在默认的注册表中注册该指标
	prometheus.MustRegister(temp)

	// 设置 gauge 的值为 39
	temp.Set(39)

	// 暴露指标
	http.Handle("/metrics", promhttp.Handler())
	http.ListenAndServe(":8080", nil)
}

```

上面文件中和最初的文件就有一些变化了：

- 使用 `prometheus.NewGauge()` 函数创建了一个自定义的 gauge 指标对象，指标名称为 `home_temperature_celsius`，并添加了一个注释信息。
- 然后使用 `prometheus.MustRegister()` 函数在默认的注册表中注册了这个 gauge 指标对象。
- 通过调用 `Set()` 方法将 gauge 指标的值设置为 39。
- 然后像之前一样通过 HTTP 暴露默认的注册表。

需要注意的是除了 `prometheus.MustRegister()` 函数之外还有一个 `prometheus.Register()` 函数，一般在 golang 中会将 `Mustxxx` 开头的函数定义为必须满足条件的函数，如果不满足会返回一个 panic 而不是一个 error 操作，所以如果这里不能正常注册的话会抛出一个 panic。

现在来运行这个程序：

```
go run ./custom-metric
```

启动后重新访问指标接口 `http://127.0.0.1:8080/metrics`，仔细对比会发现多了一个名为 `home_temperature_celsius` 的指标：

```bash
> curl http://127.0.0.1:8080/metrics

...
# HELP go_threads Number of OS threads created.
# TYPE go_threads gauge
go_threads 9
# HELP home_temperature_celsius The current temperature in degrees Celsius.
# TYPE home_temperature_celsius gauge
home_temperature_celsius 39
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0
...
```

这样就实现了添加一个自定义的指标的操作，整体比较简单，当然在实际的项目中需要结合业务来确定添加哪些自定义指标。

## 自定义注册表

前面使用 `prometheus.MustRegister()` 函数来将指标注册到全局默认注册中，此外还可以使用 `prometheus.NewRegistry()` 函数来创建和使用自己的非全局的注册表。

既然有全局的默认注册表，为什么还需要自定义注册表呢？这主要是因为：

- 全局变量通常不利于维护和测试，创建一个非全局的注册表，并明确地将其传递给程序中需要注册指标的地方，这也一种更加推荐的做法。
- 全局默认注册表包括一组默认的指标，有时候可能希望除了自定义的指标之外，不希望暴露其他的指标。

下面的示例程序演示了如何创建、使用和暴露一个非全局注册表对象，创建一个文件 `custom-registry/main.go`，内容如下所示：

```go
package main

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
  // "github.com/prometheus/client_golang/prometheus/controllers"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// 创建一个自定义的注册表
	registry := prometheus.NewRegistry()

	// 可选: 添加 process 和 Go 运行时指标到自定义的注册表中
	// registry.MustRegister(collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}))
	// registry.MustRegister(collectors.NewGoCollector())

	// 创建一个简单的 gauge 指标。
	temp := prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "home_temperature_celsius",
		Help: "The current temperature in degrees Celsius.",
	})

	// 使用自定义的注册表注册 gauge
	registry.MustRegister(temp)

	// 设置 gague 的值为 39
	temp.Set(39)

	// 暴露自定义指标
	http.Handle("/metrics", promhttp.HandlerFor(registry, promhttp.HandlerOpts{Registry: registry}))
	http.ListenAndServe(":8080", nil)
}

```

上面没有使用全局默认的注册表，而是创建的一个自定义的注册表：

- 首先使用 `prometheus.NewRegistry()` 函数创建自己的注册表对象。
- 然后使用自定义注册表对象上面的 `MustRegister()` 来注册 guage 指标，而不是调用 `prometheus.MustRegister()` 函数（这会使用全局默认的注册表）。
- 如果希望在自定义注册表中也有进程和 Go 运行时相关的指标，可以通过实例化 `Collector` 收集器来添加他们。
- 最后在暴露指标的时候必须通过调用 `promhttp.HandleFor()` 函数来创建一个专门针对自定义注册表的 HTTP 处理器，为了同时暴露前面示例中的 `promhttp_*` 相关的指标，还需要在 `promhttp.HandlerOpts` 配置对象的 `Registry` 字段中传递注册表对象。

同样重新运行上面的自定义注册表程序：

```
> go run ./custom-metric
```

启动后再次访问指标接口 `http://localhost:8080/metrics`，可以发现和上面示例中的指标数据是相同的。

```bash
> curl http://127.0.0.1:8080/metrics 

# HELP home_temperature_celsius The current temperature in degrees Celsius.
# TYPE home_temperature_celsius gauge
home_temperature_celsius 39
# HELP promhttp_metric_handler_errors_total Total number of internal errors encountered by the promhttp metric handler.
# TYPE promhttp_metric_handler_errors_total counter
promhttp_metric_handler_errors_total{cause="encoding"} 0
promhttp_metric_handler_errors_total{cause="gathering"} 0
```

## 指标定制

### Gauges

前面的示例已经了解了如何添加 gauge 类型的指标，创建了一个没有任何标签的指标，直接使用 `prometheus.NewGauge()` 函数即可实例化一个 gauge 类型的指标对象，通过 `prometheus.GaugeOpts` 对象可以指定指标的名称和注释信息：

```go
queueLength := prometheus.NewGauge(prometheus.GaugeOpts{
    Name: "queue_length",
    Help: "The number of items in the queue.",
})
```

知道 gauge 类型的指标值是可以上升或下降的，所以可以为 gauge 指标设置一个指定的值，所以 gauge 指标对象暴露了 `Set()`、`Inc()`、`Dec()`、`Add()` 和 `Sub()` 这些函数来更改指标值：

```go
// 使用 Set() 设置指定的值
queueLength.Set(0)

// 增加或减少
queueLength.Inc()   // +1：Increment the gauge by 1.
queueLength.Dec()   // -1：Decrement the gauge by 1.
queueLength.Add(23) // Increment by 23.
queueLength.Sub(42) // Decrement by 42.
```

另外 gauge 仪表盘经常被用来暴露 Unix 的时间戳样本值，所以也有一个方便的方法来将 gauge 设置为当前的时间戳：

```go
demoTimestamp.SetToCurrentTime()
```

最终 gauge 指标会被渲染成如下所示的数据：

```go
# HELP queue_length The number of items in the queue.
# TYPE queue_length gauge
queue_length 42
```

### Counters

要创建一个 counter 类型的指标和 gauge 比较类似，只是用 `prometheus.NewCounter()` 函数来初始化指标对象：

```go
totalRequests := prometheus.NewCounter(prometheus.CounterOpts{
    Name: "http_requests_total",
    Help: "The total number of handled HTTP requests.",
})
```

知道 counter 指标只能随着时间的推移而不断增加，所以不能为其设置一个指定的值或者减少指标值，所以该对象下面只有 `Inc()` 和 `Add()` 两个函数：

```go
totalRequests.Inc()   // +1：Increment the counter by 1.
totalRequests.Add(23) // +n：Increment the counter by 23.
```

当服务进程重新启动的时候，counter 指标值会被重置为 0，不过不用担心数据错乱，一般会使用的 `rate()` 函数会自动处理。

最终 counter 指标会被渲染成如下所示的数据：

```
# HELP http_requests_total The total number of handled HTTP requests.
# TYPE http_requests_total counter
http_requests_total 7734
```

### Histograms

创建直方图指标比 counter 和 gauge 都要复杂，因为需要配置把观测值归入的 bucket 的数量，以及每个 bucket 的上边界。

Prometheus 中的直方图是累积的，所以每一个后续的 bucket 都包含前一个 bucket 的观察计数，所有 bucket 的下限都从 0 开始的，所以不需要明确配置每个 bucket 的下限，只需要配置上限即可。

同样要创建直方图指标对象，使用 `prometheus.NewHistogram()` 函数来进行初始化：

```go
requestDurations := prometheus.NewHistogram(prometheus.HistogramOpts{
  Name:    "http_request_duration_seconds",
  Help:    "A histogram of the HTTP request durations in seconds.",
  // Bucket 配置：第一个 bucket 包括所有在 0.05s 内完成的请求，最后一个包括所有在10s内完成的请求。
  Buckets: []float64{0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
})
```

这里和前面不一样的地方在于除了指定指标名称和帮助信息之外，还需要配置 Buckets。

如果手动去枚举所有的 bucket 可能很繁琐，所以 Go 客户端库提供了一些辅助函数可以帮助生成线性或者指数增长的 bucket，比如 `prometheus.LinearBuckets()` 和 `prometheus.ExponentialBuckets()` 函数。

直方图会自动对数值的分布进行分类和计数，所以它只有一个 `Observe()` 方法，每当你在代码中处理要跟踪的数据时，就会调用这个方法。例如，如果刚刚处理了一个 HTTP 请求，花了 0.42 秒，则可以使用下面的代码来跟踪。

```go
requestDurations.Observe(0.42)
```

由于跟踪持续时间是直方图的一个常见用例，Go 客户端库就提供了辅助函数，用于对代码的某些部分进行计时，然后自动观察所产生的持续时间，将其转化为直方图，如下代码所示：

```go
// 启动一个计时器
timer := prometheus.NewTimer(requestDurations)

// [...在应用中处理请求...]

// 停止计时器并观察其持续时间，将其放进 requestDurations 的直方图指标中去
timer.ObserveDuration()
```

直方图指标最终会生成如下所示的数据：

```go
# HELP http_request_duration_seconds A histogram of the HTTP request durations in seconds.
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.05"} 4599
http_request_duration_seconds_bucket{le="0.1"} 24128
http_request_duration_seconds_bucket{le="0.25"} 45311
http_request_duration_seconds_bucket{le="0.5"} 59983
http_request_duration_seconds_bucket{le="1"} 60345
http_request_duration_seconds_bucket{le="2.5"} 114003
http_request_duration_seconds_bucket{le="5"} 201325
http_request_duration_seconds_bucket{le="+Inf"} 227420
http_request_duration_seconds_sum 88364.234
http_request_duration_seconds_count 227420
```

每个配置的存储桶最终作为一个带有 `_bucket` 后缀的计数器时间序列，使用 `le（小于或等于）` 标签指示该存储桶的上限，具有上限的隐式存储桶 `+Inf` 也暴露于比最大配置的存储桶边界花费更长的时间的请求，还包括使用后缀 `_sum` 累积总和和计数 `_count` 的指标，这些时间序列中的每一个在概念上都是一个 counter 计数器（只能上升的单个值），只是它们是作为直方图的一部分创建的。

### Summaries

创建和使用摘要与直方图非常类似，只是需要指定要跟踪的 quantiles 分位数值，而不需要处理 bucket 桶，比如想要跟踪 HTTP 请求延迟的第 50、90 和 99 个百分位数，那么可以创建这样的一个摘要对象：

```go
requestDurations := prometheus.NewSummary(prometheus.SummaryOpts{
    Name:       "http_request_duration_seconds",
    Help:       "A summary of the HTTP request durations in seconds.",
    Objectives: map[float64]float64{
      0.5: 0.05,   // 第50个百分位数，最大绝对误差为0.05。
      0.9: 0.01,   // 第90个百分位数，最大绝对误差为0.01。
      0.99: 0.001, // 第90个百分位数，最大绝对误差为0.001。
    },
  },
)
```

这里和前面不一样的地方在于使用 `prometheus.NewSummary()` 函数初始化摘要指标对象的时候，需要通过 `prometheus.SummaryOpts{}` 对象的 `Objectives` 属性指定想要跟踪的分位数值。

同样摘要指标对象创建后，跟踪持续时间的方式和直方图是完全一样的，使用一个 `Observe()` 函数即可：

```go
requestDurations.Observe(0.42)
```

摘要指标最终生成的指标数据与直方图非常类似，不同之处在于使用 `quantile` 标签来表示分位数序列，并且这些序列没有扩展指标名称的后缀：

```go
# HELP http_request_duration_seconds A summary of the HTTP request durations in seconds.
# TYPE http_request_duration_seconds summary
http_request_duration_seconds{quantile="0.5"} 0.052
http_request_duration_seconds{quantile="0.90"} 0.564
http_request_duration_seconds{quantile="0.99"} 2.372
http_request_duration_seconds_sum 88364.234
http_request_duration_seconds_count 227420
```

### 标签

到目前为止，还没有为指标对象添加任何的标签，要创建具有标签维度的指标，可以调用类似于 `NewXXXVec()` 的构造函数来初始化指标对象：

- `NewGauge()` 变成 `NewGaugeVec()`
- `NewCounter()` 变成 `NewCounterVec()`
- `NewSummary()` 变成 `NewSummaryVec()`
- `NewHistogram()` 变成 `NewHistogramVec()`

这些函数允许指定一个额外的字符串切片参数，提供标签名称的列表，通过它来分割指标。

例如，为了按照房子以及测量温度的房间来划分早期的温度表指标，可以这样创建指标。

```go
temp := prometheus.NewGaugeVec(
  prometheus.GaugeOpts{
    Name: "home_temperature_celsius",
    Help: "The current temperature in degrees Celsius.",
  },
  // 两个标签名称，通过它们来分割指标。
  []string{"house", "room"},
)
```

然后要访问一个特有标签的子指标，需要在设置其值之前，用 `house` 和 `room` 标签的各自数值，对产生的 gauge 向量调用 `WithLabelValues()` 方法来处理下：

```go
// 为 home=ydzs 和 room=living-room 设置指标值
temp.WithLabelValues("ydzs", "living-room").Set(27)
```

如果喜欢在选择的子指标中明确提供标签名称，可以使用效率稍低的 `With()` 方法来代替：

```go
temp.With(prometheus.Labels{"house": "ydzs", "room": "living-room"}).Set(66)
```

不过需要注意如果向这两个方法传递不正确的标签数量或不正确的标签名称，这两个方法都会触发 panic。

下面是按照 `house` 和 `room` 标签维度区分指标的完整示例，创建一个名为 `label-metric/main.go` 的新文件，内容如下所示：

```go
package main

import (
    "net/http"

    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
    // 创建带 house 和 room 标签的 gauge 指标对象
    temp := prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "home_temperature_celsius",
            Help: "The current temperature in degrees Celsius.",
        },
        // 指定标签名称
        []string{"house", "room"},
    )

    // 注册到全局默认注册表中
    prometheus.MustRegister(temp)

    // 针对不同标签值设置不同的指标值
    temp.WithLabelValues("cnych", "living-room").Set(27)
    temp.WithLabelValues("cnych", "bedroom").Set(25.3)
    temp.WithLabelValues("ydzs", "living-room").Set(24.5)
    temp.WithLabelValues("ydzs", "bedroom").Set(27.7)

    // 暴露自定义的指标
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8080", nil)
}
```

上面代码非常清晰了，运行下面的程序：

```bash
go run ./label-metric
```

启动完成后重新访问指标端点 `http://localhost:8080/metrics`，可以找到 `home_temperature_celsius` 指标不同标签维度下面的指标值：

```plain
...
# HELP home_temperature_celsius The current temperature in degrees Celsius.
# TYPE home_temperature_celsius gauge
home_temperature_celsius{house="cnych",room="bedroom"} 25.3
home_temperature_celsius{house="cnych",room="living-room"} 27
home_temperature_celsius{house="ydzs",room="bedroom"} 27.7
home_temperature_celsius{house="ydzs",room="living-room"} 24.5
...
```

> 注意：当使用带有标签维度的指标时，任何标签组合的时间序列只有在该标签组合被访问过至少一次后才会出现在 `/metrics` 输出中，这对在 PromQL 查询的时候会产生一些问题，因为它希望某些时间序列一直存在，可以在程序第一次启动时，将所有重要的标签组合预先初始化为默认值。

同样的方式在其他几个指标类型中使用标签的方法与上面的方式一致。
