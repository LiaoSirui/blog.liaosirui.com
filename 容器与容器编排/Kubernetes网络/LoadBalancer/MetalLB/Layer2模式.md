## 简介

当前的环境：

- MetalLB 使用 Layer2 模式

- 集群网络组件为 Cilium，启用了 eBPF kube-proxy replacement

- Service 配置可能包含 `externalTrafficPolicy: Cluster` 或 `Local`

工作原理：

Layer 2 中的 Speaker 工作负载是 DeamonSet 类型，在每台节点上都调度一个 Pod。首先，几个 Pod 会先进行选举，选举出 Leader。Leader 获取所有 LoadBalancer 类型的 Service，将已分配的 IP 地址绑定到当前主机到网卡上。也就是说，所有 LoadBalancer 类型的 Service 的 IP 同一时间都是绑定在同一台节点的网卡上。

当外部主机有请求要发往集群内的某个 Service，需要先确定目标主机网卡的 mac 地址。这是通过发送 ARP 请求，Leader 节点的会以其 mac 地址作为响应。外部主机会在本地 ARP 表中缓存下来，下次会直接从 ARP 表中获取。

请求到达节点后，节点再通过 kube-proxy 将请求负载均衡目标 Pod。所以说，假如 Service 是多 Pod 这里有可能会再跳去另一台主机。

![sequence](./.assets/Layer2模式/sequence.png)

## 网络流程

（1）MetalLB 宣告 VIP

- MetalLB Speaker Pod 运行在某个 Node（如 Node A）上。
- Speaker 通过 ARP（IPv4） 或 ND（IPv6） 向同一广播域内的交换机/网关发送声明：`VIP x.x.x.x 属于我（Node A）`

- 网络设备将目标为该 VIP 的数据包转发到 Node A

（2）外部数据包进入 Node A

- 外部客户端发出的数据包（目标 `VIP:Port`）通过路由器/交换机被送达 Node A 的物理网卡（如 eth0）。

- 数据包进入 Node A 内核网络栈，尚未处理时被 Cilium 的 eBPF 程序截获（如 `tc` 或 `XDP` hook）。

（3）eBPF 匹配 Service 并选择 Pod

- eBPF 程序识别目标 IP 为 VIP，并通过本地维护的 Service 映射表查询：
  - 匹配到 Kubernetes 中对应的 `Service` 与 `Port`

- 根据 `Service` 的负载均衡策略（如 `random`, `maglev`, `least_request`），从可用 Pod 中选择一个健康的目标 Pod（Pod B）

（4）执行 DNAT 转换（目标地址转换）

- eBPF 进行 目的地址转换（DNAT）：

  - 目标 IP：从 VIP ➜ PodIP_B

  - 目标端口：若 Service 配置了端口映射，则 Port ➜ TargetPort（容器端口）

（5）决定数据包路由方向

- 情况一：Pod B 位于本地（Node A）

  - Cilium 检测到 PodIP_B 属于本节点

  - 数据包通过 veth pair（宿主机 ↔ Pod 网络命名空间）被直接转发给 Pod B

- 情况二：Pod B 位于远程节点（Node C）

  - Cilium 检测 PodIP_B 属于另一个节点（Node C）

  - 按照配置使用：

    - Overlay 模式（VXLAN / Geneve）：进行隧道封装（包中目标 IP 是 Node C 的 IP）

    - Underlay 模式（如 BGP）：无需封装，直接路由

  - 数据包经网络送达 Node C

  - Node C 的 Cilium 解封装（若隧道），恢复原始目标为 PodIP_B

  - 数据包通过 veth pair 送达 Node C 上的 Pod B

注意：CEP（Cilium Endpoint）是 Pod 虚拟接口另一端（主机侧）的 IP。它被用于主机路由判断。当 Pod IP 与 CEP IP 不一致（如使用了静态 Pod IP 或 Pod 迁移），可能导致响应包不能正确路由回主机。

（6）Pod B 处理请求并响应

- Pod B 收到数据包并处理业务逻辑

- 响应数据包由 Pod B 发出：

  - 源 IP: PodIP_B

  - 源 Port: TargetPort

  - 目标 IP: Client IP

  - 目标 Port: Client Port

（7）SNAT 响应包（源地址转换）

- 响应包离开节点前，Cilium eBPF 再次介入，对其执行 SNAT（源地址转换）：

  - externalTrafficPolicy: Cluster（默认）

    - 响应包源 IP 修改为：VIP

    - SNAT 保证从任意 Node 访问都能通过 VIP 返回

  - externalTrafficPolicy: Local 且 Pod B 在 Node A

    - 源 IP 修改为：Node A 的外部 IP

    - 优化为本地访问，无跨节点跳转

  - externalTrafficPolicy: Local 且 Pod B 在 Node C
    - 若 VIP 绑定的是 Node A，Node C 上的 Pod B 不会选中，除非 VIP 也绑定在 Node C（即每个节点都部署了 Speaker）

- 响应包通过网络回到客户端

## 其他

- `externalTrafficPolicy: Cluster`
  - 所有节点接收 VIP 流量，Pod 可在任意节点。
  - SNAT 为 VIP，隐藏真实 Pod IP。
- `externalTrafficPolicy: Local`
  - 仅 Pod 所在节点接收 VIP 流量，源 IP 保留客户端真实 IP。
  - 适合需要保留源 IP 的服务场景（如日志审计、防火墙）