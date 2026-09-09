## client-go 简介

client-go 是一个调用 kubernetes 集群资源对象 API 的客户端，即通过 client-go 实现对 kubernetes 集群中资源对象（包括 deployment、service、ingress、replicaSet、pod、namespace、node 等）的增删改查等操作

大部分对 kubernetes 进行前置 API 封装的二次开发都通过 client-go 这个第三方包来实现

官方：

- GitHub 仓库：<https://github.com/kubernetes/client-go>

## 源码目录结构

源码目录结构及说明：

| 源码目录     | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| `discovery`  | 提供 DiscoveryClient 发现客户端                              |
| `dynamic`    | 提供 DynamicClient 动态客户端                                |
| `informers`  | 每种 kubernetes 资源的动态实现                               |
| `kubernetes` | 提供 ClientSet 客户端                                        |
| `listers`    | 为每一个 kubernetes 资源提供 Lister 功能，该功能对 Get 和 List 请求提供只读的缓存数据 |
| `plugin`     | 提供 OpenStack、GCP 和 Azure 等云服务商授权插件              |
| `rest`       | 提供 RESTClient 客户端，对 Kuberntes API Server 执行 RESTful 操作 |
| `scale`      | 提供 ScaleClient 客户端，用于扩容或缩容 Deployment、ReplicaSet、Replication Controller 等资源对象 |
| `tools`      | 提供常用工具，例如 Sharedinformer、Reflector、DealtFIFO 及 Indexers<br />提供 Client 查询和缓存机制，以减少向 kube-apiserver 发起的请求数等 |
| `transport`  | 提供安全的 TCP 连接，支持 Http Stream，某些操作需要在客户端和容器之间传输二进制流，例如 exec、attach等操作<br />该功能由内部的 spdy 包提供支持 |
| `util`       | 提供常用方法，例如 WorkQueue 工作队列、Certificate 证书管理  |

## 参考资料

<https://herbguo.gitbook.io/client-go/informer>

https://www.huweihuang.com/kubernetes-notes/develop/client-go.html

<https://www.backendcloud.cn/2022/11/24/client-go-1/>
