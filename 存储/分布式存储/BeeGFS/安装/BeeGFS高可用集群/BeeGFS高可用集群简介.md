## 概述

从 2012.10 版本开始，BeeGFS 支持元数据（MetaData）和文件内容（File Contents）镜像。镜像功能集成到正常 BeeGFS 服务，所以，不需要单独的服务或第三方工具。这两种类型的镜像 （元数据镜像和文件内容镜像） 可以相互独立的使用。从 BeeGFS v6.0 开始，元数据镜像也扩展成为高可用性的特性。

存储和元数据镜像的高可用性是基于 Buddy Group。一般来说，一个 Buddy Group 是一对两个目标，内部管理彼此之间的数据复制。

Buddy Group 允许存储服务在两个目标之一失败时仍可以访问所有数据。它也支持把 Buddy Group 放在不同灾备区域，例如不同的机架或不同的服务器机房。

Storage Buddy Mirroring: 4 Servers with 1 Target per Server

<img src=".assets/how-to-build-a-parallel-file-system-beegfs-on-aws-high-availability1.png" alt="img" style="zoom: 67%;" />

存储服务器 Buddy 镜像也可以用于奇数个存储服务器。因为 BeeGFS Buddy Group 由独立的存储目标组成，独立于它们对服务器的分配是可行的，

如下面的示例图所示，每个服务器有 3 个服务器和 6 个存储目标组成。

Storage Buddy Mirroring: 3 Servers with 2 Targets per Server

<img src=".assets/how-to-build-a-parallel-file-system-beegfs-on-aws-high-availability2.png" alt="img" style="zoom:67%;" />


注意，这在元数据服务器上是不可能的，因为 BeeGFS 中元数据没有目标的概念。需要偶数个元数据服务器，以便每个元数据服务器都可以属于一个 Buddy Group。

在正常操作中，Buddy Group 中的一个存储目标（或元数据服务器）被认为是主存储服务，而另一个是辅存储服务。修改操作总是先发送到主服务器，主服务器负责镜像过程。文件内容和元数据是同步镜像的，即在将两个数据副本传输到服务器后，客户端操作完成。

如果无法访问 Buddy Group 的主存储目标或元数据服务器，则会将其标记为脱机，并发出到辅存储的故障转移。在这种情况下，以前的辅存储将成为新的主存储。这样的故障转移是透明的，并且在运行应用程序时不会丢失任何数据。故障转移将在短暂的延迟后发生，以确保在将更改信息传播到所有节点时系统的一致性。如果服务只是重新启动（例如，在滚动更新的情况下），此短延迟还可以避免不必要的重新同步。 

可以通过以下命令方面查询存储服务和元数据服务的节点状态

```bash
beegfs-ctl --listtargets --nodetype=storage --state

beegfs-ctl --listtargets --nodetype=meta --state 
```

只有在 BeeGFS 管理服务正在运行时，才能对 Buddy Group 进行故障转移。这意味着，如果具有 BeeGFS 管理服务的节点崩溃，则不会发生故障转移。因此，建议在不同的机器上运行 BeeGFS 管理服务。但是，不必为 BeeGFS 管理服务提供专用服务器。

## BeeGFS 高可用集群搭建

部署架构图

<img src=".assets/how-to-build-a-parallel-file-system-beegfs-on-aws-high-availability3.png" alt="img" style="zoom:150%;" />

组件系统信息

| 角色        | IP          | 主机名  | vCPU | 内存 （GB） | 网络带宽 （Gbps） | 系统盘   | 额外存储           | 备注               |
| ----------- | ----------- | ------- | ---- | ----------- | ----------------- | -------- | ------------------ | ------------------ |
| Management  | 10.241.10.1 | node1   | 2    | 4           | Up 10             | 100G SSD |                    |                    |
| Metadata    | 10.241.20.1 | node201 | 4    | 8           | Up 10             | 100G SSD | 1 x 100GB NVMe SSD |                    |
| Metadata    | 10.241.20.2 | node202 | 4    | 8           | Up 10             | 100G SSD | 1 x 100GB NVMe SSD |                    |
| Storage-I   | 10.241.30.1 | node301 | 16   | 32          | Up 10             | 100G SSD | 2 x 500GB SSD      | target：3011、3012 |
| Storage-II  | 10.241.30.2 | node302 | 16   | 32          | Up 10             | 100G SSD | 2 x 500GB SSD      | target：3021、3022 |
| Storage-III | 10.241.30.3 | node303 | 16   | 32          | Up 10             | 100G SSD | 2 x 500GB SSD      | target：3031、3032 |
| Client      | 10.241.40.1 | node4   | 2    | 4           | Up 10             | 100G SSD |                    |                    |

