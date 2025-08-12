## 简介

Node Exporter 是基于 Prometheus 的 Client SDK 进行编写采集逻辑的，它本身内部也提供了很多可供的扩展机制。比如说它定义的 Collector 接口可以让用户进行扩展自定义自己的采集器逻辑。

## 启动入口

### 命令行参数

在 Node Exporter 根目录下可以看到一个名为 node_exporter.go 的文件，这是 Node Exporter 的程序启动入口，这个文件包含一个 main 函数。找到 main 函数可以看到它使用 kingpin 包定义了很多命令行参数，也有默认值：

<https://github.com/prometheus/node_exporter/blob/v1.9.1/node_exporter.go#L182-L203>

```go
func main() {
	var (
		metricsPath = kingpin.Flag(
			"web.telemetry-path",
			"Path under which to expose metrics.",
		).Default("/metrics").String()
		disableExporterMetrics = kingpin.Flag(
			"web.disable-exporter-metrics",
			"Exclude metrics about the exporter itself (promhttp_*, process_*, go_*).",
		).Bool()
		maxRequests = kingpin.Flag(
			"web.max-requests",
			"Maximum number of parallel scrape requests. Use 0 to disable.",
		).Default("40").Int()
		disableDefaultCollectors = kingpin.Flag(
			"collector.disable-defaults",
			"Set all collectors to disabled by default.",
		).Default("false").Bool()
		maxProcs = kingpin.Flag(
			"runtime.gomaxprocs", "The target number of CPUs Go will run on (GOMAXPROCS)",
		).Envar("GOMAXPROCS").Default("1").Int()
		toolkitFlags = kingpinflag.AddFlags(kingpin.CommandLine, ":9100")
	)
	// ...
}
```

- `metricsPath`：定义了获取指标的 HTTP URL，默认是 `/metrics`。
- `disableExporterMetrics`：定义了是否禁用 Exporter 自身的指标，比如说 `promhttp_*`、`process_*`、`go_*`。
- `maxRequests`：定义了并行采集请求的最大数量，默认是 40。设置 0 可以禁用。
- `disableDefaultCollectors`：定义了是否禁用默认的采集器，默认是 false，表示全部启用。
- `maxProcs`：定义了 Go 运行时最大逻辑处理器数量，默认是 1。
- `toolkitFlags`：定义了一些工具参数，这里是指启动的端口号为 `:9100`。

### 日志信息

打印了一些日志信息 <https://github.com/prometheus/node_exporter/blob/v1.9.1/node_exporter.go#L205-L222>

```go
promslogConfig := &promslog.Config{}
flag.AddFlags(kingpin.CommandLine, promslogConfig)
kingpin.Version(version.Print("node_exporter"))
kingpin.CommandLine.UsageWriter(os.Stdout)
kingpin.HelpFlag.Short('h')
kingpin.Parse()
logger := promslog.New(promslogConfig)

if *disableDefaultCollectors {
	collector.DisableDefaultCollectors()
}
logger.Info("Starting node_exporter", "version", version.Info())
logger.Info("Build context", "build_context", version.BuildContext())
if user, err := user.Current(); err == nil && user.Uid == "0" {
	logger.Warn("Node Exporter is running as root user. This exporter is designed to run as unprivileged user, root is not required.")
}
runtime.GOMAXPROCS(*maxProcs)
logger.Debug("Go MAXPROCS", "procs", runtime.GOMAXPROCS(0))
```

### 路由挂载

`newHandler` 函数，这个函数返回了 Node Exporter 自定义的 HTTP Handler，这个 Handler 借助了 Prometheus Client SDK 而实现的。

