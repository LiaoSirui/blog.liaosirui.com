Linux 内核的 conntrack（连接跟踪）模块负责记录所有经过系统的网络连接状态。每个 TCP 连接、UDP 通信、ICMP 请求，都会在 conntrack 表里占一条记录。

conntrack 表的大小是有限的。默认值通常是：

```bash
# 查看当前 conntrack 表大小
sysctl net.netfilter.nf_conntrack_max
# 输出示例：2310720

# 查看当前已用条目
sysctl net.netfilter.nf_conntrack_count
# 输出示例：198723

# TIMEWAIT 的超时时间
sysctl net.netfilter.nf_conntrack_tcp_timeout_time_wait
```

当 `nf_conntrack_count` 接近 `nf_conntrack_max` 时，新连接就会被丢弃，表现为随机丢包、连接超时、服务间歇性不可达。

查看 conntrack 表里哪些连接占满

```bash
# 查看 conntrack 表内容（前 20 行）
conntrack -L | head -20

# 统计各状态的连接数
conntrack -S
```

监控指标

```bash
node_nf_conntrack_entries/node_nf_conntrack_entries_limit

# alert: NodeHighNumberConntrackEntriesUsed
```

cilium 中有 conntrack BPF map 的概念：

- `--bpf-ct-global-tcp-max`：TCP 协议连接跟踪表的条目最大值。
- `--bpf-ct-global-any-max`：非 TCP 协议连接跟踪表的条目最大值。
- `--bpf-nat-global-max`：NAT 转换表的最大条目数。
- `--bpf-map-dynamic-size-ratio`（默认通常为 `0.0025`，即使用 0.25% 的系统总内存），让系统根据节点物理内存自动计算并决定 Conntrack Map 的上限

监控数据

```
cilium_bpf_map_pressure{map_name="ct4_global"}
cilium_bpf_map_capacity{map_group="cilium_ct4_global"}
cilium_datapath_conntrack_dump_resets_total
```



