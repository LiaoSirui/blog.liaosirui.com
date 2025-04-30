## `pm_qos` 子系统

### 解决的问题

c-state 引入的一个问题是：当有任务到来时，从低功耗状态切回运行状态会有一定的延迟， 对于某些应用来说可能无法接受。为了解决这个问题，应用可以通过 Power Management Quality of Service (PM QoS) 接口。

这是一个内核框架，允许 kernel code and user space processes 向内核声明延迟需求，避免性能过低。

### 原理

系统会在节能的前提下，尽量模拟 **`idle=poll processor.max_cstate=1`** 的效果

- idle=poll 会阻止处理器进入 idle state；
- processor.max_cstate=1 阻止处理器进入较深的 C-states。

使用方式：

- 应用程序打开 **`/dev/cpu_dma_latency`** ， 写入能接受的最大响应时间，这是一个 `int32` 类型，单位是 `us`；
- 注意：保持这个文件处于 open 状态；关闭这个文件后，PM QoS 就停止工作了。
