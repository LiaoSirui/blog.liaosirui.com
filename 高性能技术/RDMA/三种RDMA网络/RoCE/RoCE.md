## 简介

RDMA over Converged Ethernet

RoCE 是一种网络协议，可实现通过以太网的远程直接访问(RDMA)。

## 协议版本

以下是不同的 RoCE 版本：

- RoCE v1

RoCE 版本 1 协议是一个以太网链路层协议，带有 ethertype 0x8915，它允许同一以太网广播域中的任何两个主机间的通信。

- RoCE v2

RoCE 版本 2 协议在 IPv4 或 IPv6 协议的 UDP 上存在。对于 RoCE v2，UDP 目标端口号为 4791。

RDMA_CM 设置客户端和服务器之间用来传输数据的可靠连接。RDMA_CM 为建立连接提供了一个与 RDMA 传输相关的接口。这个通信使用特定的 RDMA 设备和基于消息的数据传输。

## Soft-RoCE

使用 Soft-RoCE 可以在任何以太网接口上模拟 RoCE 网卡功能，当不具备拥有 Mellanox 等支持 RoCE 功能的物理网卡条件时，可以使用内核的 Soft-RoCE 模块在普通以太网接口上进行模拟。

Soft-RoCE 架构：

![soft-roce.png](.assets/RoCE/soft-roce.png)

其中 Soft-RoCE 内核驱动模块完成了 RoCE 网络层（UDP/IP）处理：

![rdma-stack.png](.assets/RoCE/rdma-stack.png)

参考资料：<https://runsisi.com/2021/02/21/soft-roce/>

编译安装：<https://blog.csdn.net/weixin_33692284/article/details/92290849>

## 配置 Soft-RoCE

Soft-RoCE 是 RDMA over Ethernet 的一个软件实现，它也称为 RXE。在没有 RoCE 主机频道适配器(HCA)的主机上使用 Soft-RoCE。

安装 iproute、libibverbs、libibverbs-utils 和 infiniband-diags 软件包：

```bash
dnf install iproute libibverbs libibverbs-utils infiniband-diags
```

显示 RDMA 链接：

```bash
rdma link show
```

首先需要加载 Soft-RoCE 内核驱动模块（rdma_rxe.ko）：

```bash
modprobe rdma_rxe
```

```bash
> modinfo rdma_rxe

filename:       /lib/modules/5.4.0-64-generic/kernel/drivers/infiniband/sw/rxe/rdma_rxe.ko
alias:          rdma-link-rxe
license:        Dual BSD/GPL
description:    Soft RDMA transport
author:         Bob Pearson, Frank Zago, John Groves, Kamal Heib
srcversion:     12ABDA933B29E9F5A5ACBEA
depends:        ib_core,ip6_udp_tunnel,udp_tunnel,ib_uverbs
```

加载 rdma_rxe 内核模块，再添加名为 rxe 0 的新 rxe 设备，它使用 eth0 接口：

```bash
rdma link add rxe0 type rxe netdev eth0
```

