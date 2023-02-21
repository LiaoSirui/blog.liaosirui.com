
## 环境准备

本次安装最新 stable 版本 7.3.2-el9.x86_64

操作系统为 rocky 9

```plain
NAME="Rocky Linux"
VERSION="9.1 (Blue Onyx)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.1"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Rocky Linux 9.1 (Blue Onyx)"
ANSI_COLOR="0;32"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:rocky:rocky:9::baseos"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
ROCKY_SUPPORT_PRODUCT="Rocky-Linux-9"
ROCKY_SUPPORT_PRODUCT_VERSION="9.1"
REDHAT_SUPPORT_PRODUCT="Rocky Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="9.1"
```

节点规划如下：

```plin
Host Services:
    devmaster: Management Server (ib0, IP:10.245.245.201)

    devmaster: Metadata Server (ib0, IP:10.245.245.201)

    devmaster: Storage Server (ib0, IP:10.245.245.201)
    devnode1: Storage Server (ib0, IP:10.245.245.211)
    devnode2: Storage Server (ib0, IP:10.245.245.212)

    devmaster: Client (ib0, IP:10.245.245.201)
    devnode1: Client (ib0, IP:10.245.245.211)
    devnode2: Client (ib0, IP:10.245.245.212)

    devmaster: Mon Server (ib0, IP:10.245.245.201)(可选项)


Storage:
  Storage servers with xfs, mounted to "/beegfs/storage"
  # ext4 对小文件支持更好
  Metadata servers with ext4, mounted to "/beegfs/metadata"
```

所有节点配置 `/etc/hosts`

```plain
10.245.245.201 ib-devmaster
10.245.245.211 ib-devnode1
10.245.245.212 ib-devnode2
```

所有节点关闭防火墙和 SELINUX

```bash
systemctl stop firewalld
systemctl disable firewalld

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g'/etc/sysconfig/selinux
```

参考文档：<https://aws.amazon.com/cn/blogs/china/how-to-build-beegfs-on-aws-system/>

## 初始化磁盘

- Metadata 节点

在 Metadata 节点初始化 metadata 和 storage 的存储如下：

```bash
> df -h /dev/mapper/rl_marketplace-beegfs--meta

Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        4.0M     0  4.0M   0% /dev
```

格式化并挂载到 /mnt/beegfs-data，同时写入 fstab

```bash
mkfs.ext4 /dev/mapper/rl_marketplace-beegfs--meta

mkdir -p /beegfs/metadata
echo /dev/mapper/rl_marketplace-beegfs--meta /beegfs/metadata ext4 defaults 1 2 | tee -a /etc/fstab

mount -a
```

查看挂载信息

```bash
> df -h /beegfs/metadata

Filesystem                               Size  Used Avail Use% Mounted on
/dev/mapper/rl_marketplace-beegfs--meta  295G   28K  280G   1% /beegfs/metadata
```

打开 Metadata Server 的扩展属性功能

```bash
# 注意 xfs 无法执行
tune2fs -o user_xattr /dev/mapper/rl_marketplace-beegfs--meta
```

-  Storage 节点

这里规划一个 nvme 分区（256 G) + 14 个 hhd 分区（共 16 TB）

按照 xfs 方式进行初始化和挂载即可

## 节点安装（Package Download and Installation）

1. 在所有节点下载 BeeGFS 的 repo 文件到 /etc/yum.repos.d/

   ```bash
   wget -O /etc/yum.repos.d/beegfs-rhel9.repo https://www.beegfs.io/release/beegfs_7.3.2/dists/beegfs-rhel9.repo
   ```

   安装依赖的包

   ```bash
   dnf install -y kernel-devel
   dnf groupinstall -y "Development Tools"
   ```

2. 在管理节点安装 Management Service

   ```bash
   dnf install -y beegfs-mgmtd
   ```

3. 在 Metadata 节点安装 Metadata Service

   ```bash
   dnf install -y beegfs-meta
   ```