添加如下 hosts 至每台机器

```plain
10.241.10.1 node1
10.241.20.1 node201
10.241.20.2 node202
10.241.30.1 node301
10.241.30.2 node302
10.241.30.3 node303
10.241.40.1 node4
```

本次安装最新 stable 版本 7.3.2-el9.x86_64

```bash
cat > /etc/yum.repos.d/beegfs-rhel9.repo << _EOF_

[beegfs]
name=BeeGFS 7.3.2 (rhel9)

# If you have an active BeeGFS support contract, use the alternative URL below
# to retrieve early updates. Replace username/password with your account for
# the BeeGFS customer login area.
# baseurl=https://username:password@www.beegfs.io/login/release/beegfs_7.3.2/dists/rhel9
baseurl=https://www.beegfs.io/release/beegfs_7.3.2/dists/rhel9

gpgkey=https://www.beegfs.io/release/beegfs_7.3.2/gpg/GPG-KEY-beegfs
gpgcheck=1
enabled=0

_EOF_
```

每个节点预先安装工具

```bash
dnf install -y epel-release
dnf install -y crudini
```

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

### 节点安装

#### 安装 node1

安装管理服务应用

```bash
dnf install -y --enablerepo=beegfs beegfs-mgmtd
```

在对应目录创建管理服务

```bash
mkdir -p /data/beegfs/beegfs_mgmtd 
/opt/beegfs/sbin/beegfs-setup-mgmtd -p /data/beegfs/beegfs_mgmtd
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-mgmtd.conf '' connDisableAuthentication "true"
# 指定网卡
crudini --set /etc/beegfs/beegfs-mgmtd.conf '' connInterfacesFile "/etc/beegfs/conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-mgmtd.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-mgmtd.conf '' connInterfacesFile
```

启动服务

```bash
systemctl restart beegfs-mgmtd
systemctl enable beegfs-mgmtd
systemctl status beegfs-mgmtd
```

#### 安装 node201 / node202

安装元数据服务组件

```bash
dnf install -y --enablerepo=beegfs beegfs-meta
```

以下格式化 NVMe 卷成 xfs 文件系统，并挂载到 /data/lun_meta 路径

查看 NVMe 卷的名字，假设为 `/dev/nvme0n1`

```bash
lsblk
```

格式化成 xfs 文件系统

```bash
mkfs -t xfs /dev/nvme0n1
```

创建挂载点

```bash
mkdir -p /data/lun_meta
```

检查卷的 UUID，假设为 abcd-efgh-1234-5678

```bash
lsblk -o +UUID 
```

修改自动加载配置文件，添加：`UUID="abcd-efgh-1234-5678" /data/lun_meta xfs defaults,nofail 0 2`

```bash
echo 'UUID="abcd-efgh-1234-5678" /data/lun_meta xfs defaults,nofail 0 2' >> /etc/fstab
```

将格式化后的新卷挂载到 `/data/lun_meta`

```bash
mount -a
```

在对应目录创建元数据管理服务，并指定元数据服务 sid 为 201 或者 202，管理节点名称为 node1, 如下：

- 对 node201

```bash
/opt/beegfs/sbin/beegfs-setup-meta -p /data/lun_meta -s 201 -m node1
```

- 对 node202

```bash
/opt/beegfs/sbin/beegfs-setup-meta -p /data/lun_meta -s 202 -m node1
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-meta.conf '' connDisableAuthentication "true"
# 指定网卡
crudini --set /etc/beegfs/beegfs-meta.conf '' connInterfacesFile "/etc/beegfs/conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-meta.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-meta.conf '' connInterfacesFile
```

启动服务

```bash
systemctl restart beegfs-meta
systemctl enable beegfs-meta
systemctl status beegfs-meta
```

