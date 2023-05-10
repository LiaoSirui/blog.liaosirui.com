## CoreDNS 简介

CoreDNS 插件是一款通过链式插件的方式为 Kubernetes 提供域名解析服务的 DNS 服务器

![CoreDNS logo](.assets/CoreDNS%E7%AE%80%E4%BB%8B/CoreDNS_Colour_Horizontal.png)

CoreDNS 是由 CNCF 孵化的开源软件，用于 Cloud-Native 环境下的 DNS 服务器和服务发现解决方案

- CoreDNS 实现了插件链式架构，能够按需组合插件，运行效率高、配置灵活
- 在 kubernetes 集群中使用 CoreDNS 能够自动发现集群内的服务，并为这些服务提供域名解析。

- 通过级联云上 DNS 服务器，还能够为集群内的工作负载提供外部域名的解析服务

- 可以通过修改 CoreDNS 的配置（"Corefile"）来配置 CoreDNS

该插件为系统资源插件，kubernetes 1.11 及以上版本的集群在创建时默认安装；目前 CoreDNS 已经成为社区 kubernetes 1.11 及以上版本集群推荐的 DNS 服务器解决方案

官方：

- CoreDNS 官网：https://coredns.io/

- 开源社区地址：https://github.com/coredns/coredns

其他：

- kubernetes 官方部署的默认 coredns 版本：<https://github.com/coredns/deployment/blob/master/kubernetes/CoreDNS-k8s_version.md>

![image-20230509100753501](.assets/CoreDNS%E7%AE%80%E4%BB%8B/image-20230509100753501.png)

## 插件和外部插件

- CoreDNS 本身是没有能力作为一个递归查询的 DNS 服务器（Recursive DNS），可以通过插件来实现对域名的递归查询和缓存等功能从而加速客户端的 DNS 查询性能；这里主要实现的插件有内部插件（Plugins）forward 或外部插件（External Plugins）unbound
- CoreDNS 的日志输出并不如 nginx 那么完善（并不能在配置文件中指定输出的文件目录，但是可以指定日志的格式），默认情况下不论是 log 插件还是 error 插件都会把所有的相关日志输出到程序的 standard output；CoreDNS 的原生日志功能对于一个 DNS 服务器的绝大部分应用场景来说是足够使用的，如果有更进阶的需求，可以考虑使用 dnstap 插件来实现
- CoreDNS 内置的两个健康检查插件 health 和 ready
- CoreDNS 服务在外部域名递归结果过程中容易出现一些问题，使用 dnsredir 插件进行分流和 alternate 插件进行重试优化的操作

## 参考资料

- <https://help.aliyun.com/document_detail/195425.html>
