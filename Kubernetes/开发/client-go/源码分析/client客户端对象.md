## 四种 client 对象简介

client-go 的客户端对象有四个，关系如下：

![img](.assets/client.svg)

四种客户端都可以通过 kubeconfig 配置信息连接到指定到 Kubernetes API Server

作用各有不同：

- RESTClient

是对 HTTP Request 进行了封装，实现了 RESTful 风格的 API

RESTClient 是最基础的客户端，ClientSet、DynamicClient 及 DiscoveryClient 客户端都是在 RESTClient 基础上的实现，可与用于 k8s 内置资源和 CRD 资源

- ClientSet

ClientSet 在 RESTClient 的基础上封装了对 Resource 和 Version 的管理方案，是对 k8s 内置资源对象的客户端的集合

每一个 Resource 可以理解为一个客户端，而 ClientSet 则是多个客户端的集合，每一个 Resource 和 Version 都以函数的方式暴露给开发者；ClientSet 只能够处理 Kubernetes 内置资源，它是通过 client-gen 代码生成器自动生成的

默认情况下，不能操作 CRD 资源，但是通过 client-gen 代码生成的话，也是可以操作 CRD 资源的

- DynamicClient

DynamicClient 与 ClientSet 最大的不同之处是，ClientSet 仅能访问 Kubernetes 自带的资源 (即 Client 集合内的资源)，不能直接访问 CRD 自定义资源

DynamicClient 能够处理 Kubernetes 中的所有资源对象，包括 Kubernetes 内置资源与 CRD 自定义资源，不需要 client-gen 生成代码即可实现

- DiscoveryClient

DiscoveryClient 发现客户端，用于发现 kube-apiserver 所支持的资源组、资源版本、资源信息 (即 Group、Version、Resources)
