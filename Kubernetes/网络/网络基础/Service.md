Service 是一种抽象的对象，它定义了一组 Pod 的逻辑集合和一个用于访问它们的策略

为什么需要 service 呢？在微服务中，pod 可以对应实例，那么 service 对应的就是一个微服务。而在服务调用过程中，service 的出现解决了两个问题：

1. pod 的 ip 不是固定的，利用非固定 ip 进行网络调用不现实
2. 服务调用需要对不同 pod 进行负载均衡

service 通过 label 选择器选取合适的 pod，构建出一个 endpoints，即 pod 负载均衡列表。实际运用中，一般我们会为同一个微服务的 pod 实例都打上类似`app=xxx`的标签，同时为该微服务创建一个标签选择器为`app=xxx`的 service。

## 三种类型的 IP

- Node IP：Node 节点的 IP 地址
- Pod IP: Pod 的 IP 地址
- Cluster IP: Service 的 IP 地址

## 定义 Service

## kube-proxy

## Service

### NodePort 类型

### ExternalName

## externalIPs
