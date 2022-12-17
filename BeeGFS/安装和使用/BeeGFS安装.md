
## 环境准备

本次安装最新 stable 版本 7.3.2-el9.x86_64

操作系统为 rocky 9

```plain
NAME="Rocky Linux"
VERSION="9.0 (Blue Onyx)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.0"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Rocky Linux 9.0 (Blue Onyx)"
ANSI_COLOR="0;32"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:rocky:rocky:9::baseos"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
ROCKY_SUPPORT_PRODUCT="Rocky-Linux-9"
ROCKY_SUPPORT_PRODUCT_VERSION="9.0"
REDHAT_SUPPORT_PRODUCT="Rocky Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="9.0"
```

节点规划如下：

```plin
Host Services:
    devmaster3: Management Server (IP:10.244.244.103)

    devmaster3: Metadata Server (IP:10.244.244.103)

    devmaster1: Storage Server (IP:10.244.244.101)
    devmaster2: Storage Server (IP:10.244.244.102)
    devmaster3: Storage Server (IP:10.244.244.103)

    devmaster1: Client (IP:10.244.244.101)
    devmaster2: Client (IP:10.244.244.102)
    devmaster3: Client (IP:10.244.244.103)

    devmaster3: Mon Server (IP:10.244.244.103)(可选项)


Storage:
  Storage servers and metadata servers with xfs, mounted to "/mnt/beegfs-data"
    # Storage servers with xfs, mounted to "/mnt/beegfs-storage"
    # ext4 对小文件支持更好
    # Metadata servers with ext4, mounted to "/mnt/beegfs-metadata"
```

所有节点配置 `/etc/hosts`

```plain
10.244.244.101 devmaster1.local.liaosirui.com
10.244.244.102 devmaster2.local.liaosirui.com
10.244.244.103 devmaster3.local.liaosirui.com

10.244.244.101 devmaster1
10.244.244.102 devmaster2
10.244.244.103 devmaster3
```

所有节点关闭防火墙和 SELINUX

```bash
systemctl stop firewalld
systemctl disable firewalld

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g'/etc/sysconfig/selinux
```

## 初始化磁盘

在同时是 Metadata 节点和 Storage 节点初始化 metadata 和 storage 的存储如下：

```bash
Device         Boot Start       End   Sectors   Size Id Type
/dev/nvme1n1p1       2048 500118191 500116144 238.5G 83 Linux
```

格式化并挂载到 /mnt/beegfs-data，同时写入 fstab

```bash
mkfs.xfs /dev/nvme1n1p1
mkdir -p /mnt/beegfs-data
echo /dev/nvme1n1p1 /mnt/beegfs-data xfs defaults 0 0 | tee -a /etc/fstab
mount -a
df -h /mnt/beegfs-data
```

~~打开 Metadata Server 的扩展属性功能~~

```bash
# xfs 无法执行
# tune2fs -o user_xattr /dev/nvme1n1p1
```

## 节点安装（Package Download and Installation）

1. 在所有节点下载 BeeGFS 的 repo 文件到 /etc/yum.repos.d/

   ```bash
   wget -O /etc/yum.repos.d/beegfs-rhel9.repo https://www.beegfs.io/release/beegfs_7.3.2/dists/beegfs-rhel9.repo
   ```

   安装依赖的包

   ```bash
   dnf install kernel-devel
   dnf groupinstall -y "Development Tools"
   ```

2. 在管理节点安装 Management Service

   ```bash
   dnf install beegfs-mgmtd
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
   dnf install beegfs-mon
   ```

7. 如果需要使用 Infiniband RDMA 功能，还需要在 Metadata 和 Storage 节点安装 libbeegfs-ib

   ```bash
   dnf install libbeegfs-ib
   ```

## Management 节点配置

Management 节点配置 Management Service，管理服务需要知道它可以在哪里存储数据。它只存储一些
节点信息，比如连接性数据，因此不需要太多的存储空间，而且它的数据访问不是性能关键。因此，此服务
通常可以不在专用机器上运行。

```bash
/opt/beegfs/sbin/beegfs-setup-mgmtd -p /mnt/beegfs-data/beegfs_mgmtd
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
# eth0
#
```

## Meta 节点配置

Meta 节点配置 Metadata Service，元数据服务需要知道它可以在哪里存储数据，以及管理服务在哪里运
行。

选择定义一个定制的数字元数据服务 ID(范围 1~65535)。这里我们的 Metadata 节点是第三个节点，所以
这里我们选择数字  “3”作为元数据服务 ID。

```bash
# devmaster3
/opt/beegfs/sbin/beegfs-setup-meta -p /mnt/beegfs-data/beegfs_meta -s 3 -m 10.244.244.103
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
# eth0
#
```

## Storage 节点配置

Storage 节点配置 Storage Service，存储服务需要知道它可以在哪里存储数据，以及如何到达管理服
务器。

通常，每个存储服务将在不同的机器上运行多个存储服务和/或多个存储目标（例如多个 RAID 卷）。选
择定义自定义数字存储服务 ID 和数字存储目标 ID(范围1~65535)。

这里以第一个 Storage节点为例，选择编号 “1” 作为此存储服务的 ID，并使用“101”作为存储目标 ID，以表明这是存储服务 “1” 的第一个目标(“01”)。

```bash
# devmaster1
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/beegfs-data/beegfs_storage -s 1 -i 101 -m 10.244.244.103

# devmaster2
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/beegfs-data/beegfs_storage -s 2 -i 201 -m 10.244.244.103

# devmaster3
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/beegfs-data/beegfs_storage -s 3 -i 301 -m 10.244.244.103
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
# eth0
#

### Client 节点配置

Client 节点配置 Client（BeeGFS 默认会挂载到 /mnt/beegfs，可以自行在配置文件 /etc/beegfs/
beegfs-mounts.conf 中修改）

```bash
# devmaster1 2 3 相同
/opt/beegfs/sbin/beegfs-setup-client -m 10.244.244.103
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
# eth0
#
```

## 监控节点

监控节点修改配置文件：

```bash
vi /etc/beegfs/beegfs-mon.conf
```

- 配置管理节点地址

```ini
sysMgmtdHost = 10.244.244.103
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
# eth0
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

执行完以上配置后，重启所有节点，并确认重启后所有节点上的服务均已经正常启动，到这里 BeeGFS 的基
本配置就完成了。

## 检查节点状态

```bash
beegfs-ctl --listnodes --nodetype=management --nicdetails
beegfs-ctl --listnodes --nodetype=meta --nicdetails
beegfs-ctl --listnodes --nodetype=storage --nicdetails
beegfs-ctl --listnodes --nodetype=client --nicdetails
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
