InfiniBand网络的快速迭代，从 SDR 10Gbps、DDR 20Gbps、QDR 40Gps、FDR 56Gbps、EDR 100Gbps 到如今的 800Gbps InfiniBand，都得益于 RDMA 技术

InfiniBand 网络接口的一种分类方式，按照数据传输速率的的不同进行区分。具体如下：

- SDR（Single Data Rate）：单倍数据率，即 8Gb/s
- DDR（Double Data Rate）：双倍数据率，即 16Gb/s
- QDR（Quad Data Rate）：四倍数据率，即 32Gb/s
- FDR（Fourteen Data Rate）：十四倍数据率，即 56Gb/s
- EDR（Enhanced Data Rate）：100 Gb/s
- HDR（High Data Rate）：200 Gb/s
- NDR（Next Data Rate）：400 Gb/s+

InfiniBand 和以太网之间存在适用的应用场景。由于 InfiniBand 网络带来的速率显著增加，CPU 不需要为网络处理牺牲更多资源，从而提高了网络利用率，使得 InfiniBand 网络成为高性能计算行业主要网络解决方案。未来还将出现 1600Gbps GDR 和 3200Gbps LDR 的 InfiniBand 产品

## InfiniBand 光模块 & 高速线缆

- InfiniBand 光模块

| 产品        | 应用             | 连接器            |
| ----------- | ---------------- | ----------------- |
| 40G 光模块  | InfiniBand FDR10 | MTP/MPO-12        |
| 100G 光模块 | InfiniBand EDR   | 双工 LC           |
| 200G 光模块 | InfiniBand HDR   | MTP/MPO-12        |
| 400G 光模块 | InfiniBand NDR   | MTP/MPO-12 APC    |
| 800G 光模块 | InfiniBand NDR   | 双 MTP/MPO-12 APC |

- InfiniBand 高速线缆

| 产品          | 应用             | 连接器                                         |
| ------------- | ---------------- | ---------------------------------------------- |
| 40G 高速线缆  | InfiniBand FDR10 | 双 QSFP+ 到 QSFP+                              |
| 56G 高速线缆  | InfiniBand FDR   | 双 MTP/MPO-12 APC                              |
| 100G 高速线缆 | InfiniBand EDR   | QSFP28 到 QSFP28                               |
| 200G 高速线缆 | InfiniBand HDR   | QSFP56 到 QSFP56; QSFP56 到 2x QSFP56          |
| 400G 高速线缆 | InfiniBand HDR   | OSFP 到 2x QSFP56                              |
| 800G 高速线缆 | InfiniBand NDR   | OSFP 到 OSFP; OSFP 到 2× OSFP; OSFP 到 4× OSFP |

- InfiniBand 有源光缆

| 产品          | 应用             | 连接器                                                       |
| ------------- | ---------------- | ------------------------------------------------------------ |
| 40G 有源光缆  | InfiniBand FDR10 | QSFP+ 到 QSFP+                                               |
| 56G 有源光缆  | InfiniBand FDR   | QSFP+ 到 QSFP+                                               |
| 100G 有源光缆 | InfiniBand EDR   | QSFP28 到 QSFP28                                             |
| 200G 有源光缆 | InfiniBand HDR   | QSFP56 到QSFP56; QSFP56 到 2x QSFP56; 2x QSFP56 到 2x QSFP56 |
| 400G 有源光缆 | InfiniBand HDR   | OSFP 到 2× QSFP56                                            |


## InfiniBand 交换机

InfiniBand 交换机，NVIDIA Quantum/Quantum-2 提供了高达 200Gb/s、400Gb/s 的高速互连，超低延迟和可扩展性
