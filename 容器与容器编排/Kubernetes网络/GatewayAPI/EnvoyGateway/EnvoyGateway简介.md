## Envoy Gateway

Envoy Gateway 是一个用于管理 Envoy Proxy 的开源项目，可单独使用或作为 Kubernetes 中应用的网关。它通过了 Gateway API 核心一致性测试，使用 Gateway API 作为其唯一的配置语言来管理 Envoy 代理，支持 GatewayClass、Gateway、HTTPRoute 和 TLSRoute 资源。

Envoy Gateway 的目标是降低用户采用 Envoy 作为 API 网关的障碍，以吸引更多用户采用 Envoy。它通过入口和 L4/L7 流量路由，表达式、可扩展、面向角色的 API 设计，使其成为供应商建立 API 网关增值产品的基础。

Envoy Gateway 的核心优势是轻量级、开放、可动态编程，尤其是为后端增加了安全功能，这些优势使得它很适合作为后端 API 网关。

## 扩展 API

### Backend

Envoy Gateway 通过扩展 API 中的 Backend CRD 直接代理 K8s 集群外部的服务 (VM、物理机、第三方 SaaS)。Backend 支持 IP 地址、FQDN 域名、Unix Domain Socket 三种 endpoints 类型, 可作为 HTTPRoute 的 backendRefs。