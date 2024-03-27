
## InfiniBand

InfiniBand 代表两个不同的因素：

- InfiniBand 网络的物理链路协议
- InfiniBand Verbs API，这是远程直接访问（RDMA）技术的实现

官方文档地址：<https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/9/html/configuring_infiniband_and_rdma_networks/index>

## 驱动安装

### 编译安装

IB 网卡驱动下载：

- <https://developer.nvidia.com/networking/infiniband-software>

- <https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/>

```
Note: By downloading and installing MLNX_OFED package for Oracle Linux (OL) OS, you may be violating your operating system’s support matrix. Please consult with your operating system support before installing.

Note: MLNX_OFED 4.9-x LTS should be used by customers who would like to utilize one of the following:

NVIDIA ConnectX-3 Pro
NVIDIA ConnectX-3
NVIDIA Connect-IB
RDMA experimental verbs library (mlnx_lib)
OSs based on kernel version lower than 3.10
Note: All of the above are not available on MLNX_OFED 5.x branch.
```

这里使用 ctx-3 pro，因此需要使用 4.x 分支

### 从软件源中安装

````bash
dnf install -y \
	iproute libibverbs libibverbs-utils \
	infiniband-diags \
	perftest \
	rdma-core
````

如果没有内核模块，需要

```bash
# refer: http://elrepo.org/tiki/HomePage
dnf install -y https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm

dnf --disablerepo=\* --enablerepo=elrepo install -y kmod-mlx4

echo "mlx4_ib" > /etc/modules-load.d/mlx4.conf
```

## 配置 InfiniBand 子网管理器

所有 InfiniBand 网络都必须运行子网管理器才能正常工作。即使两台机器没有使用交换机直接进行连接，也是如此。

有可能有一个以上的子网管理器。在这种情况下，一个 master 充当一个主子网管理器，另一个子网管理器充当从属子网管理器，当主子网管理器出现故障时将接管。

大多数 InfiniBand 交换机都包含一个嵌入式子网管理器。但是，如果您需要更新的子网管理器，或者您需要更多控制，请使用 Red Hat Enterprise Linux 提供的 `OpenSM` 子网管理器。

### 安装

```bash
dnf install -y opensm
```

启用并启动 `opensm` 服务：

```bash
systemctl enable --now opensm
```

### 配置 

使用 `ibstat` 程序获取端口的 GUID：

```
> ibstat -d
CA 'mlx4_0'
	CA type: MT4103
	Number of ports: 2
	Firmware version: 2.42.5700
	Hardware version: 0
	Node GUID: 0x480fcffffff09140
	System image GUID: 0x480fcffffff09143
	Port 1:
		State: Active
		Physical state: LinkUp
		Rate: 40
		Base lid: 2
		LMC: 0
		SM lid: 4
		Capability mask: 0x0259486a
		Port GUID: 0x480fcffffff09141
		Link layer: InfiniBand
	Port 2:
		State: Down
		Physical state: Polling
		Rate: 10
		Base lid: 0
		LMC: 0
		SM lid: 0
		Capability mask: 0x02594868
		Port GUID: 0x480fcffffff09142
		Link layer: InfiniBand
```

> 有些 InfiniBand 适配器在节点、系统和端口中使用相同的 GUID。

编辑 `/etc/sysconfig/opensm` 文件并在 `GUIDS` 参数中设置 GUID：

```bash
GUIDS="GUID_1 GUID_2"
```

如果子网中有多个子网管理器，可以设置 `PRIORITY` 参数。例如：

```
PRIORITY=15
```

## 管理 ib 网卡


### ibv_devices

显示系统中目前所有设备

```bash
> ibv_devices

    device          	   node GUID
    ------          	----------------
    mlx4_0          	480fcfffffeaa8a0
```

### ibstat

查看网卡状态

