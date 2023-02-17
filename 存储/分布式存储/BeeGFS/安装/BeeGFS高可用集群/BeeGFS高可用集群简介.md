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

| **角色**    | **主机名** | **vCPU** | **内存** **（GB）** | **网络带宽** **（Gbps）** | **存储**           | **备注**           |
| ----------- | ---------- | -------- | ------------------- | ------------------------- | ------------------ | ------------------ |
| Management  | node1      | 2        | 4                   | Up 10                     | 8GB HDD            |                    |
| Metadata    | node201    | 4        | 8                   | Up 10                     | 1 x 100GB NVMe SSD |                    |
| Metadata    | node202    | 4        | 8                   | Up 10                     | 1 x 100GB NVMe SSD |                    |
| Storage-I   | node301    | 16       | 32                  | Up 10                     | 2 x 2TB HDD        | target：3011、3012 |
| Storage-II  | node302    | 16       | 32                  | Up 10                     | 2 x 2TB HDD        | target：3021、3022 |
| Storage-III | node303    | 16       | 32                  | Up 10                     | 2 x 2TB HDD        | target：3031、3032 |
| Client      | node4      | 2        | 4                   | Up 10                     | 8GB HDD            |                    |

### 节点安装

#### 安装 node1

安装管理服务应用

```bash
dnf install -y beegfs-mgmtd
```

在对应目录创建管理服务

```bash
/opt/beegfs/sbin/beegfs-setup-mgmtd -p /data/beegfs/beegfs_mgmtd 
```

启动服务

```bash
systemctl start beegfs-mgmtd
```

#### 安装 node201 / node202

安装元数据服务组件

```bash
dnf install -y beegfs-meta
```

以下格式化 NVMe 卷成 xfs 文件系统，并挂载到 /data/lun_meta 路径

查看NVMe卷的名字，假设为 `/dev/nvme0n1`

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

将格式化后的新卷挂载到 `/data/lun_meta`

```bash
mount /dev/nvme0n1 /data/lun_meta
```

设置重新启动，注意是 restart 后自动挂载

检查卷的 UUID，假设为 abcd-efgh-1234-5678

```bash
lsblk -o +UUID 
```

修改自动加载配置文件，添加：`UUID="abcd-efgh-1234-5678" /data/lun_meta xfs defaults,nofail 0 2`

```bash
echo 'UUID="abcd-efgh-1234-5678" /data/lun_meta xfs defaults,nofail 0 2' >> /etc/fstab
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

启动服务

```bash
systemctl start beegfs-meta
```

#### 安装 node301 / node302 / node303

```bash
# 安装存储管理服务
$ sudo apt install beegfs-storage      

# 到此需要格式化 NVMe 卷，其过程与配置自己加载请参考元数据服务的卷配置过程，假设挂载路径为/mnt/lun_storage_1、/mnt/lun_storage_2
$ sudo mkfs -t xfs /dev/nvme0n1 && sudo mkfs -t xfs /dev/nvme1n1

# 加入本地存储卷到 BeeGFS 存储中，如下，301 是存储节点代号，3011是目前存储节点代码，在 301 实例上如果增加另外的卷，可以选择 3012,3013 等 301{n} 形式进行存储扩容。
$ /opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_1 -s 301 -i 3011 -m node1
$ /opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_2 -s 301 -i 3012 -m node1
$ /opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_1 -s 302 -i 3021 -m node1
$ /opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_2 -s 302 -i 3022 -m node1
$ /opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_1 -s 303 -i 3031 -m node1
$ /opt/beegfs/sbin/beegfs-setup-storage -p /mnt/lun_storage_2 -s 303 -i 3032 -m node1

# 启动服务
$ systemctl start beegfs-storage 

# 停止服务
$ systemctl stop beegfs-storage 

# 本地EBS列表
$ /home/ubuntu# lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0         7:0    0   18M  1 loop /snap/amazon-ssm-agent/1480
loop1         7:1    0   89M  1 loop /snap/core/7713
loop2         7:2    0 93.8M  1 loop /snap/core/8935
loop3         7:3    0   18M  1 loop /snap/amazon-ssm-agent/1566
nvme0n1     259:0    0    2T  0 disk
nvme1n1     259:1    0    2T  0 disk
nvme2n1     259:2    0    8G  0 disk
└─nvme2n1p1 259:3    0    8G  0 part /
# 格式化
$ sudo mkfs -t xfs /dev/nvme0n1
$ sudo mkfs -t xfs /dev/nvme1n1

# 创建目录
$ mkdir /mnt/lun_storage_1
$ mkdir /mnt/lun_storage_2

# 挂载EBS卷
$ mount /dev/nvme0n1 /mnt/lun_storage_1
$ mount /dev/nvme1n1 /mnt/lun_storage_2

# 查询UUID
$ sudo lsblk -o +UUID
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT                  UUID
loop0         7:0    0   18M  1 loop /snap/amazon-ssm-agent/1480
loop1         7:1    0   89M  1 loop /snap/core/7713
loop2         7:2    0 93.8M  1 loop /snap/core/8935
loop3         7:3    0   18M  1 loop /snap/amazon-ssm-agent/1566
nvme0n1     259:0    0    2T  0 disk                             9f677321-d52d-4eb9-b00b-119c251aad26
nvme1n1     259:1    0    2T  0 disk                             9ea0044e-1774-416a-aff5-31afe054ddac
nvme2n1     259:2    0    8G  0 disk
└─nvme2n1p1 259:3    0    8G  0 part /                           651cda91-e465-4685-b697-67aa07181279

# 编辑 fatab文件，配置Mount点信息
$ sudo vim /etc/fstab
UUID=9f677321-d52d-4eb9-b00b-119c251aad26  /mnt/lun_storage_1  xfs  defaults,nofail  0  2
UUID=9ea0044e-1774-416a-aff5-31afe054ddac  /mnt/lun_storage_2  xfs  defaults,nofail  0  2
```

#### 安装 node4

安装客户端命令行工具

```bash
dnf install -y install beegfs-client beegfs-helperd beegfs-utils
```

指定管理节点 node1

```bash
/opt/beegfs/sbin/beegfs-setup-client -m node1
```

修改 `/etc/beegfs/beegfs-mounts.conf`，第一项是挂载目录，第二项是配置文件路径，如下:

```bash
/mnt/beegfs /etc/beegfs/beegfs-client.conf
```

启动 heplerd 服务，提供日志与 DNS 解析等服务

```bash
systemctl start beegfs-helperd
```

启动客户端服务

```bash
systemctl start beegfs-client
```

查看节点列表

```bash
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

### 配置 Meta Buddy / Storage Buddy

### 目标状态查询

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

### 故障恢复

BeeGFS 的 Buddy Group 支持自动的故障转移和恢复。如果存储目标或元数据服务发生故障，会将其标记为脱机，并且不会获取数据更新。通常，当目标或服务器重新注册时，它将自动与 Buddy Group 中的剩余镜像同步（自动修复）。但是，在某些情况下，也可以支持手动启动同步过程。

以下通过分别模拟存储服务和元数据服务的故障，演示在发生故障时如何进行服务恢复和数据同步操作。