
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

### 从源中安装

````
dnf install -y \
	iproute libibverbs libibverbs-utils \
	infiniband-diags \
	perftest \
	rdma-core
````

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

### 使用命令行工具 nmcli 配置 IPoIB

开启内核模块

```
modprobe ib_ipoib
```

创建 ib 网卡

```
nmcli con add type infiniband con-name mlx4_ib0 ifname mlx4_ib0 transport-mode connected mtu 65520
```

修改 ib 网卡

```
 nmcli con edit mlx4_ib0
```

如果需要 `P_Key` 接口，请使用 nmcli 创建一个

## 测试 ib 网卡

### 测试连接性

使用简单的 ping 程序，比如 infiniband-diags 软件包中的 ibping 测试 RDMA 连接性。

ibping(需要 root 权限) 程序采用客户端/服务器模式。

必须首先在一台机器中启动 ibping 服务器，然后再另一台机器中将 ibping 作为客户端运行，并让它与 ibping 服务器相连。

- 服务端

```bash
ibping -S -C mlx4_0 -P 1 
```

`-S`：以服务器端运行

`-C`：是 CA，来自 ibstat 的输出

`-P`：端口号，来自 ibstat 的输出

- 客户端

```bash
ibping -c 10000 -f -C mlx4_0 -P 1 -L 0
```

`-c`：发送 10000 个 packet 之后停止

`-f`：flood destination

`-C`：是 CA，来自 ibstat 的输出

`-P`：端口号，来自服务器端运行 ibping 命令时指定的 -P 参数值.

`-L`：Base lid，来自服务器端运行 ibping 命令时指定的端口（-P 参数值）的 base lid（参考 ibstat），具体要查看服务端的 Base lid。

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