```bash
> ibstat

CA 'mlx4_0'
	CA type: MT4103
	Number of ports: 2
	Firmware version: 2.42.5700
	Hardware version: 0
	Node GUID: 0x480fcfffffeaa8a0
	System image GUID: 0x480fcfffffeaa8a3
	Port 1:
		State: Initializing
		Physical state: LinkUp
		Rate: 40
		Base lid: 0
		LMC: 0
		SM lid: 0
		Capability mask: 0x02594868
		Port GUID: 0x480fcfffffeaa8a1
		Link layer: InfiniBand
	Port 2:
		State: Down
		Physical state: Polling
		Rate: 10
		Base lid: 0
		LMC: 0
		SM lid: 0
		Capability mask: 0x02594868
		Port GUID: 0x480fcfffffeaa8a2
		Link layer: InfiniBand
```

查看网络中的 ib 设备

```bash
ibnodes
```

## IPoIB

InfiniBand 不使用 IP 进行通信。但是，IP over InfiniBand(IPoIB) 在 InfiniBand 远程直接访问 (RDMA) 网络之上提供一个 IP 网络模拟层。这允许现有未经修改的应用程序通过 InfiniBand 网络传输数据，但性能低于应用程序原生使用 RDMA 时的数据。

### IPoIB 通讯模式

IPoIB 设备可在 `Datagram` 或 `Connected` 模式中配置。区别在于 IPoIB 层试图在通信的另一端机器打开的队列对类型：

- 在 `Datagram` 模式中，系统会打开一个不可靠、断开连接的队列对。

  这个模式不支持大于 InfiniBand 链路层的最大传输单元(MTU)的软件包。在传输数据时，IPoIB 层在 IP 数据包之上添加了一个 4 字节 IPoIB 标头。因此，IPoIB MTU 比 InfiniBand link-layer MTU 小 4 字节。因为 `2048` 是一个常见的 InfiniBand 链路层 MTU，`Datagram` 模式中的通用 IPoIB 设备 MTU 为 `2044`。

- 在 `Connected` 模式中，系统会打开一个可靠、连接的队列对。

  这个模式允许消息大于 InfiniBand link-layer MTU。主机适配器处理数据包分段和重新装配。因此，在 `Connected` 模式中，从 Infiniband 适配器发送的消息没有大小限制。但是，由于 `data` 字段和 TCP/IP `标头字段` 导致 IP 数据包有限。因此，`Connected` 模式中的 IPoIB MTU 是 `65520` 字节。

  `连接` 模式的性能更高，但会消耗更多内核内存。

虽然将系统配置为使用连接模式，但系统仍然使用 `Datagram` 模式发送多播流量，因为 InfiniBand 交换机和光纤无法在 `连接` 模式中传递多播流量。另外，当主机没有配置为使用 连接 模式时，系统会返回 `Datagram` 模式。

在运行应用程序时，将多播数据发送到接口中的 MTU 时，使用 `Datagram` 模式配置接口，或将应用配置为以以数据报报数据包中的发送大小上限。

### IPoIB 硬件地址

ipoIB 设备有 `20` 字节硬件地址，它由以下部分组成：

- 前 4 字节是标志和队列对号

- 下一个 8 字节是子网前缀

  默认子网前缀为 `0xfe:80:00:00:00:00:00:00`。设备连接到子网管理器后，设备会更改此前缀以匹配配置的子网管理器。

- 最后一个 8 字节是 InfiniBand 端口的全球唯一标识符(GUID)，附加到 IPoIB 设备

### 使用命令行工具 nmcli 配置

开启内核模块

```bash
modprobe ib_ipoib
```

创建 InfiniBand 连接，在 `Connected` 传输模式中使用 `ib0` 接口，以及最大 MTU `65520` 字节：

```bash
nmcli connection add type infiniband con-name ib0 ifname ib0 transport-mode Connected mtu 65520
```

还可以将 `0x8002` 设置为 `mlx4_ib0` 连接的 `P_Key` 接口：

```bash
# nmcli connection modify ib0 infiniband.p-key 0x8002
```

