## kiali 简介

kiali 是一款 istio 服务网格可视化工具，提供了服务拓补图、全链路跟踪、指标遥测、配置校验、健康检查等功能

![image-20231010142702194](.assets/kiali简介/image-20231010142702194.png)

kiali 架构还是比较简单的，属于单体应用。kiali 后台既可以跟外部服务 prometheus、cluster  API 进行通信获取 istio 服务网格信息，也可以集成可选服务 jaeger 和 grafana 做全链路跟踪和可视化指标度量

## 使用

### Overview（概观）

该菜单全局性展示所有命名空间下服务的流量（traffic）、配置状态（config status）、健康状态（✔）、应用数量（Applications）等

### Application（应用维度）

 applications 指运行中的应用，kiali 独有概念

 kiali 只能识别设置了 app 标签的应用。如果一个应用有多个版本，需要将这几个版本的 app 标签设置为相同的值。

### workloads（负载维度）

kiali 中的负载（workloads）跟 k8s 中的资源对应（比如  deployment、Job、Daemonset、Statefulset 等）。k8s 中的这些资源都可以在 kiali  中检测到，不管这些资源有没有加入到 istio 服务网格中

### Services（服务维度）

对应 k8s 的 service 资源类型

### Istio Config（配置维度）

istio 相关配置类信息。比如这里选择 istio type 类型，将显示有关 istio 服务网格下面的各个类型对应的配置信息状态（✔ 表示配置有效；！表示告警）