## BeeGFS 高可用集群搭建

参考文档：<https://aws.amazon.com/cn/blogs/china/how-to-build-beegfs-on-aws-system/>

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

## 环境准备

### 安装版本规划

本次安装最新 stable 版本 `7.3.3-el9.x86_64`，官方 Releae 地址：<http://www.beegfs.io/release/>

```bash
cat > /etc/yum.repos.d/beegfs-rhel9.repo << _EOF_

[beegfs]
name=BeeGFS 7.3.3 (rhel9)

# If you have an active BeeGFS support contract, use the alternative URL below
# to retrieve early updates. Replace username/password with your account for
# the BeeGFS customer login area.
# baseurl=https://username:password@www.beegfs.io/login/release/beegfs_7.3.3/dists/rhel9
baseurl=https://www.beegfs.io/release/beegfs_7.3.3/dists/rhel9

gpgkey=https://www.beegfs.io/release/beegfs_7.3.3/gpg/GPG-KEY-beegfs
gpgcheck=1
enabled=0

_EOF_
```

每个节点预先安装工具

```bash
dnf install -y epel-release
dnf install -y crudini
dnf install -y 'dnf-command(versionlock)'
```

### 节点规划

节点规划如下：

```plin
Host Services:

    beegfs-node1: Management Server (eth0, IP: 172.17.0.2)

    beegfs-node1: Metadata Server (eth0, IP: 172.17.0.2)
    beegfs-node2: Metadata Server (eth0, IP: 172.17.0.5)

    beegfs-node1: Storage Server (eth0, IP: 172.17.0.2)
    beegfs-node2: Storage Server (eth0, IP: 172.17.0.5)
    beegfs-node3: Storage Server (eth0, IP: 172.17.0.9)
    beegfs-node4: Storage Server (eth0, IP: 172.17.0.14)

    beegfs-node1: Client (eth0, IP: 172.17.0.2)

    beegfs-node1: Mon Server (eth0, IP: 172.17.0.2)(可选项)

Storage:

    Storage servers with xfs, mounted to "/beegfs/storage"

    Metadata servers with ext4, mounted to "/beegfs/meta" # ext4 对小文件支持更好
```

所有节点配置 `/etc/hosts`

```plain
echo """172.17.0.2 beegfs-node1
172.17.0.5 beegfs-node2
172.17.0.9 beegfs-node3
172.17.0.14 beegfs-node4
""" >> /etc/hosts 
```

### 目录规划

目录规划如下：

```
/beegfs/mgmtd
/beegfs/meta
/beegfs/storge/target-x
```

元数据 ID 建议从 1 开始递增

每个节点至少两个存储目标，用于做备份。存储节点 ID 建议从 11 开始递增，使用 2 位或者更多位固定长度数字开头，避免与 Meta 节点 ID 重复；存储目标 ID 建议以节点 ID 为前缀，附加 1 位或者多位固定长度数字结尾（例如某台机器节点 ID 为 11，存储目标包含两个，分别为 111、112，这里节点 ID 固定 2 位、存储目标 ID 后缀固定为 1 位）

这里以第一个 Storage节点为例，选择编号 `11` 作为此存储服务的 ID，并使用 `1101` 作为存储目标 ID，以表明这是存储服务 `11` 的第一个目标( `01`)。

### 操作系统规划

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

内核锁定在

