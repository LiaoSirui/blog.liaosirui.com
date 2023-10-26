## Istio Ingress 简介

入口网关指的是从外部经过 istio-ingressgateway 流入集群的流量，需要创建 Gateway 绑定流量

istio-ingressgateway 由 Pod 和 Service 组成。 istio-ingressgateway 本身就是一个网关应用，你可以把它当作 Nginx、Apisix、Kong ，你可以从各种各种网关应用中找到与 istio-ingressgateway 类似的概念

- 访问

作为一个应用，它需要对外开放一些端口，只有当流量经过这些端口时， istio-ingressgateway 才会起作用。为了在 Kubernetes 中暴露端口， istio-ingressgateway 还有一个 Service 对象

有了 istio-ingressgateway 之后，可以通过 Istio Gateway 监控一些域名或IP，然后暴露集群内部的服务 

- 对比 nginx

Gateway 的概念跟 Nginx 有很多相似之处

比如从配置上看， Gateway 跟 Nginx 如果要监控某个入口流量，它们的配置如下：

Nginx：

```nginx
server {
    listen      80;
    server_name example.org www.example.org;
    #...
}
```

Gateway：

```yaml
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - example.org
    - www.example.org
```

这些配置指定了 Gateway 和 Nginx 只监控哪些流量

紧接着，监控到指定入口的流量之后，需要将流量转发到集群内的应用中

Nginx 可以直接在同一个配置文件里面设置：

```nginx
server {
    listen      80;
    server_name example.org www.example.org;
    #...
}

location /some/path/ {
    proxy_pass http:/bookinfo:9080/;
}
```

而 Gateway 需要使用 VirtualService 指定流量转发到哪里，并且 VirtualService 还可以进一步筛选入口地址

```yaml
spec:
  hosts:
  - "www.example.org"
  gateways:
  # 绑定 Gateway
  - mygateway
  http:
    route:
    - destination:
        host: bookinfo
        port:
          number: 9080
```

所以总结起来，Istio 的做法是 Gateway 监控入口流量，通过 VirtualService 设置流量进入的策略，并指向 Service。而 DestinationRule 则定义了流量流向 Pod 的策略