#### 安装 node301 / node302 / node303

安装存储管理服务

```bash
dnf install -y --enablerepo=beegfs beegfs-storage
```

到此需要格式化 NVMe 卷，其过程与配置自己加载请参考元数据服务的卷配置过程，假设挂载路径为 `/mnt/lun_storage_1`、`/mnt/lun_storage_2`

格式化成 xfs 文件系统

```bash
mkfs -t xfs /dev/nvme0n1
mkfs -t xfs /dev/nvme1n1
```

创建挂载点

```bash
mkdir /mnt/lun_storage_1
mkdir /mnt/lun_storage_2
```

检查卷的 UUID，假设为 `9f677321-d52d-4eb9-b00b-119c251aad26` 和 `9ea0044e-1774-416a-aff5-31afe054ddac`

```bash
lsblk -o +UUID 
```

编辑 fstab 文件，配置 Mount 点信息，添加：`UUID="abcd-efgh-1234-5678" /data/lun_meta xfs defaults,nofail 0 2`

```bash
echo 'UUID="9f677321-d52d-4eb9-b00b-119c251aad26" /mnt/lun_storage_1 xfs defaults,nofail 0 2' >> /etc/fstab
echo 'UUID="9ea0044e-1774-416a-aff5-31afe054ddac" /mnt/lun_storage_2 xfs defaults,nofail 0 2' >> /etc/fstab
```

将格式化后的新卷挂载到 `/data/lun_meta`

```bash
mount -a
```

加入本地存储卷到 BeeGFS 存储中，如下，301 是存储节点代号，3011是目前存储节点代码，在 301 实例上如果增加另外的卷，可以选择 3012,3013 等 301{n} 形式进行存储扩容。

- 对 node301

```bash
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_1 -s 301 -i 3011 -m node1
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_2 -s 301 -i 3012 -m node1
```

- 对 node302

```bash
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_1 -s 302 -i 3021 -m node1
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_2 -s 302 -i 3022 -m node1
```

- 对 node303

```bash
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_1 -s 303 -i 3031 -m node1
/opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_2 -s 303 -i 3032 -m node1
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-storage.conf '' connDisableAuthentication "true"
# 指定网卡
crudini --set /etc/beegfs/beegfs-storage.conf '' connInterfacesFile "/etc/beegfs/conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-storage.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-storage.conf '' connInterfacesFile
```

启动服务

```bash
systemctl restart beegfs-storage
systemctl enable beegfs-storage
systemctl status beegfs-storage
```

#### 安装 node4

安装客户端命令行工具

```bash
dnf install -y --enablerepo=beegfs \
  beegfs-client beegfs-helperd beegfs-utils
```

指定管理节点 node1

```bash
/opt/beegfs/sbin/beegfs-setup-client -m node1
```

修改 `/etc/beegfs/beegfs-mounts.conf`，第一项是挂载目录，第二项是配置文件路径，如下:

```bash
/mnt/beegfs /etc/beegfs/beegfs-client.conf
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-helperd.conf '' connDisableAuthentication "true"
crudini --set /etc/beegfs/beegfs-client.conf '' connDisableAuthentication "true"
# 指定网卡
crudini --set /etc/beegfs/beegfs-client.conf '' connInterfacesFile "/etc/beegfs/conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-helperd.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-client.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-client.conf '' connInterfacesFile
```

启动 heplerd 服务，提供日志与 DNS 解析等服务

```bash
systemctl restart beegfs-helperd
systemctl enable beegfs-helperd
systemctl status beegfs-helperd
```

启动客户端服务

```bash
systemctl restart beegfs-client
systemctl enable beegfs-client
systemctl status beegfs-client
```

rockylinux9 无法直接启动，修改如下：

```bash
sed -i 's|#include <stdarg.h>|//#include <linux/stdarg.h>|g' /opt/beegfs/src/client/client_module_7/source/common/Common.h

sed -i 's|PDE_DATA(const struct inode \*)|pde_data(const struct inode \*inode)|g' /opt/beegfs/src/client/client_module_7/build/KernelFeatureDetection.mk

sed -i 's|PDE_DATA(|pde_data(|g' /opt/beegfs/src/client/client_module_7/source/filesystem/ProcFs.c
```

