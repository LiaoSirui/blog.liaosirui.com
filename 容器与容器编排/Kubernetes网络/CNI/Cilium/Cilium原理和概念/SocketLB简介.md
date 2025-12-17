Socket LB：基于 eBPF 实现的东西向的 LB，可以在 Socket 级别完成数据包的发送和接受，而不是 Per-Packet 的处理方式。可以实现跨主机的 Pod->Pod 的直接连接，直接通信，而传统的 Kube-Proxy 是实现的 Per-Packet 的，且需要基于 IPVS/Iptables 的方式实现的 LB 的转发能力

相关文档：

- <https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/>
