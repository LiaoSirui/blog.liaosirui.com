## unbound 插件简介

CoreDNS 并没有一个本地的递归解析器，但 libunbound 具有这种功能

官方：

- CoreDNS 官方的 unbound 文档  <https://coredns.io/explugins/unbound/>
- GitHub 地址：<https://github.com/coredns/unbound>

此外，unbound 插件虽然是 CoreDNS 中的 External Plugins，但是从详情页面中可以看到 `Maintained by CoreDNS: CoreDNS maintainers take care of this plugin.`，说明这个插件是官方维护的，在稳定性可靠性以及后续更新维护上都有不错的保证，应该是可以放心使用的

## 编译插件

安装 libunbound

```bash
# EL9
dnf install --enablerepo=crb -y unbound-devel unbound-libs
```

添加插件配置至 `plugin.cfg`

```ini
unbound:github.com/coredns/unbound
```

注意编译需要开启 CGO

```bash
make CGO_ENABLED=1
```

## 配置使用

### 语法配置

```corefile
unbound [FROM] {
    except IGNORED_NAMES...
    option NAME VALUE
}
```

- FROM 指的是客户端请求需要解析的域名
- IGNORED_NAMES 和 except 搭配使用，指定不使用 unbound 的 zone
- option 可以添加 unbound 本身支持的一些参数，具体可以查看 unbound.conf 的 man 文档或者直接查看官网的文档 <https://nlnetlabs.nl/documentation/unbound/unbound.conf/>

### prometheus 监控

unbound 插件提供了两个监控指标，只要对应的 zone 中启用了 Prometheus 插件，那么就可以同时启用这两个指标 (其他插件的监控指标也一样)，它们分别是：

- `coredns_unbound_request_duration_seconds {server}` - duration per query.
- `coredns_unbound_response_rcode_count_total {server, rcode}` - count of RCODEs.

这两个监控指标的数据格式和内容与 coredns 原生的 `coredns_dns_request_duration_seconds` 和 `coredns_dns_response_rcode_count_total` 一致，因此相关的监控图表只需要套用原有的进行简单修改后就能直接使用

### 示例

除了 `liaosirui.com` 这个域名其他的都使用 `unbound`，并开启 DNS 最小化查询功能 <https://datatracker.ietf.org/doc/html/rfc7816>

```corefile
. {
    unbound {
        except liaosirui.com
        option qname-minimisation yes
    }
    log
    errors
    prometheus 0.0.0.0:9253
    bind 0.0.0.0
    cache {
        success 10240 600 60
        denial 5120 60 5
    }
}
```