要配置 IPv4 设置，设置 `ib0` 连接的静态 IPv4 地址、网络掩码、默认网关和 DNS 服务器：

```
nmcli connection modify ib0 ipv4.addresses 10.245.245.101/24
# nmcli connection modify ib0 ipv4.gateway 10.244.245.254
# nmcli connection modify ib0 ipv4.dns 10.244.245.253
# nmcli connection modify ib0 ipv4.method manual
```

## RDMA 内存限制

远程直接内存访问(RDMA)操作需要固定物理内存。因此，内核不允许将内存写入交换空间。如果用户固定太多内存，系统会耗尽内存，并且内核会终止进程来释放更多内存。因此，内存固定是一个特权操作。

如果非 root 用户运行大型 RDMA 应用程序，则可能需要增加这些用户可在系统中的内存量。

如何为 `rdma` 组配置无限内存：

以 `root` 用户身份，使用以下内容创建文件 `/etc/security/limits.conf` 

```
@rdma soft memlock unlimited
@rdma hard memlock unlimited
```

使用 `ulimit -l` 命令显示限制：

```none
$ ulimit -l
unlimited
```

如果命令返回 `unlimited`，用户可以获得无限数量的内存。

## 测试 ib 网卡

### 测试连接性

使用简单的 ping 程序，比如 infiniband-diags 软件包中的 ibping 测试 RDMA 连接性。

ibping(需要 root 权限) 程序采用客户端/服务器模式。

必须首先在一台机器中启动 ibping 服务器，然后再另一台机器中将 ibping 作为客户端运行，并让它与 ibping 服务器相连。

- 服务端

```bash
ibping -S -C <ca> -P 1 
```

`-S`：以服务器端运行

`-C`：是 CA，来自 ibstat 的输出

`-P`：端口号，来自 ibstat 的输出

- 客户端

```bash
ibping -c 10000 -f -C <ca> -P 1 -L 1
```

`-c`：发送 10000 个 packet 之后停止

`-f`：flood destination

`-C`：是 CA，来自 ibstat 的输出

`-P`：端口号，来自服务器端运行 ibping 命令时指定的 -P 参数值.

`-L`：Base lid，来自服务器端运行 ibping 命令时指定的端口（-P 参数值）的 base lid（参考 ibstat），具体要查看服务端的 Base lid。

### 性能测试

服务端运行

```bash
ib_send_bw -a -c UD -d mlx4_0 -i 1
```

客户端运行

```bash
ib_send_bw -a -c UD -d mlx4_0 -i 1 172.16.0.102
```

### 测试带宽

第一台执行

```bash
ib_write_bw
```

第二台执行

```bash
ib_write_bw <对端的 IP 地址>
```

这里测试的写带宽，如果要测试读带宽把 write 改成 read 就可以了

```bash
> ib_read_bw 10.245.245.101
---------------------------------------------------------------------------------------
                    RDMA_Read BW Test
 Dual-port       : OFF		Device         : mlx4_0
 Number of qps   : 1		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 PCIe relax order: ON
 ibv_wr* API     : OFF
 TX depth        : 128
 CQ Moderation   : 1
 Mtu             : 2048[B]
 Link type       : IB
 Outstand reads  : 16
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x01 QPN 0x0213 PSN 0xc5556c OUT 0x10 RKey 0x8010100 VAddr 0x007f52462f6000
 remote address: LID 0x02 QPN 0x0215 PSN 0x18c2ac OUT 0x10 RKey 0x8010100 VAddr 0x007fd98e4e7000
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[MB/sec]    BW average[MB/sec]   MsgRate[Mpps]
Conflicting CPU frequency values detected: 2500.000000 != 4665.464000. CPU Frequency is not max.
 65536      1000             3074.52            3074.48		   0.049192
---------------------------------------------------------------------------------------

> ib_write_bw 10.245.245.101
---------------------------------------------------------------------------------------
                    RDMA_Write BW Test
 Dual-port       : OFF		Device         : mlx4_0
 Number of qps   : 1		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 PCIe relax order: ON
 ibv_wr* API     : OFF
 TX depth        : 128
 CQ Moderation   : 1
 Mtu             : 2048[B]
 Link type       : IB
 Max inline data : 0[B]
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x01 QPN 0x0210 PSN 0x74083e RKey 0x010100 VAddr 0x007f69af1a3000
 remote address: LID 0x02 QPN 0x0212 PSN 0x6559ac RKey 0x010100 VAddr 0x007f364105b000
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[MB/sec]    BW average[MB/sec]   MsgRate[Mpps]
Conflicting CPU frequency values detected: 2500.000000 != 4900.441000. CPU Frequency is not max.
 65536      5000             3097.74            3097.69		   0.049563
---------------------------------------------------------------------------------------
```



