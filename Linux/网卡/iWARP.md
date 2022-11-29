## 简介

Wide-area RDMA

远程直接内存访问(RDMA)使用互联网 Wide-area RDMA 协议(iWARP)并通过 TCP 进行融合和低延迟数据传输。

使用标准以太网交换机和 TCP/IP 堆栈，iWARP 在 IP 子网之间路由流量。这提供了高效使用现有基础架构的灵活性。

Soft-iWARP (siw) 是一个基于软件的、用于 Linux 的 iWARP 内核驱动器和用户程序库。它是一个基于软件的 RDMA 设备，在附加到网络接口卡时为 RDMA 硬件提供编程接口。它提供测试和验证 RDMA 环境的简便方法。

## 配置 Soft-iWARP

软 IWARP(siw)通过 Linux TCP/IP 网络堆栈实施互联网 Wide-area RDMA 协议(iWARP)远程直接内存访问(RDMA)传输。它可让具有标准以太网适配器的系统与 iWARP 适配器或另一个系统互操作，运行 Soft-iWARP 驱动程序，或使用支持 iWARP 的硬件的主机进行互操作。

安装 iproute、libibverbs、libibverbs-utils 和 infiniband-diags 软件包：

```bash
dnf install iproute libibverbs libibverbs-utils infiniband-diags
```

显示 RDMA 链接：

```bash
rdma link show
```

加载 siw 内核模块：

```bash
modprobe siw
```

添加一个新的名为 siw0 的 siw 设备，它使用 eth0 接口：

```bash
rdma link add siw0 type siw netdev eth0
```

验证，查看所有 RDMA 链接的状态：

```bash
> rdma link show

link siw0/1 state ACTIVE physical_state LINK_UP netdev enp0s1
```

列出可用的 RDMA 设备：

```bash
> ibv_devices

    device              node GUID
    ------           ----------------
    siw0             1ac04dfffeee0c32
```

可以使用 ibv_devinfo 工具显示详细的状态：

```bash
> ibv_devinfo siw0

hca_id: siw0
 transport:   iWARP (1)
 fw_ver:    0.0.0
 node_guid:   1ac0:4dff:feee:0c32
 sys_image_guid:   18c0:4dee:0c32:0000
 vendor_id:   0x626d74
 vendor_part_id:   1
 hw_ver:    0x0
 phys_port_cnt:   1
  port: 1
   state:   PORT_ACTIVE (4)
   max_mtu:  1024 (3)
   active_mtu:  1024 (3)
   sm_lid:   0
   port_lid:  0
   port_lmc:  0x00
   link_layer:  Ethernet
```