其他修改处：

```bash
diff --git a/client_module/source/Makefile b/client_module/source/Makefile
index 375f647..d8f612c 100644
--- a/client_module/source/Makefile
+++ b/client_module/source/Makefile
@@ -184,6 +184,8 @@ SOURCES := \
 
 ${TARGET}-y    := $(patsubst %.c,%.o,$(SOURCES))
 
+NOSTDINC_FLAGS+=-isystem $(shell $(CC) -print-file-name=include)
+
 ifneq ($(OFED_INCLUDE_PATH),)
 
```

查看节点列表

```bash
# 元数据节点列表
beegfs-ctl --listnodes --nodetype=meta

# 存储节点列表
beegfs-ctl --listnodes --nodetype=storage

# 客户端节点列表
beegfs-ctl --listnodes --nodetype=client
```

查看存储目标

```bash
# 元数据节点列表
beegfs-ctl --listtargets --mirrorgroups
```

### 目标状态查询

元数据 targets

```bash
> beegfs-ctl --listtargets --nodetype=meta --state
```

存储 targets

```bash
> beegfs-ctl --listtargets --nodetype=storage --state
```

#### 可达性状态描述

可达性状态用来描述系统是否可以访问目标。它由管理服务监视。这种状态是 Buddy 镜像的重要组成部分，因为 Buddy 镜像组中的目标的故障转移是基于主目标的可达性状态的。

定义了以下可达状态:

- Online：可以到达目标或节点。
- Offline：检测到此目标或节点的通信失败。这是一个中间状态，在这个状态中，关于可能发生故障的信息将传播到所有节点，以便系统为将此目标转换为脱机状态做好准备。如果不能达到的目标或节点快速关机，回来后 （如短服务重启滚动更新的一部分）, 或者是遥不可及的由于临时网络故障，它还可以回到不在线状态和故障转移或同步将会发生。
- Offline：无法到达目标。如果这是镜像 Buddy Group 的主要目标，则在目标转换到脱机状态时将立即发出故障转移。

#### 一致性状态描述

一致性状态描述存储目标或元数据节点上的数据状态。定义了以下一致性状态:

- Good：数据被认为是好的。需要重新同步：这种一致性状态只适用于镜像 Buddy Group 的次要目标或节点。目标或节点上的数据被认为是不同步的（例如，因为它是离线的），需要重新同步。
- Needs-resync：目标或节点上的数据被认为是不同步的，重新同步的尝试正在进行中。
- Bad：目标或节点上的数据被认为是不同步的，重新同步的尝试失败。请查看日志文件以获得关于为什么选择此状态的更多信息。

### 配置 Meta Buddy / Storage Buddy

自动创建元数据 Group

```bash
> beegfs-ctl --addmirrorgroup --automatic --nodetype=meta

New mirror groups:
BuddyGroupID   Node type Node
============   ========= ====
           1     primary      201 @ beegfs-meta node201 [ID: 201]
               secondary      202 @ beegfs-meta node202 [ID: 202]
```

自动创建存储 Group

```bash
> beegfs-ctl --addmirrorgroup --automatic --nodetype=storage

New mirror groups:
BuddyGroupID Target type Target
============ =========== ======
           1     primary     3011 @ beegfs-storage node301 [ID: 301]
               secondary     3021 @ beegfs-storage node302 [ID: 302]
           2     primary     3031 @ beegfs-storage node303 [ID: 303]
               secondary     3012 @ beegfs-storage node301 [ID: 301]
           3     primary     3022 @ beegfs-storage node302 [ID: 302]
               secondary     3032 @ beegfs-storage node303 [ID: 303]

Mirror buddy group successfully set: groupID 1 -> target IDs 3011, 3021
Mirror buddy group successfully set: groupID 2 -> target IDs 3031, 3012
Mirror buddy group successfully set: groupID 3 -> target IDs 3022, 3032
```

激活 metadata mirroring，需要重启所有的 meta service，参考：<https://www.beegfs.io/wiki/MDMirror#hn_59ca4f8bbb_2>

```bash
> beegfs-ctl --mirrormd
NOTE:
 To complete activating metadata mirroring, please remount any clients and
 restart all metadata servers now.
```

