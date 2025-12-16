L7 CiliumNetworkPolicy

网络策略定义允许哪些工作负载相互通信，通过防止意外流量来确保部署安全。Cilium 可同时执行本地 Kubernetes NetworkPolicies 和增强型 CiliumNetworkPolicy 资源 (CRD) 类型。

传统防火墙通过过滤 IP 地址和目标端口来保护工作负载。在 Kubernetes 环境中，每当集群中的 pod 启动时，都需要对所有节点主机上的防火墙（或 iptables 规则）进行操作，以便重建与所需网络策略执行相对应的防火墙规则。这并不能很好地扩展。

为了避免这种情况，Cilium 根据 Kubernetes 标签等相关元数据为应用容器组分配一个身份 (identity)。然后将该身份与应用容器发出的所有网络数据包关联起来，使 eBPF 程序能够在接收节点有效验证身份，而无需使用任何 Linux 防火墙规则。例如，当扩展部署并在集群中创建新 pod 时，新 pod  与现有 pod 共享相同的身份。与网络策略执行相对应的 eBPF 程序规则无需再次更新，因为它们已经知道 pod 的身份！

传统防火墙在第 3 层和第 4 层运行，而 Cilium 还能确保 REST/HTTP、gRPC 和 Kafka 等现代第 7 层应用协议的安全（除了在第 3 层和第 4 层执行外）。它能根据应用协议请求条件执行网络策略，例如

- 允许方法为 GET、路径为 `/public/.*` 的所有 HTTP 请求。拒绝所有其他请求。
- 要求所有 REST 调用都包含 HTTP 标头 `X-Token:[0-9]+`。