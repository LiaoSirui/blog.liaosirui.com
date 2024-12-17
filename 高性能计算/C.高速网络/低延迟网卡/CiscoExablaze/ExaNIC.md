## ExaNIC

ExaNIC Software 超低延迟网络卡驱动与工具

- <https://github.com/cisco/exanic-software>

ExaNIC Software 是一套为 Exablaze（现为 Cisco 的一部分）超低延迟网络卡提供驱动、实用程序和开发库的开源项目。这个项目旨在帮助用户充分利用ExaNIC系列网卡的高性能和独特功能，包括世界领先的延迟性能、精确时钟同步以及硬件可扩展性

ExaNIC X25 和 X100 无与伦比的延迟性能的关键因素是最新一代的 Xilinx Ultrascale + FPGA 技术。这些器件基于 Xilinx KU3P FPGA 构建，具有 25Gb /s 的收发器和 13Mb 的片上超 RAM。X25 / X100 NIC 也可选地分别带有 4GB / 9GB 的板载 DDR4 内存，从而使开发人员可以使用 ExaNIC 固件开发套件（FDK）直接在设备内部构建功能更强大和多样化的应用程序

ExaNIC Software 提供了多种功能强大的工具：

- exanic-config：一个直观的配置工具，用于查看设备的状态和配置。
- exanic-capture：支持无损线速率捕获的包捕获工具，带有高精度硬件时间戳。
- exasock：加速 Linux 套接字应用程序，通过直接与卡交互来绕过内核，实现低延迟通信。
- libexanic：允许开发者直接访问网卡，进行发送和接收数据等操作。

此外，它还提供了硬件流量过滤和定向功能，以降低主机应用负载。对于有特定网络处理需求的高级用户，可以利用 FPGA 开发自定义的硬件网络功能（Firmware Development Kit 需单独授权）。

ExaNIC Software 及其驱动适用于各种高性能计算和金融交易场景，如：

- 高频交易系统：ExaNIC 的超低延迟特性使得它可以用于要求严格的时间敏感型交易。
- 数据中心：在网络基础设施中部署 ExaNIC 可以提高吞吐量和效率。
- 实时数据分析：通过高速无损包捕获，ExaNIC 适用于实时数据流分析和处理。
- 网络安全监控：利用硬件过滤和定向功能，可以减轻服务器处理网络流量的压力。

## 安装 ExaNIC

官方文档

- <https://exablaze.com/docs/exanic/user-guide/installation/>
- YUM 源 <https://exablaze.com/downloads/yum/redhat/el8/x86_64/>

安装驱动

```bash
modprobe exanic
exanic-config exanic0
```

注意内核版本要求，比如 <https://github.com/cisco/exanic-software/blob/v2.7.4/RELEASE-NOTES.txt>

```bash
The following Linux distributions are officially supported and have been tested
with this release:

* RHEL 9.2 (kernel 5.14.0-284.11.1)
* RHEL 8.8 (kernel 4.18.0-477.10)
* Rocky Linux 9.2 (kernel 5.14.0-284.11.1)
* Rocky Linux 8.8 (kernel 4.18.0-477.10.1)
* Debian 12 (kernel 6.1)
* Ubuntu 23.04 (kernel 6.2)
```