4. 在 Storage 节点安装 Storage Service

   ```bash
   dnf install -y beegfs-storage
   ```

5. 在 Client 节点安装 Client and Command-line Utils

   ```bash
   dnf install -y beegfs-client beegfs-helperd beegfs-utils beegfs-common kernel-devel
   ```

6. 在监控节点（Mon）安装 Mon Service

   ```bash
   dnf install -y beegfs-mon
   ```

7. 如果需要使用 Infiniband RDMA 功能，还需要在 Metadata 和 Storage 节点安装 libbeegfs-ib

   ```bash
   dnf install -y libbeegfs-ib
   ```

## Management 节点配置

Management 节点配置 Management Service，管理服务需要知道它可以在哪里存储数据。它只存储一些
节点信息，比如连接性数据，因此不需要太多的存储空间，而且它的数据访问不是性能关键。因此，此服务
通常可以不在专用机器上运行。

```bash
/opt/beegfs/sbin/beegfs-setup-mgmtd -p /beegfs/mgmtd
```

修改配置文件

```bash
vi /etc/beegfs/beegfs-mgmtd.conf
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```

## Meta 节点配置

Meta 节点配置 Metadata Service，元数据服务需要知道它可以在哪里存储数据，以及管理服务在哪里运行。

选择定义一个定制的数字元数据服务 ID (范围 1~65535)。这里我们的 Metadata 节点是第三个节点，所以这里我们选择数字 `1` 作为元数据服务 ID。

```bash
# devmaster
/opt/beegfs/sbin/beegfs-setup-meta -p /beegfs/metadata -s 1 -m 10.245.245.201
```

修改配置文件

```bash
vi /etc/beegfs/beegfs-meta.conf
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```

## Storage 节点配置

Storage 节点配置 Storage Service，存储服务需要知道它可以在哪里存储数据，以及如何到达管理服务器。

通常，每个存储服务将在不同的机器上运行多个存储服务和/或多个存储目标（例如多个 RAID 卷）。

选择自定义数字存储服务 ID 和数字存储目标 ID (范围1~65535)。

这里以第一个 Storage节点为例，选择编号 `1` 作为此存储服务的 ID，并使用 `101` 作为存储目标 ID，以表明这是存储服务 `1` 的第一个目标( `01`)。

依次添加 pool：

```bash
# id 2
beegfs-ctl --addstoragepool --desc="ssd"
# id 3
beegfs-ctl --addstoragepool --desc="hdd"
```



依次添加 target：

```bash
# devmaster
## ssd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool1001 -s 1 -P 2 -i 1001 -m 10.245.245.201
## hdd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2001 -s 1 -P 3 -i 2001 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2002 -s 1 -P 3 -i 2002 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2003 -s 1 -P 3 -i 2003 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2004 -s 1 -P 3 -i 2004 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2005 -s 1 -P 3 -i 2005 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2006 -s 1 -P 3 -i 2006 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2007 -s 1 -P 3 -i 2007 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2008 -s 1 -P 3 -i 2008 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2009 -s 1 -P 3 -i 2009 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2010 -s 1 -P 3 -i 2010 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2011 -s 1 -P 3 -i 2011 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2012 -s 1 -P 3 -i 2012 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2013 -s 1 -P 3 -i 2013 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2014 -s 1 -P 3 -i 2014 -m 10.245.245.201


# devnode1
## ssd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool1101 -s 2 -P 2 -i 1101 -m 10.245.245.201
## hdd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2101 -s 2 -P 3 -i 2101 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2102 -s 2 -P 3 -i 2102 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2103 -s 2 -P 3 -i 2103 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2104 -s 2 -P 3 -i 2104 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2105 -s 2 -P 3 -i 2105 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2106 -s 2 -P 3 -i 2106 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2107 -s 2 -P 3 -i 2107 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2108 -s 2 -P 3 -i 2108 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2109 -s 2 -P 3 -i 2109 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2110 -s 2 -P 3 -i 2110 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2111 -s 2 -P 3 -i 2111 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2112 -s 2 -P 3 -i 2112 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2113 -s 2 -P 3 -i 2113 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2114 -s 2 -P 3 -i 2114 -m 10.245.245.201


# devnode2
## ssd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool1201 -s 3 -P 2 -i 1201 -m 10.245.245.201
## hdd
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2201 -s 3 -P 3 -i 2201 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2202 -s 3 -P 3 -i 2202 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2203 -s 3 -P 3 -i 2203 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2204 -s 3 -P 3 -i 2204 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2205 -s 3 -P 3 -i 2205 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2206 -s 3 -P 3 -i 2206 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2207 -s 3 -P 3 -i 2207 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2208 -s 3 -P 3 -i 2208 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2209 -s 3 -P 3 -i 2209 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2210 -s 3 -P 3 -i 2210 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2211 -s 3 -P 3 -i 2211 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2212 -s 3 -P 3 -i 2212 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2213 -s 3 -P 3 -i 2213 -m 10.245.245.201
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storage/pool2214 -s 3 -P 3 -i 2214 -m 10.245.245.201

```

