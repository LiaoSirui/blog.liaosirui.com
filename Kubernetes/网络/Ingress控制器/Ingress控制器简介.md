Ingress 资源对象只是一个路由请求描述配置文件，要让其真正生效还需要对应的 Ingress 控制器才行，Ingress 控制器有很多:


- Ingress-Nginx：基于 Nginx 的 Ingress 控制器
- Traefik：Traefik 是一个开源的可以使服务发布变得轻松有趣的边缘路由器
- APISIX：Apache APISIX 是一个基于 OpenResty 和 Etcd 实现的动态、实时、高性能的 API 网关