重启 beegfs-meta 服务

```bash
systemctl restart beegfs-meta
```

> 如果想要设置自定义组 id，或者想要确保 Buddy Group 位于不同的故障域中 (例如，不同的机架)，那么手动定义镜像 Buddy Group 是非常有用的。使用 beegfs-ctl 工具手动定义镜像 Buddy Group。通过使用下面的命令，您可以创建一个 ID 为 100 的 Buddy Group，由目标 1 和目标 2 组成
>
> ```bash
> # 手动指定 Buddy Group
> beegfs-ctl --addmirrorgroup --nodetype=storage --primary=3011 --secondary=3021 --groupid=1
> ```

查询元数据服务状态

```bash
> beegfs-ctl --listmirrorgroups --nodetype=meta
     BuddyGroupID     PrimaryNodeID   SecondaryNodeID
     ============     =============   ===============
                1               201               202

```

查询存储服务状态

```bash
> beegfs-ctl --listmirrorgroups --nodetype=storage
     BuddyGroupID   PrimaryTargetID SecondaryTargetID
     ============   =============== =================
                1              3011              3021
                2              3031              3012
                3              3022              3032

> beegfs-ctl --listtargets --mirrorgroups
MirrorGroupID MGMemberType TargetID   NodeID
============= ============ ========   ======
            1      primary     3011      301
            1    secondary     3021      302
            2      primary     3031      303
            2    secondary     3012      301
            3      primary     3022      302
            3    secondary     3032      303
```

系统中定义了存储 Buddy 镜像组之后，必须定义一个使用它的数据条带模式。

获取目录属性

```bash
> beegfs-ctl --getentryinfo /mnt/beegfs
EntryID: root
Metadata buddy group: 1
Current primary metadata node: node201 [ID: 201]
Stripe pattern details:
+ Type: RAID0
+ Chunksize: 512K
+ Number of storage targets: desired: 4
+ Storage Pool: 1 (Default)
```

创建 RAID0 模式的目录

```bash
> mkdir /mnt/beegfs/raid0-dir

> beegfs-ctl --setpattern --pattern=raid0 --chunksize=1m --numtargets=4 /mnt/beegfs/raid0-dir
New chunksize: 1048576
New number of storage targets: 4

> beegfs-ctl --getentryinfo /mnt/beegfs/raid0-dir
EntryID: 0-5E9E76DD-C9
Metadata buddy group: 1
Current primary metadata node: node201 [ID: 201]
Stripe pattern details:
+ Type: RAID0
+ Chunksize: 1M
+ Number of storage targets: desired: 4
+ Storage Pool: 1 (Default)
```

创建 Buddy 模式的目录

```bash
> mkdir /mnt/beegfs/buddy-dir

> beegfs-ctl --setpattern --pattern=buddymirror --chunksize=1m --numtargets=4 /mnt/beegfs/buddy-dir
New chunksize: 1048576
New number of storage targets: 4

> beegfs-ctl --getentryinfo /mnt/beegfs/buddy-dir
EntryID: 0-5E9E7791-C9
Metadata buddy group: 1
Current primary metadata node: node201 [ID: 201]
Stripe pattern details:
+ Type: Buddy Mirror
+ Chunksize: 1M
+ Number of storage targets: desired: 4
+ Storage Pool: 1 (Default)
```

### 故障恢复

BeeGFS 的 Buddy Group 支持自动的故障转移和恢复。如果存储目标或元数据服务发生故障，会将其标记为脱机，并且不会获取数据更新。通常，当目标或服务器重新注册时，它将自动与 Buddy Group 中的剩余镜像同步（自动修复）。但是，在某些情况下，也可以支持手动启动同步过程。

以下通过分别模拟存储服务和元数据服务的故障，演示在发生故障时如何进行服务恢复和数据同步操作。

获取元数据服务的同步状态

```bash
> beegfs-ctl --resyncstats --nodetype=meta --mirrorgroupid=1

Job state: Not started
# of discovered dirs: 0
# of discovery errors: 0
# of synced dirs: 0
# of synced files: 0
# of dir sync errors: 0
# of file sync errors: 0
# of client sessions to sync: 0
# of synced client sessions: 0
session sync error: No
# of modification objects synced: 0
# of modification sync errors: 0
```

