通过使用 QUERY API 可以查询 PromQL 在特定时间点下的计算结果

URL 请求参数：

- `query=`：PromQL 表达式
- `time=`：用于指定用于计算 PromQL 的时间戳。可选参数，默认情况下使用当前系统时间
- `timeout=`：超时设置。可选参数，默认情况下使用 `-query,timeout` 的全局设置