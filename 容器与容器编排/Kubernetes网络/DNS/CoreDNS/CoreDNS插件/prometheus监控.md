## 监控插件

Prometheus 插件作为 coredns 的 Plugins，默认情况下是内置在 coredns 中，如果是自己编译安装的版本，需要注意在编译安装的时候的 plugin.cfg 文件中添加了 `prometheus:metrics`，这样才能确保编译成功

```bash
# 首先检查一下运行的版本
> ./coredns -plugins | grep prometheus
  dns.prometheus
```

prometheus 插件主要用于暴露 CoreDNS 相关的监控数据，除了 coredns 本身外，其他支持 prometheus 的插件（如 cache 插件）在启用的时候也可以通过 prometheus 插件暴露出相关的监控信息，默认情况下暴露出的监控数据在 `localhost:9153`，路径为 `/metrics`，配置文件中的每个 server 块只能使用一次 prometheus

官方文档：<https://coredns.io/plugins/metrics/>

coredns 中想要启用 prometheus 插件，只需要在对应的 zone 中加上这一行配置即可，默认监听的是本机 127.0.0.1 的 9153 端口，当然也可以根据自己的需要更改监听的网卡和端口

```corefile
prometheus [ADDRESS]

# example:
#   prometheus localhost:9253
#   prometheus localhost:{$PORT} # 从环境变量加载端口
```

注意：prometheus 的生效范围是按照 zone 来划分的

## 监控数据

下面是一些 coredns 自身相关的指标：

- `coredns_build_info {version, revision, goversion}` - 关于 CoreDNS 本身的信息
- `coredns_panics_total {}` - panics 的总数
- `coredns_dns_requests_total {server, zone, proto, family, type}` - 总查询次数
- `coredns_dns_request_duration_seconds {server, zone, type}` - 处理每个查询的耗时
- `coredns_dns_request_size_bytes {server, zone, proto}` - 请求的大小（以 bytes 为单位）
- `coredns_dns_do_requests_total {server, zone}` - 设置了 DO 位的查询（queries that have the DO bit set）
- `coredns_dns_response_size_bytes {server, zone, proto}` - 响应的大小（以 bytes 为单位）
- `coredns_dns_responses_total {server, zone, rcode}` - 每个 zone 的响应码和数量
- `coredns_plugin_enabled {server, zone, name}` - 每个 zone 上面的各个插件是否被启用

上面出现的几个标签：

- `zone`：每个 `request/response` 相关的指标都会有一个 `zone` 的标签，也就是上述的大多数监控指标都是可以细化到每一个 `zone` 的。这对于需要具体统计相关数据和监控排查问题的时候是非常有用的
- `server`：是用来标志正在处理这个对应请求的服务器，一般的格式为 `<scheme>://[<bind>]:<port>`，默认情况下应该是 `dns://:53`，如果使用了 bind 插件指定监听的 IP，那么就可能是 `dns://127.0.0.53:53` 这个样子
- `proto`：指代的就是传输的协议，一般就是 udp 或 tcp
- `family`：指代的是传输的 IP 协议代数，(1 = IP (IP version 4), 2 = IP6 (IP version 6))
- `type`：指代的是 DNS 查询的类型，这里被分为常见的如 (A, AAAA, MX, SOA, CNAME, PTR, TXT, NS, SRV, DS, DNSKEY, RRSIG, NSEC, NSEC3, IXFR, AXFR and ANY) 和其他类型 other

重点指标如下：

| 指标类型                               | 指标说明                   | 告警设置                                                     |
| -------------------------------------- | -------------------------- | ------------------------------------------------------------ |
| `coredns_dns_requests_total`           | 请求次数                   | 可针对总量进行告警，判断当前域名解析 QPS 是否过高            |
| `coredns_dns_responses_total`          | 响应次数                   | 可针对不同状态码 RCODE 的响应次数进行告警，例如服务端异常 SERVFAIL 出现时，可进行告警 |
| `coredns_panics_total`                 | CoreDNS 程序异常退出的次数 | 大于 0 则说明异常发生，应进行告警                            |
| `coredns_dns_request_duration_seconds` | 域名解析延迟               | 延迟过高时应进行告警                                         |

## grafana dashboard

coredns 原生支持的 prometheus 指标数量和丰富程度在众多 DNS 系统中可以说是首屈一指的，此外在 grafana 的官网上也有着众多现成的 dashboard 可用，并且由于绝大多数指标都是通用的，多个不同的 dashboard 之间的 panel 可以随意复制拖拽组合成新的 dashboard 并且不用担心兼容性问题

可以实现：

- 监控出不同 DNS 类型的请求数量以及不同的 zone 各自的请求数量，还有其他的类似请求延迟、请求总数等等各项参数都能完善地监控起来
- 可以监控到不同的请求的传输层协议状态，缓存的大小状态和命中情况等各种信息

官方面板市场搜索：<https://grafana.com/grafana/dashboards/?search=coredns>

推荐的面板：

- <https://grafana.com/grafana/dashboards/14981-coredns/>
