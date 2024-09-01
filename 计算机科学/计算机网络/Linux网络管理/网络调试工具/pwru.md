`pwru` 是 Cilium 推出的基于 eBPF 开发的网络数据包排查工具，它提供了更细粒度的网络数据包排查方案

`pwru` 要求内核代码在 5.5 版本之上，`--output-skb` 要求内核版本在 5.9 之上，并且要求内核开启以下配置：

| Option                  | Note                   |
| :---------------------- | :--------------------- |
| CONFIG_DEBUG_INFO_BTF=y | Available since >= 5.3 |
| CONFIG_KPROBES=y        |                        |
| CONFIG_PERF_EVENTS=y    |                        |
| CONFIG_BPF=y            |                        |
| CONFIG_BPF_SYSCALL=y    |                        |