```bash
# 内核文件需要自己存
dnf install -y \
    --disablerepo=\* --enablerepo=local-kernel \
    kernel-5.14.0-162.23.1.el9_1 \
    kernel-core-5.14.0-162.23.1.el9_1 \
    kernel-debug-devel-5.14.0-162.23.1.el9_1 \
    kernel-devel-5.14.0-162.23.1.el9_1 \
    kernel-doc-5.14.0-162.23.1.el9_1 \
    kernel-headers-5.14.0-162.23.1.el9_1 \
    kernel-modules-5.14.0-162.23.1.el9_1 \
    kernel-tools-5.14.0-162.23.1.el9_1 \
    kernel-tools-libs-5.14.0-162.23.1.el9_1

# 重启后锁版本，如果不安装客户端可不进行此步骤
dnf versionlock 'kernel' 'kernel-devel'

[root@beegfs-node1 ~]# uname -a
Linux beegfs-node1 5.14.0-162.23.1.el9_1.x86_64 #1 SMP PREEMPT_DYNAMIC Tue Apr 11 19:09:37 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

所有节点关闭防火墙和 SELINUX

```bash
systemctl stop firewalld
systemctl disable firewalld

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
```

设置内核参数

```bash
grubby --update-kernel=ALL --args=net.ifnames=0
grubby --update-kernel=ALL --args=biosdevname=0

grubby --update-kernel=ALL --args=selinux=0

grubby --update-kernel=ALL --args=ipv6.disable=1

# 客户端所在机器需要更换内核
grubby --set-default=/boot/vmlinuz-5.14.0-162.23.1.el9_1.x86_64
```

## 节点安装

### 安装管理节点

Management 节点配置 Management Service，管理服务需要知道它可以在哪里存储数据。它只存储一些
节点信息，比如连接性数据，因此不需要太多的存储空间，而且它的数据访问不是性能关键。因此，此服务
通常可以不在专用机器上运行。

安装管理服务应用

```bash
dnf install -y --enablerepo=beegfs beegfs-mgmtd
```

在对应目录创建管理服务

```bash
mkdir -p /beegfs/mgmtd

/opt/beegfs/sbin/beegfs-setup-mgmtd -p /beegfs/mgmtd
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/beegfs-mgmtd-conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-mgmtd.conf '' connDisableAuthentication "true"
# 禁止自动初始化
crudini --set /etc/beegfs/beegfs-mgmtd.conf '' storeAllowFirstRunInit "false"
# 指定网卡
crudini --set /etc/beegfs/beegfs-mgmtd.conf '' connInterfacesFile "/etc/beegfs/beegfs-mgmtd-conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-mgmtd.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-mgmtd.conf '' storeAllowFirstRunInit
crudini --get /etc/beegfs/beegfs-mgmtd.conf '' connInterfacesFile
```

增加 `service.d` 文件：

```bash
# /etc/systemd/system/beegfs-mgmtd.service.d/override.conf
[Service]
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0
OOMScoreAdjust=-900

```

启动服务

```bash
systemctl daemon-reload
systemctl enable --now beegfs-mgmtd
systemctl status beegfs-mgmtd
```

### 安装元数据节点

Meta 节点配置 Metadata Service，元数据服务需要知道它可以在哪里存储数据，以及管理服务在哪里运行。

安装元数据服务组件

```bash
dnf install -y --enablerepo=beegfs beegfs-meta
```

以下格式化卷成 ext4 文件系统，并挂载到 `/beegfs/meta` 路径

查看卷的名字，假设为 `/dev/vdb1`

```bash
> lsblk

NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sr0     11:0    1 203.6M  0 rom
vda    253:0    0    50G  0 disk
└─vda1 253:1    0    50G  0 part /
vdb    253:16   0   100G  0 disk
├─vdb1 253:17   0    20G  0 part
├─vdb2 253:18   0    30G  0 part
└─vdb3 253:19   0    30G  0 part
```

格式化成 ext4 文件系统

```bash
mkfs -t ext4 -i 2048 -I 512 -J size=400 -Odir_index,filetype /dev/vdb1
```

创建挂载点

```bash
mkdir -p /beegfs/meta
```

检查卷的 UUID，假设为 `d5386a2f-44a3-47a3-b836-15aca91589f9`

```bash
> lsblk -o +UUID

NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS UUID
sr0     11:0    1 203.6M  0 rom              2023-06-30-16-33-45-00
vda    253:0    0    50G  0 disk
└─vda1 253:1    0    50G  0 part /           ca1a6b30-667f-4840-8861-7166f0af455f
vdb    253:16   0   100G  0 disk
├─vdb1 253:17   0    20G  0 part             d5386a2f-44a3-47a3-b836-15aca91589f9
├─vdb2 253:18   0    30G  0 part
└─vdb3 253:19   0    30G  0 part
```

修改自动加载配置文件，添加：

```bash
echo "UUID=d5386a2f-44a3-47a3-b836-15aca91589f9 /beegfs/meta ext4 sync,noatime,nodiratime 0 0" >> /etc/fstab
```

将格式化后的新卷挂载到 `/data/lun_meta`

```bash
mount -a
```

在对应目录创建元数据管理服务，并指定元数据服务 sid 为 201 或者 202，管理节点名称为 node1, 如下：

- 对 `beegfs-node1`

```bash
/opt/beegfs/sbin/beegfs-setup-meta -p /beegfs/meta -s 1 -m beegfs-node1
```

- 对 `beegfs-node2`

```bash
/opt/beegfs/sbin/beegfs-setup-meta -p /beegfs/meta -s 2 -m beegfs-node1
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/beegfs-meta-conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-meta.conf '' connDisableAuthentication "true"
# 禁止自动初始化
crudini --set /etc/beegfs/beegfs-meta.conf '' storeAllowFirstRunInit "false"
# 指定网卡
crudini --set /etc/beegfs/beegfs-meta.conf '' connInterfacesFile "/etc/beegfs/beegfs-meta-conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-meta.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-meta.conf '' storeAllowFirstRunInit
crudini --get /etc/beegfs/beegfs-meta.conf '' connInterfacesFile
```

增加 `service.d` 文件：

```bash
# /etc/systemd/system/beegfs-meta.service.d/override.conf
[Service]
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0
OOMScoreAdjust=-900

```

启动服务

```bash
systemctl daemon-reload
systemctl enable --now beegfs-meta
systemctl status beegfs-meta
```

### 配置元数据节点 buddy mirror

安装客户端命令行工具

```bash
dnf install -y --enablerepo=beegfs \
  beegfs-client beegfs-helperd beegfs-utils
```

指定管理节点 node1

```bash
/opt/beegfs/sbin/beegfs-setup-client -m beegfs-node1
```

自动创建元数据 Group

```bash
> beegfs-ctl --addmirrorgroup --automatic --nodetype=meta

New mirror groups:
BuddyGroupID   Node type Node
============   ========= ====
           1     primary        2 @ beegfs-meta beegfs-node2 [ID: 2]
               secondary        1 @ beegfs-meta beegfs-node1 [ID: 1]

Mirror buddy group successfully set: groupID 1 -> target IDs 2, 1
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

查询元数据服务状态

```bash
> beegfs-ctl --listmirrorgroups --nodetype=meta
     BuddyGroupID     PrimaryNodeID   SecondaryNodeID
     ============     =============   ===============
                1               201               202

```

### 安装存储节点

Storage 节点配置 Storage Service，存储服务需要知道它可以在哪里存储数据，以及如何到达管理服务器。

通常，每个存储服务将在不同的机器上运行多个存储服务和/或多个存储目标（例如多个 RAID 卷）。

安装存储管理服务

```bash
dnf install -y --enablerepo=beegfs beegfs-storage
```

到此需要格式化卷，其过程与配置自己加载请参考元数据服务的卷配置过程，假设挂载路径为

```bash
# beegfs-node1
/beegfs/storge/target-1101
/beegfs/storge/target-1102

# beegfs-node2
/beegfs/storge/target-1201
/beegfs/storge/target-1202

# beegfs-node3
/beegfs/storge/target-1301
/beegfs/storge/target-1302

# beegfs-node4
/beegfs/storge/target-1401
/beegfs/storge/target-1402

```

这里以 `beegfs-node1` 格式化成 xfs 文件系统为例

