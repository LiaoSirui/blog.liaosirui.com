## NFS 和 iSCSI 对比

### 主要区别

网络文件系统（NFS）和 Internet 小型计算机系统接口（iSCSI）都是数据共享协议。通过网络有效共享数据对任何组织的日常运营都至关重要。NFS 可以在文件级别实现远程数据共享。用户（或客户端设备）可以使用 NFS 连接到网络服务器并访问服务器上的文件。多台客户端设备（用户）可以共享相同的文件，而不会发生数据冲突。类似地，iSCSI 也允许远程数据共享，不过要在数据块级别上执行。它支持多台客户端设备和一台数据块存储设备（或数据库服务器）之间的数据交换，并经由本地磁盘驱动器以类似的方式进行访问

### 工作原理：NFS 与 iSCSI

网络文件系统（NFS）和 Internet 小型计算机系统接口（iSCSI）均用于在网络或虚拟网络之间的客户端-服务器关系中共享数据。这些一直是远程企业通信中的常用协议。

#### NFS 的工作原理

NFS 协议在 20 世纪 80 年代设计为 Unix 系统的客户端-服务器文件共享协议。NFS 通过各种更新保持活跃，最近一次更新是 NFS 版本 4。NFS 是分布式文件系统的常用协议。

NFS 协议的工作原理如下：

1. 客户端请求访问远程 NFS 服务器上的资源
2. 服务器在客户端上远程挂载资源。
3. NFS 数据存储在客户端上显示并像本地资源一样运行
4. 读取资源存储在客户端的文件系统缓存中，以便快速访问

通过虚拟连接共享对资源（例如文件或目录）的访问权限。NFS 使用远程过程调用（RPC）作为底层通信技术。 

#### iSCSI 的工作原理

最初的小型计算机系统接口（SCSI）协议旨在通过局域网（LAN）共享数据。iSCSI 协议在 20 世纪 90 年代末开发，旨在允许 SCSI 协议在 TCP/IP 网络上运作。

iSCSI 是一种传输层协议，旨在提供对网络中存储设备的无缝访问。名称 *iSCSI* 用于表示原始协议已修改，并将 SCSI 命令封装在 TCP/IP 数据包中。 

iSCSI 采用客户端-服务器架构。客户端称为*启动器*，而服务器称为 *iSCSI 目标*。块存储设备称为*逻辑单元*，iSCSI 目标可能有许多逻辑单元。每个逻辑单元都有指定的逻辑单元号（LUN）。

iSCSI 协议的工作原理如下：

1. 启动器使用质询握手身份验证协议（CHAP）连接到目标。
2. 连接后，存储设备在客户端上显示为本地磁盘驱动器。

### 主要区别：NFS 与 iSCSI

虽然两者都是数据共享协议，但网络文件系统（NFS）和 Internet 小型计算机系统接口（iSCSI）的工作原理大不相同。接下来，我们将概述两者的一些独特功能。

#### 性能

由于 iSCSI 协议在块级别工作，因此通过直接操作远程磁盘，它通常可以提供比 NFS 更高的性能。

NFS 添加一层文件系统抽象，可以逐个文件进行操作。

#### 冲突解决

当多个客户端尝试访问或写入同一个文件时，需要使用冲突解决技术或文件锁定技术。

NFS 内置分布式文件系统的冲突解决方案

iSCSI 没有内置的冲突解决方案。在这种情况下，必须将另一个软件分层到顶部，以防止操作不稳定。

#### 配置简易性

虽然 NFS 是为 Unix 构建的，通常可在 Linux 发行版中直接使用，但也可以通过安装软件包在其他操作系统上使用 NFS。对于 Linux 客户端和服务器，设置和配置相对快速且简单。

iSCSI 可在多种不同的操作系统上使用。iSCSI 可能内置在某些存储设备上，但始终需要在客户端计算机上安装 iSCSI 启动器软件

### 差异摘要：NFS 与 iSCSI

| 数据共享协议 | **NFS**                         | **iSCSI**                                                    |
| ------------ | ------------------------------- | ------------------------------------------------------------ |
| 它是什么？   | 网络文件系统。                  | Internet 小型计算机系统接口。                                |
| 操作层级     | 应用层协议。                    | 传输层协议。                                                 |
| 最适合       | 基于 Linux 的网络架构。         | 私有存储区域网络架构。                                       |
| 共享资源     | 文件和目录。                    | I/O 设备，通常是存储设备。                                   |
| 访问级别     | 基于文件。                      | 基于块。                                                     |
| 文件锁定     | 内置并由客户端处理。            | 非内置，必须由其他系统处理。                                 |
| 运行基础     | TCP 或 UDP 上的 RPC。           | TCP/IP 上的 SCSI。                                           |
| 配置简易性   | 在 Linux 环境中相对快速且简单。 | 可能需要更长的时间，因为所有客户端都需要安装 iSCSI 启动器软件。 |

## 挂载 iSCSI

### Linux 挂载 iSCSI

安装 iSCSI 的客户端

```bash
dnf install iscsi-initiator-utils -y

# apt-get install open-iscsi
```

定义客户端连机器的名称，一般来说不需要修改

```bash
cat /etc/iscsi/initiatorname.iscsi
```

（可选）启用 chap 认证

```bash
vim /etc/iscsi/iscsid.conf

# 启用 chap 认证
node.session.auth.authmethod = CHAP
# 认证用户名
node.session.auth.username = username
# 如果需要让 windows 访问 password 需要 12 位以上
node.session.auth.password = password
```

启动 iscsid 服务

```bash
systemctl enable --now iscsid
```

发现存储服务器资源

```bash
# -t 显示输出结果 -p:iscsi 服务器地址
iscsiadm -m discovery \
  --type sendtargets \
  --portal 192.168.100.20

192.168.100.20:3260,1 iqn.2021-11.pip.cc:server
```

登录存储服务器

```bash
# -T:服务器发现的名称 -p：服务器地址 
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -p 192.168.100.20 \
  --login
```

设置开机自动注册

``` bash
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -p 192.168.100.20 \
  --op update \
  -n node.startup -v automatic
```

注意，fstab 文件中必须指定 `_netdev`，不然重启可能无法正常开机，例如

```bash
/dev/sdb /data ext4 defaults,_netdev 0 0

# 用于 systemd
# systemctl list-units --type=mount
```

卸载卷的方式如下

```bash
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -p 192.168.100.20 \
  -u
```

验证是否还存在 iSCSI Session

```bash
iscsiadm -m session -P 3 | grep Attached
```

删除发现 iSCSI 信息

```bash
iscsiadm -m node \
  -T iqn.2021-11.pip.cc:server \
  -o delete
```

`ll /var/lib/iscsi/nodes/` 查看为空，即在客户端删除了 iSCSI Target

查看挂载

```bash
iscsiadm -m node
```

