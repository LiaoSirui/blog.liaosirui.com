CoreDNS 插件是一款通过链式插件的方式为 Kubernetes 提供域名解析服务的 DNS 服务器

CoreDNS 是由 CNCF 孵化的开源软件，用于 Cloud-Native 环境下的 DNS 服务器和服务发现解决方案。CoreDNS 实现了插件链式架构，能够按需组合插件，运行效率高、配置灵活。在 kubernetes 集群中使用 CoreDNS 能够自动发现集群内的服务，并为这些服务提供域名解析。同时，通过级联云上 DNS 服务器，还能够为集群内的工作负载提供外部域名的解析服务

该插件为系统资源插件，kubernetes 1.11 及以上版本的集群在创建时默认安装

目前 CoreDNS 已经成为社区 kubernetes 1.11 及以上版本集群推荐的 DNS 服务器解决方案

官方：

- CoreDNS 官网：https://coredns.io/

- 开源社区地址：https://github.com/coredns/coredns