```go
func main() {
	// ...

	// 设置默认的路由对应的处理器，这边用的处理器是 Node Exporter 自定义的 Handler
	http.Handle(*metricsPath, newHandler(!*disableExporterMetrics, *maxRequests, logger))
	if *metricsPath != "/" {
		landingConfig := web.LandingConfig{
			Name:        "Node Exporter",
			Description: "Prometheus Node Exporter",
			Version:     version.Info(),
			Links: []web.LandingLinks{
				{
					Address: *metricsPath,
					Text:    "Metrics",
				},
			},
		}
		// 如果访问根路径，那么会显示一个内置的引导页面
		landingPage, err := web.NewLandingPage(landingConfig)
		if err != nil {
			logger.Error(err.Error())
			os.Exit(1)
		}
		http.Handle("/", landingPage)
	}

	// 启动服务器
	server := &http.Server{}
	if err := web.ListenAndServe(server, toolkitFlags, logger); err != nil {
		logger.Error(err.Error())
		os.Exit(1)
	}
}
```

## 自定义路由处理器

### handler 结构体

Node Exporter 自定义了一个 HTTP Handler 来处理请求，在 main 函数上面可以找到对应的实现：<https://github.com/prometheus/node_exporter/blob/v1.9.1/node_exporter.go#L41-L119>

```go
// handler wraps an unfiltered http.Handler but uses a filtered handler,
// created on the fly, if filtering is requested. Create instances with
// newHandler.
type handler struct {
	unfilteredHandler http.Handler
	// enabledCollectors list is used for logging and filtering
	enabledCollectors []string
	// exporterMetricsRegistry is a separate registry for the metrics about
	// the exporter itself.
	exporterMetricsRegistry *prometheus.Registry
	includeExporterMetrics  bool
	maxRequests             int
	logger                  *slog.Logger
}

func newHandler(includeExporterMetrics bool, maxRequests int, logger *slog.Logger) *handler {
	h := &handler{
		exporterMetricsRegistry: prometheus.NewRegistry(),
		includeExporterMetrics:  includeExporterMetrics,
		maxRequests:             maxRequests,
		logger:                  logger,
	}
	if h.includeExporterMetrics {
		h.exporterMetricsRegistry.MustRegister(
			promcollectors.NewProcessCollector(promcollectors.ProcessCollectorOpts{}),
			promcollectors.NewGoCollector(),
		)
	}

	// 这里就表示不传入过滤条件，把 unfilteredHandler 赋值为默认创建的 innerHandler
	if innerHandler, err := h.innerHandler(); err != nil {
		panic(fmt.Sprintf("Couldn't create metrics handler: %s", err))
	} else {
		h.unfilteredHandler = innerHandler
	}
	return h
}

// ServeHTTP implements http.Handler.
func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// 这里可以指定查询参数 collect[] 字段可以获取指定的采集器的指标
	collects := r.URL.Query()["collect[]"]
	h.logger.Debug("collect query:", "collects", collects)

	excludes := r.URL.Query()["exclude[]"]
	h.logger.Debug("exclude query:", "excludes", excludes)

	 // 没有过滤条件，那么就使用 unfilteredHandler 字段
	if len(collects) == 0 && len(excludes) == 0 {
		// No filters, use the prepared unfiltered handler.
		h.unfilteredHandler.ServeHTTP(w, r)
		return
	}

	if len(collects) > 0 && len(excludes) > 0 {
		h.logger.Debug("rejecting combined collect and exclude queries")
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Combined collect and exclude queries are not allowed."))
		return
	}

	filters := &collects
	if len(excludes) > 0 {
		// In exclude mode, filtered collectors = enabled - excludeed.
		f := []string{}
		for _, c := range h.enabledCollectors {
			if (slices.Index(excludes, c)) == -1 {
				f = append(f, c)
			}
		}
		filters = &f
	}

	// To serve filtered metrics, we create a filtering handler on the fly.
	// 有过滤条件，那就调用 innerHandler 方法传入过滤条件
	filteredHandler, err := h.innerHandler(*filters...)
	if err != nil {
		h.logger.Warn("Couldn't create filtered metrics handler:", "err", err)
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(fmt.Sprintf("Couldn't create filtered metrics handler: %s", err)))
		return
	}
	filteredHandler.ServeHTTP(w, r)
}
```

