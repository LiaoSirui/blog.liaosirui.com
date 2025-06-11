通常用来做调试

```toml
[sinks.my_sink_id]            # 接收器名称
  type = "console"            # 类型
  inputs = [ "my-source-or-transform-id" ]       # 输入，这里的输入是上一层的"变换"名称
  encoding.codec = "json"     # 可选json 或者 text

```

