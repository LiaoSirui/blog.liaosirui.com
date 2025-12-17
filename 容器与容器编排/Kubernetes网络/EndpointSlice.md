## 诞生背景

端点切片（EndpointSlices） 是一个新 API，它提供了 Endpoint API 可伸缩和可拓展的替代方案。EndpointSlice 会跟踪 Service Pod 的 IP 地址、端口、readiness 和拓扑信息

如果使用 Endpoint API，Service 只有一个 Endpoint 资源。这意味着它需要为 Service 的每个 Pod 都存储好 IP 地址和端口（网络端点），这需要大量的 API 资源。另外，kube-proxy 会在每个节点上运行，并监控 Endpoint  资源的任何更新。如果 Endpoint 资源中有一个端口发生更改，那么整个对象都会分发到 kube-proxy 的每个实例。

为了说明这些问题的严重程度，这里举一个简单的例子。如果一个 Service 有 5000 个 Pod，它如果有 1.5MB 的  Endpoint 资源。当该列表中的某个网络端点发生了变化，那么就要将完整的 Endpoint 资源分发给集群中的每个节点。在具有 3000  个节点的大型集群中，这会是个很大的问题。每次更新将跨集群发送 4.5GB 的数据（1.5MB*3000，即 Endpoint 大小 *  节点个数），并且每次端点更新都要发送这么多数据。想象一下，如果进行一次滚动更新，共有 5000 个 Pod 全部被替换，那么传输的数据量将超过  22 TB。

EndpointSlice API 拆分 Endpoint

<img src="./.assets/EndpointSlice/2dad73b99e611713192d2bff0e86e21e.png" alt="img" style="zoom:67%;" />

EndpointSlice API 大大提高了网络的可伸缩性，因为现在添加或删除 Pod 时，只需更新 1 个小的 EndpointSlice。尤其是成百上千个 Pod 支持单个 Service 时，差异将非常明显。

## 属主关系

在大多数场合下，EndpointSlice 都由某个 Service 所有，  （因为）该端点切片正是为该服务跟踪记录其端点。这一属主关系是通过为每个 EndpointSlice  设置一个属主（owner）引用，同时设置 kubernetes.io/service-name 标签来标明的， 目的是方便查找隶属于某  Service 的所有 EndpointSlice。

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: example-abc
  labels:
    kubernetes.io/service-name: example
addressType: IPv4
ports:
  - name: http
    protocol: TCP
    port: 80
endpoints:
  - addresses:
      - "10.1.2.3"
    conditions:
      ready: true
    hostname: pod-1
    nodeName: node-1
    zone: us-west2-a
```