获取存储服务的同步状态

```bash
> beegfs-ctl --resyncstats --nodetype=storage --mirrorgroupid=1

Job state: Not started
# of discovered dirs: 0
# of discovered files: 0
# of dir sync candidates: 0
# of file sync candidates: 0
# of synced dirs: 0
# of synced files: 0
# of dir sync errors: 0
# of file sync errors: 0
```

（1）模拟 Buddy Group 存储服务的 Failover

首先模拟写入1GB数据

```bash
> cd /mnt/beegfs/buddy-dir

> dd if=/dev/zero of=testdata bs=1G count=1
1+0 records in
1+0 records out
1073741824 bytes (1.1 GB, 1.0 GiB) copied, 1.59144 s, 675 MB/s
```

登陆 node301，停止 beegfs-storage 服务

```bash
systemctl stop beegfs-storage
```

查询存储服务，301 的目标服务已经变为 Offline 状态

```bash
> beegfs-ctl --listtargets --nodetype=storage --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
    3011          Offline         Good      301
    3012          Offline         Good      301
    3021           Online         Good      302
    3022           Online         Good      302
    3031           Online         Good      303
    3032           Online         Good      303
```

继续模拟写入 1GB 数据，服务是可用的

```bash
> dd if=/dev/zero of=testdata2 bs=1G count=1

1+0 records in
1+0 records out
1073741824 bytes (1.1 GB, 1.0 GiB) copied, 3.67663 s, 292 MB/s
```

恢复 301 节点的存储服务

```bash
systemctl start beegfs-storage
```

301 节点的存储服务在自动恢复

```bash
> beegfs-ctl --listtargets --nodetype=storage --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
    3011           Online         Good      301
    3012           Online Needs-resync      301
    3021           Online         Good      302
    3022           Online         Good      302
    3031           Online         Good      303
    3032           Online         Good      303
```

使用命令手动触发数据同步

```bash
> beegfs-ctl --startresync --nodetype=storage --targetid=3011 --timestamp=0 --restart

Waiting for running resyncs to abort.
Resync request sent.

> beegfs-ctl --startresync --nodetype=storage --targetid=3012 --timestamp=0 --restart

Waiting for running resyncs to abort.
Resync request sent.
```

检查 301 节点的存储服务已经完全恢复

```bash
> beegfs-ctl --listtargets --nodetype=storage --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
    3011           Online         Good      301
    3012           Online         Good      301
    3021           Online         Good      302
    3022           Online         Good      302
    3031           Online         Good      303
    3032           Online         Good      303
```

（2）模拟元数据服务的 Failover

查询元数据服务状态

```bash
> beegfs-ctl --listtargets --nodetype=meta --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
     201           Online         Good      201
     202           Online         Good      202
```

登陆 node201，停止 beegfs-meta 服务

```bash
systemctl stop beegfs-meta
```

查询元数据服务状态，201 节点已经在脱机状态

```bash
> beegfs-ctl --listtargets --nodetype=meta --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
     201 Probably-offline         Good      201
     202           Online         Good      202
```

模拟写入 1GB 数据，成功写入

```bash
> dd if=/dev/zero of=testdata3 bs=1G count=1

1+0 records in
1+0 records out
1073741824 bytes (1.1 GB, 1.0 GiB) copied, 1.71778 s, 625 MB/s
```

查询元数据服务状态，已经完全离线

```bash
> beegfs-ctl --listtargets --nodetype=meta --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
     201          Offline Needs-resync      201
     202           Online         Good      202
```

恢复 201 节点的元数据服务  

```bash
systemctl start beegfs-meta
```

201 节点的元数据在自动恢复

```bash
> beegfs-ctl --listtargets --nodetype=meta --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
     201           Online Needs-resync      201
     202           Online         Good      202
```

可以使用命令手动触发数据同步

```bash
> beegfs-ctl --startresync --nodetype=meta --nodeid=201

Resync request sent.
```

查询元数据服务，已经完全恢复

```bash
> beegfs-ctl --listtargets --nodetype=meta --state

TargetID     Reachability  Consistency   NodeID
========     ============  ===========   ======
     201           Online         Good      201
     202           Online         Good      202
```