```bash
mkfs -t xfs -l version=2,su=256k /dev/vdb2
mkfs -t xfs -l version=2,su=256k /dev/vdb3
```

创建挂载点

```bash
mkdir -p /beegfs/storge/target-1101
mkdir -p /beegfs/storge/target-1102
```

检查卷的 UUID

```bash
> lsblk -o +UUID 

NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS  UUID
sr0     11:0    1 203.6M  0 rom               2023-06-30-16-33-45-00
vda    253:0    0    50G  0 disk
└─vda1 253:1    0    50G  0 part /            ca1a6b30-667f-4840-8861-7166f0af455f
vdb    253:16   0   100G  0 disk
├─vdb1 253:17   0    20G  0 part /beegfs/meta d5386a2f-44a3-47a3-b836-15aca91589f9
├─vdb2 253:18   0    30G  0 part              f43eec11-4735-4beb-a681-5eb7118b2815
└─vdb3 253:19   0    30G  0 part              4e3fa14a-9e04-4397-b1d9-65f0777ef75d
```

编辑 fstab 文件，配置 Mount 点信息，添加：`UUID="abcd-efgh-1234-5678" /data/lun_meta xfs defaults,nofail 0 2`

```bash
echo 'UUID="f43eec11-4735-4beb-a681-5eb7118b2815" /beegfs/storge/target-1101 xfs sync,noatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64,swalloc,allocsize=131072k 0 0' >> /etc/fstab

echo 'UUID="4e3fa14a-9e04-4397-b1d9-65f0777ef75d" /beegfs/storge/target-1102 xfs sync,noatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64,swalloc,allocsize=131072k 0 0' >> /etc/fstab
```

将格式化后的新卷挂载到 `/data/lun_meta`

```bash
mount -a
```

加入本地存储卷到 BeeGFS 存储中

- 对 `beegfs-node1`

```bash
/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storge/target-1101 \
    -s 11 -i 1101 -m beegfs-node1

/opt/beegfs/sbin/beegfs-setup-storage -p /beegfs/storge/target-1102 \
    -s 11 -i 1102 -m beegfs-node1
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/beegfs-storage-conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-storage.conf '' connDisableAuthentication "true"
# 禁止自动初始化
crudini --set /etc/beegfs/beegfs-storage.conf '' storeAllowFirstRunInit "false"
# 指定网卡
crudini --set /etc/beegfs/beegfs-storage.conf '' connInterfacesFile "/etc/beegfs/beegfs-storage-conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-storage.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-storage.conf '' storeAllowFirstRunInit
crudini --get /etc/beegfs/beegfs-storage.conf '' connInterfacesFile
```

增加 `service.d` 文件：

```bash
# /etc/systemd/system/beegfs-storage.service.d/override.conf
[Service]
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0
OOMScoreAdjust=-900

```

启动服务

```bash
systemctl daemon-reload
systemctl enable --now beegfs-storage
systemctl status beegfs-storage
```

### 配置存储节点 buddy mirror

自动创建存储 Group

```bash
> beegfs-ctl --addmirrorgroup --automatic --nodetype=storage

New mirror groups:
BuddyGroupID Target type Target
============ =========== ======
           1     primary     1101 @ beegfs-storage beegfs-node1 [ID: 11]
               secondary     1201 @ beegfs-storage beegfs-node2 [ID: 12]
           2     primary     1301 @ beegfs-storage beegfs-node3 [ID: 13]
               secondary     1401 @ beegfs-storage beegfs-node4 [ID: 14]
           3     primary     1202 @ beegfs-storage beegfs-node2 [ID: 12]
               secondary     1102 @ beegfs-storage beegfs-node1 [ID: 11]
           4     primary     1402 @ beegfs-storage beegfs-node4 [ID: 14]
               secondary     1302 @ beegfs-storage beegfs-node3 [ID: 13]

Mirror buddy group successfully set: groupID 1 -> target IDs 1101, 1201
Mirror buddy group successfully set: groupID 2 -> target IDs 1301, 1401
Mirror buddy group successfully set: groupID 3 -> target IDs 1202, 1102
Mirror buddy group successfully set: groupID 4 -> target IDs 1402, 1302
```

