## CoreDNS 简介

CoreDNS 是一个灵活且可扩展的 DNS 服务器，它的设计目标是提供一种更现代化的 DNS 解决方案，用于服务发现和服务代理，特别是在云原生和容器化环境中。

CoreDNS 的主要特点包括：

- 插件架构：CoreDNS 采用模块化设计，所有功能都通过插件实现。用户可以根据需求启用或禁用插件，以定制 DNS 服务器的行为。
- 高性能：得益于 Go 语言的高并发处理能力，CoreDNS 在处理大量 DNS 请求时表现出色。
- 简洁配置：CoreDNS 的配置文件格式简单直观，用户易于上手和管理。
- 灵活性：支持多种后端，如 file、Kubernetes、etcd 等，能够适应各种应用场景。
- 云原生友好：与 Kubernetes 无缝集成，目前为 Kubernetes 集群默认 DNS 服务组件。

官方：

- CoreDNS 官网：<https://coredns.io/>
- GitHub <https://github.com/coredns/coredns>

目前 CoreDNS 已经成为社区 kubernetes 1.11 及以上版本集群推荐的 DNS 服务器解决方案。kubernetes 官方部署的默认 CoreDNS 版本：<https://github.com/coredns/deployment/blob/master/kubernetes/CoreDNS-k8s_version.md>

## CoreDNS 插件

CoreDNS 通过插件形式实现更多功能，CoreDNS 插件有两种：官方插件和外部插件，用户可以根据自身需求安装插件或者自己开发插件以满足业务需求

对于预编译的版本，会内置全部官方认证的插件，也就是官网的插件页面列出来的全部插件，插件页面：<https://coredns.io/plugins/>

```bash
> ./coredns -plugins

acl
any
auto
# ....
```

## 自建解析服务器

参考文档：

<https://draveness.me/dns-coredns/>

需要重点注意 SOA 记录和 NS 记录

```corefile
$ORIGIN alpha-quant.com.cn.
@ 3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
        2017042745 ; serial
        7200       ; refresh (2 hours)
        3600       ; retry (1 hour)
        1209600    ; expire (2 weeks)
        3600       ; minimum (1 hour)
        )

  3600 IN NS a.iana-servers.net.
  3600 IN NS b.iana-servers.net.
```

解决 `Got recursion not available from xx.xx.xx.xx, trying next server`

```corefile
header {
  response set ra # set RecursionAvailable flag
}
```

推荐使用

- <https://coredns.io/plugins/file/>

## 参考资料

- <https://help.aliyun.com/document_detail/195425.html>
