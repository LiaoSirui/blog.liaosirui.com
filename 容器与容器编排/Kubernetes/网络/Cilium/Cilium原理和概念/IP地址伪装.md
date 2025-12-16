## IP 地址伪装 (Masquerading)

Pod 使用的 IPv4 地址通常是从 RFC1918 专用地址块中分配的，因此不可公开路由。Cilium 会自动将离开群集的所有流量的源 IP 地址伪装成 node 的 IPv4 地址，因为 node 的 IP 地址已经可以在网络上路由。如下图

![Masquerading](./.assets/IP地址伪装/1b435ad5166a473e461ac04b531b8f67-masquerade.png)

## 配置

### 基于 eBPF 的 IP 地址伪装模式

默认使用基于 IPTables 的 IP 地址伪装模式。这是传统的实现方式，可以在所有内核版本上运行

改为以下 helm value 部署

```yaml
enableIPv4Masquerade: true
enableIPv6Masquerade: true
bpf:
  masquerade: true
```

查看生效配置

```bash
# kubectl -n kube-system exec ds/cilium -- cilium status | grep Masquerading
Masquerading:            BPF   [nm-bond]   172.31.24.0/24 fd85:ee78:d8a6:8607::24:0/128 [IPv4: Enabled, IPv6: Enabled]
```

基于 eBPF 的伪装可伪装以下 IPv4 L4 协议的数据包：

- TCP
- UDP
- ICMP（仅 Echo request 和 Echo reply）

### 设置可路由 CIDR

默认行为是排除本地节点 IP 分配 CIDR 范围内的任何目的地。如果 pod IP 可通过更广泛的网络进行路由，则可使用选项：`ipv4-native-routing-cidr: 10.0.0.0/8`（或 IPv6 地址的 `ipv6-native-routing-cidr: fd00::/100`）指定该网络，在这种情况下，该 CIDR 范围内的所有目的地都不会被伪装。

```bash
# cilium config view | grep native
ipv4-native-routing-cidr                          172.31.24.0/24
ipv6-native-routing-cidr                          fd85:ee78:d8a6:8607::24:0/128
routing-mode                                      native
```

默认情况下，除了发往其他集群节点的数据包外，所有从 pod 发往 `ipv4-native-routing-cidr` 范围之外 IP 地址的数据包都会被伪装

为实现更精细的控制，Cilium 在 eBPF 中实现了 ip-masq-agent，可通过 `ipMasqAgent.enabled=true` helm 选项启用

```yaml
ipMasqAgent:
  enabled: true
  config:
    nonMasqueradeCIDRs:
      - 10.0.0.0/8
      - 172.16.0.0/12
      - 192.168.0.0/16
    masqLinkLocal: true
    masqLinkLocalIPv6: true
```

查看生效配置

```bash
kubectl -n kube-system exec ds/cilium -- cilium bpf ipmasq list
```

