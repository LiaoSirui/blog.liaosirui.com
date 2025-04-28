## cAdvisor 简介

cAdvisor 对 Node 节点上的资源及容器进行实时监控和性能数据采集，包括 CPU 、内存、网络吞吐量及文件系统等

cAdvisor 是 Google 开源的容器资源监控和性能分析工具。它是专门为容器而生，在 Kubernetes 中，cAdvisor 集成在 Kubelet 中，当 Kubelet 启动时，会自动启动 cAdvisor，即一个 cAdvisor 仅对一台 Node 主机进行监控

cAdvisor 对 Node 节点上的资源及容器进行实时监控和性能数据采集，包括 CPU 、内存、网络吞吐量及文件系统等

官方文档：<https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md>

## 常用指标

- CPU

| 指标名称                           | 类型    | 含义                                |
| ---------------------------------- | ------- | ----------------------------------- |
| container_cpu_load_average_10s     | gauge   | 过去 10 秒容器 CPU 的平均负载       |
| container_cpu_usage_seconds_total  | counter | 容器 CPU 累计使用量 (单位：秒)      |
| container_cpu_system_seconds_total | counter | System CPU 累计占用时间（单位：秒） |
| container_cpu_user_seconds_total   | counter | User CPU 累计占用时间（单位：秒）   |

- 内存

| 指标名称                           | 类型  | 含义                                                       |
| ---------------------------------- | ----- | ---------------------------------------------------------- |
| container_memory_max_usage_bytes   | gauge | 容器的最大内存使用量（单位：字节）                         |
| container_memory_usage_bytes       | gauge | 容器当前的内存使用量（单位：字节），包括缓存等可释放的内存 |
| container_memory_working_set_bytes | gauge | 容器当前的内存使用量（单位：字节）                         |
| container_spec_memory_limit_bytes  | gauge | 容器的内存使用量限制                                       |
| machine_memory_bytes               | gauge | 当前主机的内存总量                                         |

- 网络

| 指标名称                                 | 类型    | 含义                                   |
| ---------------------------------------- | ------- | -------------------------------------- |
| container_network_receive_bytes_total    | counter | 容器网络累积接收数据总量（单位：字节） |
| container_network_receive_packets_total  | counter | 容器网络累积接收数据总量（单位：包）   |
| container_network_transmit_bytes_total   | counter | 容器网络累积发送数据总量（单位：字节） |
| container_network_transmit_packets_total | counter | 容器网络累积发送数据总量（单位：包）   |
| container_network_receive_errors_total   | counter | 容器网络累计接收错误总量               |
| container_network_transmit_errors_total  | counter | 容器网络累计发送错误总量               |