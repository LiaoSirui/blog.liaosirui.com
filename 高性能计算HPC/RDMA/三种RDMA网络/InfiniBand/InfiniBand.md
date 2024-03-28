
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

## 参考文档

- <https://www.cnblogs.com/sctb/p/13179542.html>

- <https://www.sdnlab.com/26283.html>