`handler` 结构体内部组合了一个 `http.Hanlder`，还有 Client SDK 的 `*prometheus.Registry` 以及其他几个不是太重要的字段。

`http` 包有一个 `Handler` 接口，定义了 `ServeHTTP` 方法，这里这个 `handler` 实现了 `ServeHTTP` 方法，也就是说它是 `Handler` 接口的子类型

调用 `ServerHTTP` 方法之前，必然先调用构造函数创建了 `handler` 的实例。在 `newHandler` 构造函数中，`exporterMetricsRegistry` 字段赋值使用了 Client SDK 提供的 `prometheus.NewRegistry()` 构造函数，这个构造函数可以自定义采集器注册器而不用 SDK 默认提供的 `DefaultRegisterer` 对象。

在 <https://github.com/prometheus/client_golang/blob/v1.20.5/prometheus/registry.go#L43-L58> 文件中可以看到如下定义：

```go
var (
	defaultRegistry              = NewRegistry()
	DefaultRegisterer Registerer = defaultRegistry
	DefaultGatherer   Gatherer   = defaultRegistry
)
```

在 `newHandler` 构造函数中，定义了 `handler` 结构体之后紧接着判断是否包含 Exporter 本身的指标，如果包含，那么就调用 `NewProcessCollector` 和 `NewGoCollector` 构造函数分别创建进程采集器和 Go 运行时采集器然后注册到 `handler` 内部的 `exporterMetricsRegistry` 注册器中。这样 SDK 的注册器中就知道有采集器注册。

### innerHandler 函数

最后调用了 `innerHandler` 函数，创建一个内部 `Handler` 对象用于做一些过滤操作。代码如下：<https://github.com/prometheus/node_exporter/blob/v1.9.1/node_exporter.go#L121-L179>

```go
// innerHandler is used to create both the one unfiltered http.Handler to be
// wrapped by the outer handler and also the filtered handlers created on the
// fly. The former is accomplished by calling innerHandler without any arguments
// (in which case it will log all the collectors enabled via command-line
// flags).
func (h *handler) innerHandler(filters ...string) (http.Handler, error) {
	// 这里调用了 NewNodeCollector 构造函数创建节点采集器对象
    // 注入 logger 对象和过滤器字符串可变参数
	nc, err := collector.NewNodeCollector(h.logger, filters...)
	if err != nil {
		return nil, fmt.Errorf("couldn't create collector: %s", err)
	}

	// Only log the creation of an unfiltered handler, which should happen
	// only once upon startup.
	// 没有过滤条件那么则启用所有的采集器，这里的采集器说的是子采集器
	if len(filters) == 0 {
		h.logger.Info("Enabled collectors")
		for n := range nc.Collectors {
			h.enabledCollectors = append(h.enabledCollectors, n)
		}
		sort.Strings(h.enabledCollectors)
		for _, c := range h.enabledCollectors {
			h.logger.Info(c)
		}
	}

	// 创建了一个新的注册器来注册采集器，这个采集器用于采集当前的版本信息
	r := prometheus.NewRegistry()
	r.MustRegister(versioncollector.NewCollector("node_exporter"))
	if err := r.Register(nc); err != nil {
		return nil, fmt.Errorf("couldn't register node collector: %s", err)
	}

	// 之前的一切工作都是为了这一步做准备，这里使用了 SDK 的 promhttp 包创建了一个新的 http.Handler
    // 第一个参数是 prometheus.Gatherers，它是 []Gatherer 的别名，意思是传递一个注册器切片
    // 因为 Registry 实现了 Gatherer 接口，重写了 Gather 方法所以可以传入进去
    // 而 Gatherers 又实现了 Gatherer 接口，所以可以传入 HandlerFor 函数
    // 第二个参数表示创建 Handler 的选项，传入了 h.exporterMetricsRegistry 的字段
	var handler http.Handler
	if h.includeExporterMetrics {
		handler = promhttp.HandlerFor(
			prometheus.Gatherers{h.exporterMetricsRegistry, r},
			promhttp.HandlerOpts{
				ErrorLog:            slog.NewLogLogger(h.logger.Handler(), slog.LevelError),
				ErrorHandling:       promhttp.ContinueOnError,
				MaxRequestsInFlight: h.maxRequests,
				Registry:            h.exporterMetricsRegistry,
			},
		)
		// Note that we have to use h.exporterMetricsRegistry here to
		// use the same promhttp metrics for all expositions.
		// 为了让所有的注册器的采集器都共用一个 Handler
		handler = promhttp.InstrumentMetricHandler(
			h.exporterMetricsRegistry, handler,
		)
	} else {
		handler = promhttp.HandlerFor(
			r,
			promhttp.HandlerOpts{
				ErrorLog:            slog.NewLogLogger(h.logger.Handler(), slog.LevelError),
				ErrorHandling:       promhttp.ContinueOnError,
				MaxRequestsInFlight: h.maxRequests,
			},
		)
	}

	return handler, nil
}
```

