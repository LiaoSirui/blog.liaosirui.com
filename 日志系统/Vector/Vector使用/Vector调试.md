## 日志级别

Vector 的 log level 默认为 info，支持的值为 `trace`、`debug`、`info`、`warn`、`error` 和 `off`。可以将其修改为 debug，并将日志格式化为 `json`：

```yaml
role: "Agent"

tolerations:
  - operator: Exists

logLevel: "debug"

env:
  - name: VECTOR_LOG_FORMAT
    value: "json"
```

## VRL 语法

通过访问 <https://playground.vrl.dev/> ，可以检验 VRL 语法的正确性。

## 调试性能

```bash
vector top --url http://127.0.0.1:8686/graphql
```

