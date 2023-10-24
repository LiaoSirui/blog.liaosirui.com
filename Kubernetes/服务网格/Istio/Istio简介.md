## Istio 简介

Istio 是一个功能强大的服务网格平台，为微服务架构提供了一套丰富的工具和功能，以简化和增强服务之间的通信、安全性和可观察性

官方：

- 官网：<https://istio.io/>
- 文档：<https://istio.io/latest/docs/>
- GitHub 仓库：<https://github.com/istio/istio>

Istio 的流量路由规则可以很容易地控制服务之间的流量和 API 调用。Istio 简化了服务级别属性的配置，比如熔断器、超时、重试等，并且能轻松地设置重要的任务，如 A/B 测试、金丝雀发布、基于流量百分比切分的概率发布等。它还提供了开箱即用的故障恢复特性，有助于增强应用的健壮性，从而更好地应对被依赖的服务或网络发生故障的情况

### Istio 服务治理

Istio 是一个与 Kubernetes 紧密结合的服务网格(Service Mesh)，用于服务治理。

注意，Istio 是用于服务治理的，主要有流量管理、服务间安全、可观测性这几种功能。在微服务系统中，会碰到很多棘手的问题，Istio 只能解决其中一小部分。

服务治理有三种方式，第一种是每个项目中包含单独的治理逻辑，这样比较简单；第二种是将逻辑封装到 SDK 中，每个项目引用 SDK 即可，不增加或只需要少量配置或代码即可；第三种是下沉到基础设施层。Istio 便是第三种方式。

![image-20230522205019428](.assets/Istio简介/image-20230522205019428.png)

Istio 对业务是非侵入式的，完全不需要改动项目代码。

### kiali

Kiali 仪表板展示了网格的概览以及应用的各个服务之间的关系，它还提供过滤器来可视化流量的流动

## 参考资料

- <https://www.qikqiak.com/k8strain/istio/traffic/#_6>
- <https://mp.weixin.qq.com/s/1VMEt3sJG3FWdaNXFGDn4Q>
- <https://istio.io/latest/zh/docs/ops/diagnostic-tools/proxy-cmd/>
