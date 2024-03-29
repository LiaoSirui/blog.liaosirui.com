
## InfiniBand

InfiniBand：

- InfiniBand 网络的物理链路协议
- InfiniBand Verbs API，这是远程直接访问（RDMA）技术的实现

## 型号

```bash
> lspci | grep -i connect

0a:00.0 Network controller: Mellanox Technologies MT27520 Family [ConnectX-3 Pro]
```

- Mellanox 是厂商, 该厂产品覆盖 Infiniband 网络和以太网网络的网卡, 交换设备, 软件等
- ConnectX-3 Pro 是产品名称
- MT27520 具体的型号

## 驱动安装

### 编译安装

OFED 就是网卡的驱动, Mellanox 所有网卡的驱动都用 OFE

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

解压直接执行安装即可

```bash
dnf install -y pciutils gtk2 atk cairo gcc-gfortran tcsh lsof tcl tk perl usbutils

./mlnxofedinstall
```

注意驱动默认会更新网卡的固件到最新版本，如果不想更新，可以配置参数

### 从软件源中安装

````bash
dnf install -y \
	iproute libibverbs libibverbs-utils \
	infiniband-diags \
	perftest \
	rdma-core \
	mlnx_tune
````

如果没有内核模块，需要

```bash
# refer: http://elrepo.org/tiki/HomePage
dnf install -y https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm

dnf --disablerepo=\* --enablerepo=elrepo install -y kmod-mlx4

echo "mlx4_ib" > /etc/modules-load.d/mlx4.conf
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

- EL 系列配置官方文档地址：<https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/9/html/configuring_infiniband_and_rdma_networks/index>

- <https://www.cnblogs.com/sctb/p/13179542.html>

- <https://www.sdnlab.com/26283.html>