修改配置文件

```bash
vi /etc/beegfs/beegfs-storage.conf
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```

## Client 节点配置

Client 节点配置 Client（BeeGFS 默认会挂载到 /mnt/beegfs，可以自行在配置文件 `/etc/beegfs/beegfs-mounts.conf` 中修改）

```bash
# 所有节点相同
/opt/beegfs/sbin/beegfs-setup-client -m 10.245.245.201
```

修改配置文件

```bash
vi /etc/beegfs/beegfs-helperd.conf
vi /etc/beegfs/beegfs-client.conf
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf
connRDMAInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```

## 监控节点

监控节点修改配置文件：

```bash
vi /etc/beegfs/beegfs-mon.conf
```

- 配置管理节点地址

```ini
sysMgmtdHost = 10.245.245.201
```

- 配置不使用认证

```ini
connDisableAuthentication = true
```

- 配置网卡

```ini
connInterfacesFile = /etc/beegfs/conn-inf.conf

# /etc/beegfs/conn-inf.conf 内容如下
# 
# ib0
#
```

## 启动服务

以上配置完成后，在所有节点启动服务并设置开机自动启动

```bash
   Management 节点:
      systemctl start beegfs-mgmtd
      systemctl enable beegfs-mgmtd
   Metadata 节点:
      systemctl start beegfs-meta
      systemctl enable beegfs-meta
   Storage 节点:
      systemctl start beegfs-storage   
      systemctl enable beegfs-storage 
   Client 节点:
      systemctl start beegfs-helperd
      systemctl enable beegfs-helperd
      systemctl start beegfs-client
      systemctl enable beegfs-client
   Mon 节点:
      systemctl start beegfs-mon
      systemctl enable beegfs-mon
```

## 重启

执行完以上配置后，重启所有节点，并确认重启后所有节点上的服务均已经正常启动，到这里 BeeGFS 的基本配置就完成了。

## 检查节点状态

```bash
beegfs-ctl --listnodes --nodetype=management --nicdetails
beegfs-ctl --listnodes --nodetype=meta --nicdetails
beegfs-ctl --listnodes --nodetype=storage --nicdetails
beegfs-ctl --listnodes --nodetype=client --nicdetails
```

查看存储池

```bash
beegfs-ctl --liststoragepools
```

查看存储目标

```bash
beegfs-ctl --listtargets
```

显示 Client 实际使用的连接

```bash
beegfs-net
```

显示服务的连接性

```bash
beegfs-check-servers
```

显示存储和元数据目标的空闲空间和索引节点

```bash
beegfs-df
```

查看 Meta 镜像组

```bash
beegfs-ctl --listmirrorgroups --nodetype=meta
```
