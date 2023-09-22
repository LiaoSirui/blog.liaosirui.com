## DCGM

NVIDIA DCGM 是用于管理和监控基于 Linux 系统的 NVIDIA GPU 大规模集群的一体化工具

文档：<https://docs.nvidia.com/datacenter/cloud-native/gpu-telemetry/latest/index.html>

## 常见的查询指标

- 利用率

| 指标名称                  | 类型  | 含义                          |
| ------------------------- | ----- | ----------------------------- |
| DCGM_FI_DEV_GPU_UTIL      | Gauge | GPU 利用率（单位：%）         |
| DCGM_FI_DEV_MEM_COPY_UTIL | Gauge | GPU 内存带宽利用率（单位：%） |
| DCGM_FI_DEV_ENC_UTIL      | Gauge | GPU 编码器利用率（单位：%）   |
| DCGM_FI_DEV_DEC_UTIL      | Gauge | GPU 解码器利用率（单位：%）   |

- 显存

| 指标名称            | 类型  | 含义                          |
| ------------------- | ----- | ----------------------------- |
| DCGM_FI_DEV_FB_FREE | Gauge | GPU 帧缓存剩余量（单位：MiB） |
| DCGM_FI_DEV_FB_USED | Gauge | GPU 帧缓存使用量（单位：MiB） |

- 温度和功率

| 指标名称                             | 类型    | 含义                             |
| ------------------------------------ | ------- | -------------------------------- |
| DCGM_FI_DEV_GPU_TEMP                 | Gauge   | GPU 当前温度（单位：℃）          |
| DCGM_FI_DEV_MEMORY_TEMP              | Gauge   | 显存当前温度（单位：℃）          |
| DCGM_FI_DEV_POWER_USAGE              | Gauge   | GPU 当前使用功率（单位：W）      |
| DCGM_FI_DEV_TOTAL_ENERGY_CONSUMPTION | Counter | GPU 启动以来的总能耗（单位：mJ） |

- 其他

| 指标名称                           | 类型  | 含义                                 |
| ---------------------------------- | ----- | ------------------------------------ |
| DCGM_FI_DEV_SM_CLOCK               | Gauge | GPU SM 时钟（单位：MHZ）             |
| DCGM_FI_DEV_VGPU_LICENSE_STATUS    | Gauge | vGPU 许可证状态                      |
| DCGM_FI_PROF_PCIE_RX_BYTES         | Gauge | GPU PCIE 接收字节总数（单位：字节）  |
| DCGM_FI_PROF_PCIE_TX_BYTES         | Gauge | GPU PCIE 发送字节总数（单位：字节）  |
| DCGM_FI_DEV_MEM_CLOCK              | Gauge | GPU 内存时钟（单位：MHZ）            |
| DCGM_FI_DEV_NVLINK_BANDWIDTH_TOTAL | Gauge | GPU 所有通道的 NVLink 带宽计数器总数 |
| DCGM_FI_DEV_PCIE_REPLAY_COUNTER    | Gauge | GPU PCIE 重试次数                    |