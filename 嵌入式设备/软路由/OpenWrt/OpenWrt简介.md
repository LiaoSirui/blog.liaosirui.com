## OpenWRT 简介

OpenWrt 项目是一个针对嵌入式设备的 Linux 操作系统

OpenWrt 不是一个单一且不可更改的固件，而是提供了具有软件包管理功能的完全可写的文件系统。这使您可以从供应商提供的应用范围和配置中解脱出来，并且让您通过使用适配任何应用的软件包来定制设备。对于开发人员来说，OpenWrt 是一个无需围绕它构建完整固件就能开发应用程序的框架

OpenWRT 是一个高度模块化、高度自动化的嵌入式 Linux 系统，拥有强大的网络组件和扩展性，不同于其他许多用于路由器的发行版，它是一个从零开始编写的、功能齐全的、容易修改的路由器操作系统。还提供了 100 多个已编译好的软件，而且数量还在不断增加，OPKG 包含超过 3500 个软件，默认使用 LuCI 作为 web 交互界面

![image-20230423213736979](./.assets/OpenWrt简介/image-20230423213736979.png)

官方：

- 官网：<https://openwrt.org/zh/start>

## OpenWRT 下载

进入 OpenWrt 固件下载主页面：<http://downloads.openwrt.org/>

截止 2023-04，最新稳定发行版：

```
OpenWrt 22.03.4
Released: Fri, 14 April 2023
# https://downloads.openwrt.org/releases/22.03.4/targets/
```

Development Snapshots 是开发版，包含最新的功能，但可能不够稳定 <http://downloads.openwrt.org/snapshots/targets/>

如果使用 Snapshots 没有什么问题，当然是最好的选择，否则可以尝试一下稳定发行版

- 选择路由器的 CPU 类型

打开页面后，选择你的路由器的芯片型号进入，这里以 x86 系列为例，于是进入了：<https://downloads.openwrt.org/releases/22.03.4/targets/x86/>

- 选择路由器的 Flash 类型

再选择 Flash 类型，比如 WR2543 是 generic，网件 WNDR4300 路由器是 nand，这里进入 <https://downloads.openwrt.org/releases/22.03.4/targets/x86/64/>

### 镜像格式

- 官方提供了多种格式的 Image Files

  - `combined-ext4.img.gz`：包含引导信息、rootfs (ext4 格式)、内核以及相关分区信息的硬盘镜像，可以 dd 写入某个磁盘
  - `combined-squashfs.img.gz`：包含引导信息、rootfs (squashfs 格式)、内核以及相关分区信息的硬盘镜像
  - `generic-rootfs.tar.gz`：rootfs 包含的所有文件
  - `rootfs-ext4.img.gz`：rootfs (ext4 格式) 分区镜像，可以 dd 到某个分区或者 mount -o 到某个目录
  - `rootfs-squashfs.img.gz`：rootfs (squashfs 格式) 分区镜像，可以 dd 写入某个分区或者 mount -o 挂载到目录
  - `vmlinuz`：内核

  ext4 与 squashfs 格式的区别：

  - ext4 格式的 rootfs 可以扩展磁盘空间大小，而 squashfs 不能
  - squashfs 格式的 rootfs 可以使用重置功能（恢复出厂设置），而 ext4 不能