> 如果想要设置自定义组 id，或者想要确保 Buddy Group 位于不同的故障域中 (例如，不同的机架)，那么手动定义镜像 Buddy Group 是非常有用的。使用 beegfs-ctl 工具手动定义镜像 Buddy Group。通过使用下面的命令，您可以创建一个 ID 为 100 的 Buddy Group，由目标 1 和目标 2 组成
>
> ```bash
> # 手动指定 Buddy Group
> beegfs-ctl --addmirrorgroup --nodetype=storage --primary=1101 --secondary=1201 --groupid=1
> ```

查询存储服务状态

```bash
> beegfs-ctl --listmirrorgroups --nodetype=storage
     BuddyGroupID   PrimaryTargetID SecondaryTargetID
     ============   =============== =================
                1              1101              1201
                2              1301              1401
                3              1202              1102
                4              1402              1302

> beegfs-ctl --listtargets --mirrorgroups
MirrorGroupID MGMemberType TargetID   NodeID
============= ============ ========   ======
            1      primary     1101       11
            1    secondary     1201       12
            2      primary     1301       13
            2    secondary     1401       14
            3      primary     1202       12
            3    secondary     1102       11
            4      primary     1402       14
            4    secondary     1302       13

```

### 安装客户端节点

安装客户端命令行工具

```bash
dnf install -y --enablerepo=beegfs \
  beegfs-client beegfs-helperd beegfs-utils
```

指定管理节点 node1

```bash
/opt/beegfs/sbin/beegfs-setup-client -m beegfs-node1
```

修改 `/etc/beegfs/beegfs-mounts.conf`，第一项是挂载目录，第二项是配置文件路径，如下:

```bash
/mnt/beegfs /etc/beegfs/beegfs-client.conf
```

增加网卡配置文件

```bash
echo "eth0" > /etc/beegfs/beegfs-client-conn-inf.conf
```

修改配置文件

```bash
# 关闭认证
crudini --set /etc/beegfs/beegfs-helperd.conf '' connDisableAuthentication "true"
crudini --set /etc/beegfs/beegfs-client.conf '' connDisableAuthentication "true"
# 指定网卡
crudini --set /etc/beegfs/beegfs-client.conf '' connInterfacesFile "/etc/beegfs/beegfs-client-conn-inf.conf"

# 查看配置
crudini --get /etc/beegfs/beegfs-helperd.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-client.conf '' connDisableAuthentication
crudini --get /etc/beegfs/beegfs-client.conf '' connInterfacesFile
```

启动 heplerd 服务，提供日志与 DNS 解析等服务

```bash
systemctl enable --now beegfs-helperd
systemctl status beegfs-helperd
```

启动客户端服务

```bash
systemctl enable --now beegfs-client
systemctl status beegfs-client
```

系统中定义了存储 Buddy 镜像组之后，必须定义一个使用它的数据条带模式。

首先获取目录属性

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

## 重启后确认节点状态

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

执行完以上配置后，重启所有节点，并确认重启后所有节点上的服务均已经正常启动，到这里 BeeGFS 的基本配置就完成了。

查看节点列表

```bash
beegfs-ctl --listnodes --nodetype=management --nicdetails

# 元数据节点列表
beegfs-ctl --listnodes --nodetype=meta --nicdetails

# 存储节点列表
beegfs-ctl --listnodes --nodetype=storage --nicdetails

# 客户端节点列表
beegfs-ctl --listnodes --nodetype=client --nicdetails
```

查看存储池

```bash
beegfs-ctl --liststoragepools
```

查看存储目标

```bash
# 存储目标列表
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

