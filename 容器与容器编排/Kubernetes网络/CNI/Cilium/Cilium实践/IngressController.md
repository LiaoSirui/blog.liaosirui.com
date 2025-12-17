- `Cilium` 现在提供了开箱即用的 `Kubernetes` `Ingress` 实现。`Cilium ingress` 实现了基于路径的路由、`TLS` 终止还可以提供多服务共享一个负载均衡器 `IP` 等功能。
- `Cilium Ingress Controller` 在底层使用了 `Envoy` 和 `eBPF`，可管理进入 `Kubernetes` 集群的南北向流量，集群内的东西向流量以及跨集群通信的流量，同时实现丰富的 `L7` 负载均衡衡和 `L7` 流量管理。

开启配置

```yaml
ingressController:
  enabled: true
  loadbalancerMode: shared
  enforceHttps: false
  enableProxyProtocol: false
  service:
    name: cilium-ingress
    type: LoadBalancer
    insecureNodePort:
    secureNodePort:
    loadBalancerClass: "io.cilium/bgp-control-plane"
    loadBalancerIP: "172.31.34.20"
    allocateLoadBalancerNodePorts: false
```

测试 Ingress

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
  namespace: default
spec:
  ingressClassName: cilium
  rules:
    - http:
        paths:
          - backend:
              service:
                name: cni
                port:
                  number: 80
            path: /
            pathType: Prefix
```

Ingress PathType 类型：Cilium 中 ImplementationSpecific 为 Exact，需注意

- ImplementationSpecific：对于这种 path 类型，匹配取决于 IngressClass。可以将其视为一个单独的 pathType 或者将其认为和 Prefix 或者 Exact 路径类型一样。

- Exact：精确匹配 URL 路径，并且区分大小写

- Prefix: 根据 URL 中的，被 / 分割的前缀进行匹配。匹配区分大小写并且按照元素对路径进行匹配。path 元素指的是路径中由 / 分隔符分隔的标签列表。
