## Conntrack / Map 相关指标

Cilium 使用 BPF conntrack（连接跟踪表）来维护连接状态。当表满时，会通过 GC（垃圾回收）清理条目，可能导致活跃连接被错误清理或新连接无法建立。

BPF map 压力指标

```bash
cilium_bpf_map_pressure{}

cilium_bpf_map_pressure{map_name="ct4_global"}
cilium_bpf_map_pressure{map_name="ct_any4_global"}
```

当该值接近 1.0 (即 100%) 时表示表快满

BPF map 操作错误次数

```bash
cilium_bpf_map_ops_total{outcome="fail"}
```

Map 容量与使用情况

```bash
cilium_bpf_maps_virtual_memory_max_bytes{}
```

Conntrack GC 指标

```bash
# GC 运行情况：alive(存活) vs deleted(被删除) 的条目数
cilium_datapath_conntrack_gc_entries{status="alive"}
cilium_datapath_conntrack_gc_entries{status="deleted"}

sum by (node) (cilium_datapath_conntrack_gc_entries{status="deleted", protocol="TCP"})

# GC 运行耗时
cilium_datapath_conntrack_gc_duration_seconds_.*

# GC 运行次数
cilium_datapath_conntrack_gc_runs_total{protocol="TCP"}

# GC
cilium_datapath_conntrack_dump_resets_total
```

丢包 / 转发失败指标

```bash
# 丢包统计，关注 reason 标签
cilium_drop_count_total{}

sum by (reason) (rate(cilium_drop_count_total[5m]))
```

关键配置参数：

```bash
# bpf-ct-global-tcp-max  默认 524288 (TCP)
# bpf-ct-global-any-max  默认 262144 (非TCP)
bpf-ct-global-any-max: "1048576"
bpf-ct-global-tcp-max: "524288"

# 或调整 GC 间隔，使过期连接更快清理
# conntrack-gc-interval（默认动态，可显式设置）
```