## Node Collector

### NewNodeCollector 函数

在 `innerHandler` 函数中，调用了 `NewNodeCollector` 函数：

```go
func (h *handler) innerHandler(filters ...string) (http.Handler, error) {
	// 这里调用了 NewNodeCollector 构造函数创建节点采集器对象
    // 注入 logger 对象和过滤器字符串可变参数
	nc, err := collector.NewNodeCollector(h.logger, filters...)
	// ...
}
```

这个构造函数用来创建 `NodeCollector` 实例，这个函数在 collector 包下的 collector.go 文件中，也是比较核心的代码：

<https://github.com/prometheus/node_exporter/blob/v1.9.1/collector/collector.go>

```go
// Namespace defines the common namespace to be used by all metrics.
const namespace = "node"

var (
	scrapeDurationDesc = prometheus.NewDesc(
		prometheus.BuildFQName(namespace, "scrape", "collector_duration_seconds"),
		"node_exporter: Duration of a collector scrape.",
		[]string{"collector"},
		nil,
	)
	scrapeSuccessDesc = prometheus.NewDesc(
		prometheus.BuildFQName(namespace, "scrape", "collector_success"),
		"node_exporter: Whether a collector succeeded.",
		[]string{"collector"},
		nil,
	)
)

const (
	defaultEnabled  = true
	defaultDisabled = false
)

// 全局变量，下面会用到
var (
	// 存储每个子采集器的工厂函数
	factories              = make(map[string]func(logger *slog.Logger) (Collector, error))
	initiatedCollectorsMtx = sync.Mutex{}
	// 存储每个子采集器的工厂函数
	initiatedCollectors    = make(map[string]Collector)
	// 采集器的状态
	collectorState         = make(map[string]*bool)
	forcedCollectors       = map[string]bool{} // collectors which have been explicitly enabled or disabled
)

// ...

// NodeCollector implements the prometheus.Collector interface.
type NodeCollector struct {
	// 这里的 Collector 接口是内部定义的接口，而不是 SDK 的 prometheus.Collector 类型
	Collectors map[string]Collector
	logger     *slog.Logger
}

// ...

// NewNodeCollector creates a new NodeCollector.
func NewNodeCollector(logger *slog.Logger, filters ...string) (*NodeCollector, error) {
	f := make(map[string]bool)

	// 对过滤条件进行判断
	for _, filter := range filters {
		enabled, exist := collectorState[filter]
		if !exist {
			return nil, fmt.Errorf("missing collector: %s", filter)
		}
		if !*enabled {
			return nil, fmt.Errorf("disabled collector: %s", filter)
		}
		f[filter] = true
	}
	collectors := make(map[string]Collector)
	initiatedCollectorsMtx.Lock()
	defer initiatedCollectorsMtx.Unlock()

	// collectorState 是全局变量，代表每个子采集器的状态
	for key, enabled := range collectorState {
		if !*enabled || (len(f) > 0 && !f[key]) {
			continue
		}
		// initiatedCollectors 起到的是缓存的作用
		if collector, ok := initiatedCollectors[key]; ok {
			collectors[key] = collector
		} else {
			// 根据 key 调用子采集器的工厂函数创建子采集器
			collector, err := factories[key](logger.With("collector", key))
			if err != nil {
				return nil, err
			}
			collectors[key] = collector
			initiatedCollectors[key] = collector
		}
	}
	return &NodeCollector{Collectors: collectors, logger: logger}, nil
}

```

