## OpenBMC

主板管理控制器（BMC）作为服务器硬件的关键组成部分，承担着监控系统健康状态、远程控制以及故障恢复等重要职责。BMC 是服务器上的管理模块，它包含独立的 SoC 以及 SoC 上运行的系统，完成对服务器的管理、监控、并对外提供服务

OpenBMC 是一个开源的项目，用于开发 BMC 固件

`OpenBMC` 使用 `Yocto` 项目作为底层构建和分发生成框架。固件本身基于 `U-Boot`。`OpenBMC` 使用 `D-Bus` 作为进程间通信(`IPC`)。`OpenBMC` 包含一个用于与固件堆栈交互的 `Web` 应用程序。`OpenBMC` 添加了 `Redfish` 对硬件管理的支持

## OpenBMC  的硬件平台

- ASPEED
- Xilinx
- NXP

## KCS

Keyboard Controller Style (KCS) Interface

系统（BIOS 和 OS）和 BMC 通信的一种基本方式

## 参考资料

- <https://blog.csdn.net/jiangwei0512/article/details/108891248>
- <https://blog.csdn.net/qq_34160841/article/details/115430387>
- <https://www.cnblogs.com/arvin-blog/p/15690416.html>
- <https://www.cnblogs.com/servlet-context/p/18368243>
- <http://www.360doc.com/content/22/0315/17/21412_1021659567.shtml>
- <https://www.gaitpu.com/data-center/server/openbmc-versus-traditional-bmc>
- <https://blog.csdn.net/yjj350418592/article/details/121836729>