### 测试网络延迟

延迟的测试和带宽的测试差不多，只不过在命令上有点不同只要把 bw 改成 lat 就可以了

第一台执行

````bash
# 测试写延迟
ib_write_lat

# 测试读延迟
ib_read_lat
````

第二台执行

```bash
# 测试写延迟
ib_write_lat <对端的 IP 地址>

# 测试读延迟
ib_read_lat <对端的 IP 地址>
```

测试结果

```bash
> ib_read_lat 10.245.245.101
---------------------------------------------------------------------------------------
                    RDMA_Read Latency Test
 Dual-port       : OFF		Device         : mlx4_0
 Number of qps   : 1		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 PCIe relax order: ON
 ibv_wr* API     : OFF
 TX depth        : 1
 Mtu             : 2048[B]
 Link type       : IB
 Outstand reads  : 16
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x01 QPN 0x021c PSN 0x83df1a OUT 0x10 RKey 0x20010100 VAddr 0x0055f49b272000
 remote address: LID 0x02 QPN 0x021e PSN 0x6b79ad OUT 0x10 RKey 0x20010100 VAddr 0x0055c103dcf000
---------------------------------------------------------------------------------------
 #bytes #iterations    t_min[usec]    t_max[usec]  t_typical[usec]    t_avg[usec]    t_stdev[usec]   99% percentile[usec]   99.9% percentile[usec]
Conflicting CPU frequency values detected: 2500.000000 != 4533.369000. CPU Frequency is not max.
Conflicting CPU frequency values detected: 2500.000000 != 4762.091000. CPU Frequency is not max.
 2       1000          3.30           15.56        3.40     	       3.45        	0.50   		3.80    		15.56
---------------------------------------------------------------------------------------

> ib_write_lat 10.245.245.101
---------------------------------------------------------------------------------------
                    RDMA_Write Latency Test
 Dual-port       : OFF		Device         : mlx4_0
 Number of qps   : 1		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 PCIe relax order: OFF
 ibv_wr* API     : OFF
 TX depth        : 1
 Mtu             : 2048[B]
 Link type       : IB
 Max inline data : 220[B]
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x01 QPN 0x0219 PSN 0xe0ddc0 RKey 0x18010100 VAddr 0x0055687e848000
 remote address: LID 0x02 QPN 0x021b PSN 0xdc7e04 RKey 0x18010100 VAddr 0x005561e52c8000
---------------------------------------------------------------------------------------
 #bytes #iterations    t_min[usec]    t_max[usec]  t_typical[usec]    t_avg[usec]    t_stdev[usec]   99% percentile[usec]   99.9% percentile[usec]
Conflicting CPU frequency values detected: 2500.000000 != 4708.411000. CPU Frequency is not max.
Conflicting CPU frequency values detected: 2500.000000 != 4769.441000. CPU Frequency is not max.
 2       1000          1.76           7.68         1.88     	       1.96        	0.49   		5.28    		7.68
---------------------------------------------------------------------------------------
```

## 参考文档

- <https://www.cnblogs.com/sctb/p/13179542.html>

- <https://www.sdnlab.com/26283.html>
