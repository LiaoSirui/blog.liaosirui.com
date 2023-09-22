## node-exporter

node-exporter 是 Prometheus 官方提供的 exporter，主要用来采集 Linux 类型节点的相关信息和运行指标，包括主机的 CPU、内存、Load、Filesystem、Network 等

官方：<https://github.com/prometheus/node_exporter>

## 常用查询指标

- CPU

| 指标名称               | 类型    | 含义                           |
| ---------------------- | ------- | ------------------------------ |
| node_cpu_seconds_total | Counter | 节点 CPU 的使用时间 (单位：秒) |

- 内存

| 指标名称                   | 类型  | 含义                           |
| -------------------------- | ----- | ------------------------------ |
| node_memory_MemTotal_bytes | Gauge | 节点总内存大小（单位：字节）   |
| node_memory_MemFree_bytes  | Gauge | 节点空闲内存大小（单位：字节） |
| node_memory_Buffers_bytes  | Gauge | 节点缓存大小（单位：字节）     |
| node_memory_Cached_bytes   | Gauge | 节点页面缓存大小（单位：字节） |

- 磁盘

| 指标名称                         | 类型    | 含义                                                       |
| -------------------------------- | ------- | ---------------------------------------------------------- |
| node_filesystem_avail_bytes      | Gauge   | 分区用户剩余空间（单位：字节），表示用户拥有的剩余可用空间 |
| node_filesystem_size_bytes       | Gauge   | 分区空间总容量（单位：字节）                               |
| node_filesystem_free_bytes       | Gauge   | 分区物理剩余空间（单位：字节），表示物理层的可用空间       |
| node_disk_read_bytes_total       | Counter | 分区读总字节数（单位：字节）                               |
| node_disk_written_bytes_total    | Counter | 分区写总字节数（单位：字节）                               |
| node_disk_reads_completed_total  | Counter | 分区读总次数                                               |
| node_disk_writes_completed_total | Counter | 分区写总次数                                               |

- 网络

| 指标名称                            | 类型    | 含义                           |
| ----------------------------------- | ------- | ------------------------------ |
| node_network_receive_bytes_total    | Counter | 接收流量总字节数（单位：字节） |
| node_network_transmit_bytes_total   | Counter | 发送流量总字节数（单位：字节） |
| node_network_receive_packets_total  | Counter | 接收流量总包数（单位：包）     |
| node_network_transmit_packets_total | Counter | 发送流量总包数（单位：包）     |
| node_network_receive_drop_total     | Counter | 接收流量总丢包数（单位：包）   |
| node_network_transmit_drop_total    | Counter | 发送流量总丢包数（单位：包）   |