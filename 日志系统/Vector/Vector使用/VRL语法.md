## VRL 简介

[Vector Remap Language (VRL)](https://vector.dev/docs/reference/vrl/) 是 Vector 中用于数据转换和处理的语言。它的设计目标是简化数据流的处理，能够以更灵活和直观的方式操作数据管道

Vector Remap Language，简称 VRL，是一种专为处理观测数据（如日志、指标、追踪）设计的脚本语言。虽然最初 VRL 是为了在 Vector 工具中使用而创建，但其设计理念使其通用且易于在多种场景下重用。VRL 分为多个可按需启用的组件，确保灵活性与功能性兼备。它包括核心编译运行能力、抽象语法树解析、价值类型处理、错误逻辑、路径操作等功能，并提供标准库以支持丰富的数据处理需求。

VRL 可以分为三个部分：

- 解析
- 过滤 & 错误处理
- 替换

Remap 是通过编写 VRL 语言来定制 Transform 的逻辑

```toml
[sources.demo_source]
type = "demo_logs"
format = "apache_common"
lines = [ "line1" ]

[transforms.transform_apache_common_log]
type = "remap"
inputs = [ "demo_source" ]
drop_on_error = true
drop_on_abort = true
reroute_dropped = true
source = """
log = parse_apache_log!(.message,format: "common")
if to_int(log.status) > 300 {
  abort
}
. = log
.mark = "transform_apache_common_log"
"""

[sinks.transform_apache_common_log_sink]
type = "console"
inputs = [ "transform_apache_common_log" ]
encoding.codec = "json"

[sinks.demo_source_sink]
type = "console"
inputs = [ "demo_source" ]
encoding.codec = "json"

[transforms.transform_apache_common_log_dropped]
type = "remap"
inputs = [ "transform_apache_common_log.dropped" ]
source = """
.mark = "dropped"
"""

[sinks.dropped_msg_sink]
type = "console"
inputs = [ "transform_apache_common_log_dropped" ]
encoding.codec = "json"
```

## VRL

### 解析

```vrl
log = parse_apache_log!(.message, format: "common")
```

同大部分编程语言的赋值语句类型。这一句是把等号右边表达式产生的结果赋值给 `log` 变量。等号右边整体的意思是按照 Apach Common 的格式解析原 event 中的 message 字段转化为更结构化的键值对结构。

这里是调用了一个内置函数 `parse_apache_log` 他接收两个参数：

- `.message`
- `format: "common"`

这里的 `.message` 是对当前 event 取 message 字段的操作。当前 event 的格式如下：

```json
{
    "host": "localhost",
    "message": "218.169.11.238 - KarimMove [25/Nov/2024:04:21:15 +0000] \"GET /wp-admin HTTP/1.0\" 410 36844",
    "service": "vector",
    "source_type": "demo_logs",
    "timestamp": "2024-11-25T04:21:15.135802380Z"
}
```

可以观察到除了 message 字段还包含了一些 `host` `source_type` 等元信息。apache log 格式除了 `common` 还有 `combined` 格式，这里的第二个参数表示用 `common` 的格式来解析传入的日志内容。

除此之外，还会观察到 `parse_apache_log` 后有一个 `!` 。这个感叹号并不是类似 Rust 中宏的标记，而是代表了一种错误处理逻辑

如果解析成功，Log 将会被赋值为结构化的 Apach Common 格式的数据，可以看到本来单一的字符串内容变成了结构化的键值对，后续可以很方便的进行过滤和聚合等操作。

```json
{
    "host": "67.210.39.57",
    "message": "DELETE /user/booperbot124 HTTP/1.1",
    "method": "DELETE",
    "path": "/user/booperbot124",
    "protocol": "HTTP/1.1",
    "size": 14865,
    "status": 300,
    "timestamp": "2024-11-26T06:24:17Z",
    "user": "meln1ks"
}
```

### 过滤 & 错误处理

既然 Log 已经是结构化的数据，就可以用更精细的方式来过滤或者裁剪关心的数据。假设对 status 大于 300 的数据不关心，那就可以设置 `log.status` > 300 时中断此 transform （这里的谓词可以换成任意想要的逻辑）。

```vrl
if to_int(log.status) > 300 {
  abort
}
```

默认逻辑下，如果触发 `abort`， 当前事件会原封不动地传入下一个处理单元，因为不关心这些数据所以决定丢掉这部分数据。

可使用如下配置：

```toml
drop_on_error = true
drop_on_abort = true
```

但是，如果有一些本来没考虑到的情况，导致了 vrl 执行错误（类型错误，解析错误等），这样可能本来所关心的数据就被丢失，这会造成一些信息上的缺失。为了解决这个问题。可以使用 `reroute_dropped = true` 配置来把 drop 的 event 增加 `metadata` 后统一分发到一个 `<current_transform_id>.dropped` 的 input 里

```json
{
    "host": "localhost",
    "mark": "dropped",
    "message": "8.132.254.222 - benefritz [25/Nov/2024:07:56:35 +0000] \"POST /controller/setup HTTP/1.1\" 550 36311",
    "metadata": {
        "dropped": {
            "component_id": "transform_apache_common_log",
            "component_kind": "transform",
            "component_type": "remap",
            "message": "aborted",
            "reason": "abort"
        }
    },
    "service": "vector",
    "source_type": "demo_logs",
    "timestamp": "2024-11-25T07:56:35.126819716Z"
}
```

只要关注这个 input 就可以了解哪些数据被 drop 了，视情况可以修改 vrl 把那些丢失的数据也利用起来

### 替换

```vrl
. = log
.mark = "transform_apache_common_log"
```

上述配置中，第一行等号左边的「`.`」，在 VRL 中表示 VRL 正在处理的当前 event。等号右边的则是之前解析出来的结构化 Log 结果，将会替换掉当前的 event。

第二行表示在已经替换成结构化日志的当前 event 增加一个 `mark` 字段来标记当前 event 来自 `transform_apache_common_log transform`。

最终得到了如下数据格式的数据，此数据格式的数据会取代原数据格式被下游接收:

```json
{
    "host": "67.210.39.57",
    "mark": "transform_apache_common_log",
    "message": "DELETE /user/booperbot124 HTTP/1.1",
    "method": "DELETE",
    "path": "/user/booperbot124",
    "protocol": "HTTP/1.1",
    "size": 14865,
    "status": 300,
    "timestamp": "2024-11-26T06:24:17Z",
    "user": "meln1ks"
}
```

## VRL 错误处理

```vrl
log = parse_apache_log!(.message, format: "common")
```

调用 `parse_apache_log` 时，在其后增加了一个 `!`，这是 VRL 中的一种错误处理方式。由于 Event 中包含的字段类型多种多样，为了保证其灵活性，许多函数在逻辑处理或数据类型不符合预期时可能会返回错误。因此，需要引入错误处理机制来应对这些情况

`parse_apache_log` 其实是返回了两个结果，一个是函数正常返回结果，另一个则是一个错误信息类似于：

```vrl
result, err = parse_apache_log(log,format:"common") 
```

当 `err` 不等于 `null` 时表示函数执行发送了错误。在 VRL 中，在函数名称后面增加 `!` 算是一种语法糖，表示当遇到错误时立即中断当前 VRL 片段提前返回错误

类似如下的代码：

```vrl
result, err = parse_apache_log(log,format:"common")
if err != null {
   panic
}
```

假如 message 是多种格式的数据混合在一起，使用 `!` 来提前中断解析逻辑就显得不是那么合理

假设 Event 字段可能是 JSON、Apache Common 格式中的一种，可能就需要如下的配置来使日志结构化的输出：

```vrl
structured, err = parse_json(.message)
if err != null {
  log("Unable to parse JSON: " + err, level: "error")
  . = parse_apache_log!(.message,format: "common")
} else {
  . = structured
}
```

不能在 `parse_json` 失败的时候就直接终止 transform，需要再尝试按照 apache common 格式解析后再视解析结果而定