`NodeCollector` 的角色是一个大的采集器对象，可以代表整个 Exporter，而这些存储在 `initiatedCollectors` 映射里面的 `Collector` 实例则是 `NodeCollector` 的子采集器。大的采集器把采集任务分派给小的采集器并发地完成采集。

注意这里的 `Collector` 接口不是 SDK 里面提供的接口，而是 Node Exporter 里面定义的 `Collector` 接口，名称和 SDK 里面那个是一样的。

### Collector 接口

#### `prometheus.Collector`

`NodeCollector` 实现的 `prometheus.Collector` 接口定义，源码在 <https://github.com/prometheus/client_golang/blob/v1.20.5/prometheus/collector.go#L16-L63>

```go
type Collector interface {	
	Describe(chan<- *Desc)
	Collect(chan<- Metric)
}
```

如果要写一个 Exporter，那么就要定义一个结构体然后实现这个接口。`Describe` 方法用于描述你要采集的指标的信息，通过一个 `chan<- *Desc` 管道来存储指标描述信息。

`Collect` 方法是用于被 SDK 的注册器调用，当一个 HTTP 请求过来时，SDK 提供的 `http.Handler` 会通过注册器调用它内部的所有 `Collector` 实例的 `Collect` 方法，从而最后给前端返回指标文本数据。这个方法会被并发地调用，所以在实现的时候必须得保证并发安全。

#### 内置的 Collector

Node Exporter 内置的 `Collector` 接口：<https://github.com/prometheus/node_exporter/blob/v1.9.1/collector/collector.go#L179-L183>

```go
// Collector is the interface a collector has to implement.
type Collector interface {
	// Get new metrics and expose them via prometheus registry.
	Update(ch chan<- prometheus.Metric) error
}
```

内部只有一个 `Update` 方法，从这里可以直观地看出来，这个 `Collector` 仅仅是对 `prometheus.Collector` 的一层包装而已，方法签名其实是差不多的，但是这样做的好处就是可以和 SDK 内部的代码解耦合，变得更加可控。

Node Exporter 内部的子采集器都实现了这个 `Collector` 接口，只要重写 `Update` 方法即可。

#### NodeCollector 实现 Collector 接口

采集指标的关键代码都在如何实现 `prometheus.Collector` 接口的方法，`NodeCollector` 对这个接口的实现如下：

<https://github.com/prometheus/node_exporter/blob/v1.9.1/collector/collector.go#L139-L177>

```go
// Describe implements the prometheus.Collector interface.
func (n NodeCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- scrapeDurationDesc
	ch <- scrapeSuccessDesc
}

// Collect implements the prometheus.Collector interface.
func (n NodeCollector) Collect(ch chan<- prometheus.Metric) {
	wg := sync.WaitGroup{}
	wg.Add(len(n.Collectors))

	// 对 NodeCollector 内部的 Collector 字段进行遍历
    // 每个子采集器都开启一个协程去完成采集任务，通过调用 execute 函数实现
	for name, c := range n.Collectors {
		go func(name string, c Collector) {
			execute(name, c, ch, n.logger)
			wg.Done()
		}(name, c)
	}
	wg.Wait()
}

// Collector 这里是指内部的 Collector 接口，而不是 SDK 提供的
func execute(name string, c Collector, ch chan<- prometheus.Metric, logger *slog.Logger) {
	begin := time.Now()
	// 采集指标的最终实现调用，上文提到的 Update 方法
	err := c.Update(ch)
	duration := time.Since(begin)
	var success float64

	if err != nil {
		if IsNoDataError(err) {
			logger.Debug("collector returned no data", "name", name, "duration_seconds", duration.Seconds(), "err", err)
		} else {
			logger.Error("collector failed", "name", name, "duration_seconds", duration.Seconds(), "err", err)
		}
		success = 0
	} else {
		logger.Debug("collector succeeded", "name", name, "duration_seconds", duration.Seconds())
		success = 1
	}

	// 这两个指标在 collector.go 文件最上面有定义过，值就是采集的时间以及是否成功
	ch <- prometheus.MustNewConstMetric(scrapeDurationDesc, prometheus.GaugeValue, duration.Seconds(), name)
	ch <- prometheus.MustNewConstMetric(scrapeSuccessDesc, prometheus.GaugeValue, success, name)
}

```

