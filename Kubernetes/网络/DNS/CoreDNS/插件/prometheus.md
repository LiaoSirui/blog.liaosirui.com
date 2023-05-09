## 监控插件

Prometheus 插件作为 coredns 的 Plugins，默认情况下是内置在 coredns 中，如果是自己编译安装的版本，需要注意在编译安装的时候的 plugin.cfg 文件中添加了 `prometheus:metrics`，这样才能确保编译成功

```bash
# 首先检查一下运行的版本
> ./coredns -plugins | grep prometheus
  dns.prometheus
```

## 监控数据

官方文档：<https://coredns.io/plugins/metrics/>

重点指标如下：

| 指标类型                               | 指标说明                   | 告警设置                                                     |
| -------------------------------------- | -------------------------- | ------------------------------------------------------------ |
| `coredns_dns_requests_total`           | 请求次数                   | 可针对总量进行告警，判断当前域名解析 QPS 是否过高            |
| `coredns_dns_responses_total`          | 响应次数                   | 可针对不同状态码 RCODE 的响应次数进行告警，例如服务端异常 SERVFAIL 出现时，可进行告警 |
| `coredns_panics_total`                 | CoreDNS 程序异常退出的次数 | 大于 0 则说明异常发生，应进行告警                            |
| `coredns_dns_request_duration_seconds` | 域名解析延迟               | 延迟过高时应进行告警                                         |