## 子采集器

以内存采集为子采集器示例，可以看到以下结构体和常量定义：<https://github.com/prometheus/node_exporter/blob/v1.9.1/collector/meminfo.go#L27-L60>

```go
const (
	// 表示子采集器系统（类似于命名空间）
	memInfoSubsystem = "memory"
)

func init() {
	registerCollector("meminfo", defaultEnabled, NewMeminfoCollector)
}

// Update calls (*meminfoCollector).getMemInfo to get the platform specific
// memory metrics.
func (c *meminfoCollector) Update(ch chan<- prometheus.Metric) error {
	var metricType prometheus.ValueType
	memInfo, err := c.getMemInfo()
	if err != nil {
		return fmt.Errorf("couldn't get meminfo: %w", err)
	}
	c.logger.Debug("Set node_mem", "memInfo", fmt.Sprintf("%v", memInfo))
	for k, v := range memInfo {
		if strings.HasSuffix(k, "_total") {
			metricType = prometheus.CounterValue
		} else {
			metricType = prometheus.GaugeValue
		}
		ch <- prometheus.MustNewConstMetric(

			// 指标描述字段
			prometheus.NewDesc(
				prometheus.BuildFQName(namespace, memInfoSubsystem, k),
				fmt.Sprintf("Memory information field %s.", k),
				nil, nil,
			),
			metricType, v,
		)
	}
	return nil
}
```

不同的后缀表示不同的操作系统环境，以 Linux 为例：<https://github.com/prometheus/node_exporter/blob/v1.9.1/collector/meminfo_linux.go>

### registerCollector 函数

`registerCollector` 函数用于把采集器的构造函数注册到 collector.go 文件中的 `factories` 构造函数工厂里面进行统一创建。

`registerCollector` 函数在 collector.go 文件定义如下：<https://github.com/prometheus/node_exporter/blob/v1.9.1/collector/collector.go#L59-L75>

```go
func registerCollector(collector string, isDefaultEnabled bool, factory func(logger *slog.Logger) (Collector, error)) {
	var helpDefaultState string
	if isDefaultEnabled {
		helpDefaultState = "enabled"
	} else {
		helpDefaultState = "disabled"
	}

	// 可以通过命令行参数控制是否开启采集器
	flagName := fmt.Sprintf("collector.%s", collector)
	flagHelp := fmt.Sprintf("Enable the %s collector (default: %s).", collector, helpDefaultState)
	defaultValue := fmt.Sprintf("%v", isDefaultEnabled)

	flag := kingpin.Flag(flagName, flagHelp).Default(defaultValue).Action(collectorFlagAction(collector)).Bool()
	collectorState[collector] = flag

	// 保存到构造函数工厂内部
	factories[collector] = factory
}
```

`registerCollector` 函数在 `init` 函数中被调用，在每个采集器文件内部都含有 `init` 函数：

```go
func init() {
	registerCollector("meminfo", defaultEnabled, NewMeminfoCollector)
}
```

### Update 方法

具体的采集逻辑就是在 `Update` 方法中。

内存采集器的 `Udpate` 方法实现如下：<https://github.com/prometheus/node_exporter/blob/v1.9.1/collector/meminfo.go#L35-L60>

```go
// Update calls (*meminfoCollector).getMemInfo to get the platform specific
// memory metrics.
func (c *meminfoCollector) Update(ch chan<- prometheus.Metric) error {
	var metricType prometheus.ValueType
	memInfo, err := c.getMemInfo()
	if err != nil {
		return fmt.Errorf("couldn't get meminfo: %w", err)
	}
	c.logger.Debug("Set node_mem", "memInfo", fmt.Sprintf("%v", memInfo))
	for k, v := range memInfo {
		if strings.HasSuffix(k, "_total") {
			metricType = prometheus.CounterValue
		} else {
			metricType = prometheus.GaugeValue
		}
		ch <- prometheus.MustNewConstMetric(
			prometheus.NewDesc(
				prometheus.BuildFQName(namespace, memInfoSubsystem, k),
				fmt.Sprintf("Memory information field %s.", k),
				nil, nil,
			),
			metricType, v,
		)
	}
	return nil
}

```

获取内存信息的具体实现是在 meminfo_linux.go 文件中，不同操作系统有不同的实现，`getMemInfo` 方法实现如下：

```go
type meminfoCollector struct {
	fs     procfs.FS
	logger *slog.Logger
}

// NewMeminfoCollector returns a new Collector exposing memory stats.
func NewMeminfoCollector(logger *slog.Logger) (Collector, error) {
	fs, err := procfs.NewFS(*procPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open procfs: %w", err)
	}

	return &meminfoCollector{
		logger: logger,
		fs:     fs,
	}, nil
}

func (c *meminfoCollector) getMemInfo() (map[string]float64, error) {
	meminfo, err := c.fs.Meminfo()
	if err != nil {
		return nil, fmt.Errorf("Failed to get memory info: %s", err)
	}

	metrics := make(map[string]float64)

	if meminfo.ActiveBytes != nil {
		metrics["Active_bytes"] = float64(*meminfo.ActiveBytes)
	}
	// ....

	return metrics, nil
}
```

本质上是读取 Linux 操作系统的 `/proc/meminfo` 文件，然后分析 <https://github.com/prometheus/procfs/blob/v0.15.1/meminfo.go>

## 二次开发采集器

模拟读取温度的采集器，仅仅是模拟不做具体实现，读取机器温度由传感器提供接口。

创建 temperature.go 文件，然后定义 `TemperatureCollector` 结构体：

```go
package collector

import (
	`math/rand`
	`time`

	`github.com/go-kit/log`
	`github.com/prometheus/client_golang/prometheus`
)

const (
	temperatureSubSystem = "temperature"
)

type TemperatureCollector struct {
	logger      log.Logger
	temperature *prometheus.Desc
}

func NewTemperatureCollector(logger log.Logger) (Collector, error) {
	return &TemperatureCollector{
		logger: logger,
		temperature: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, temperatureSubSystem, "cpu_instant_temperature"),
			"CPU's instant temperature implemented by sensors' api.",
			[]string{"core"},
			nil,
		),
	}, nil
}

```

然后实现 `Collector` 接口：

```go
// 假设有 CPU 有 4 核
// 仅仅模拟一下，主要目的是了解 Node Exporter 的框架结构
func (t TemperatureCollector) Update(ch chan<- prometheus.Metric) error {
	rand.Seed(time.Now().UnixNano())
	cores := []string{"1", "2", "3", "4"}
	for i := 0; i < len(cores); i++ {
		val := rand.Int31n(100)
		ch <- prometheus.MustNewConstMetric(t.temperature, prometheus.GaugeValue, float64(val), cores[i])
	}
	return nil
}

```

最后声明 `init` 函数，调用 `registerCollector` 函数：

```go
func init() {
	registerCollector("temperature", defaultEnabled, NewTemperatureCollector)
}
```

