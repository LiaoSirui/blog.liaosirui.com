## Pacemaker 简介

Pacemaker 是集群的软件部分，负责管理其资源（VIP、服务、数据）。它负责启动、停止和监控集群资源。它保证节点的高可用性。

Pacemaker 使用 corosync（默认）或 Heartbeat 提供的消息层。

Pacemaker 由 5 个关键组件组成

- 集群信息库 (CIB)
- 集群资源管理守护进程 (CRMd)
- 本地资源管理守护进程 (LRMd)
- 策略引擎 (PEngine 或 PE)
- 围栏守护进程 (STONITHd)

CIB 表示集群配置和所有集群资源的当前状态。其内容会在整个集群中自动同步，并由 PEngine 使用，以计算如何达到理想的集群状态。然后，指令列表会提供给指定控制器 (DC)。Pacemaker 通过选举一个 CRMd 实例为主节点来集中所有集群决策。

DC 按所需顺序执行 PEngine 的指令，通过 Corosync 或 Heartbeat 将其传输给本地 LRMd 或其他节点的 CRMd。

有时，为了保护共享数据或启用恢复，可能需要停止节点。Pacemaker 附带 STONITHd 以实现此目的。

## Stonith

Stonith 是 Pacemaker 的一个组件。它代表 “Shoot-The-Other-Node-In-The-Head”（向另一节点开枪），这是一项建议的实践，旨在尽可能快地确保故障节点的隔离（关闭或至少断开与共享资源的连接），从而避免数据损坏。

一个无响应的节点并不意味着它无法再访问数据。在将数据交给另一个节点之前，确保节点不再访问数据的唯一方法是使用 STONITH，它将关闭或重启故障服务器。

如果集群服务无法关闭，STONITH 也起着作用。在这种情况下，Pacemaker 使用 STONITH 来强制停止整个节点。

## 仲裁管理

仲裁代表验证决策所需的最小在线节点数，例如决定在其中一个节点发生错误时哪个备用节点应接管。默认情况下，Pacemaker 要求超过一半的节点在线。

当通信问题将集群分成几个节点组时，仲裁可以防止资源在比预期更多的节点上启动。当在线节点总数的一半以上在组中时，集群就具有仲裁（active_nodes_group > active_total_nodes / 2）。

当未达到仲裁时，默认决定是关闭所有资源。

例如：

- 在双节点集群中，由于无法达到仲裁，必须忽略节点故障，否则整个集群将关闭。
- 如果一个 5 节点集群被分成 3 个节点和 2 个节点的两个组，3 节点组将具有仲裁并继续管理资源。
- 如果一个 6 节点集群被分成两个 3 节点组，则没有组将具有仲裁。在这种情况下，pacemaker 的默认行为是停止所有资源以避免数据损坏。

## 集群通信

Pacemaker 使用 Corosync 或 Heartbeat（来自 Linux-ha 项目）进行节点间通信和集群管理。

选择 pacemaker / corosync 似乎更合适，因为它是 RedHat、Debian 和 Ubuntu 发行版的默认选择。

### Corosync

Corosync Cluster Engine 是集群成员之间的消息传递层，它集成了其他功能以在应用程序内实现高可用性。Corosync 源自 OpenAIS 项目。

节点使用 UDP 协议以客户端 / 服务器模式进行通信。

它可以管理超过 16 个主动/被动或主动/主动模式的集群。

### Heartbeat

Heartbeat 技术比 Corosync 的功能有限。无法创建超过两个节点的集群，其管理规则也不如其竞争对手复杂。

## 数据管理

DRDB 是一种块类型设备驱动程序，可在网络上实现 RAID 1（镜像）。

当 NAS 或 SAN 技术不可用但需要数据同步时，DRDB 可能很有用。

## 安装

```bash
dnf config-manager --set-enabled ha
dnf install pacemaker pcs -y
```

pcs 包提供集群管理工具。pcs 命令是用于管理 Pacemaker 高可用性堆栈的命令行界面。

在所有节点上激活守护进程

```bash
systemctl enable pcsd --now
```

包安装创建了一个密码为空的 `hacluster` 用户。要执行诸如同步 corosync 配置文件或重启远程节点等任务。必须为该用户分配密码。

```bash
hacluster:x:189:189:cluster user:/home/hacluster:/sbin/nologin
```

在所有节点上，为 hacluster 用户分配相同的密码

```bash
echo "pwdhacluster" | sudo passwd --stdin hacluster
```

以从任何节点作为 hacluster 用户登录到所有节点，然后使用它们上的 `pcs` 命令

```bash
# pcs host auth 192.168.16.206 192.168.16.207
Username: hacluster
Password:
192.168.16.206: Authorized
192.168.16.207: Authorized
```

从进行 pcs 身份验证的节点，启动集群配置

```bash
pcs cluster setup hacluster 192.168.16.206 192.168.16.207
```

pcs cluster setup 命令处理双节点集群的仲裁问题。因此，这样的集群在其中一个节点发生故障时将正常工作。如果您手动配置 Corosync 或使用其他集群管理 shell，则必须正确配置 Corosync。

现在可以启动集群

```bash
pcs cluster start --all
```

启用集群服务以在启动时启动

```bash
pcs cluster enable --all
```

检查服务状态

```bash
# pcs status
Cluster name: hacluster

WARNINGS:
No stonith devices and stonith-enabled is not false

Cluster Summary:
  * Stack: corosync (Pacemaker is running)
  * Current DC: 192.168.16.207 (version 2.1.7-5.5.el8_10-0f7f88312) - partition with quorum
  * Last updated: Thu Jan 29 16:45:35 2026 on 192.168.16.206
  * Last change:  Thu Jan 29 16:42:28 2026 by hacluster via hacluster on 192.168.16.207
  * 2 nodes configured
  * 0 resource instances configured

Node List:
  * Online: [ 192.168.16.206 192.168.16.207 ]

Full List of Resources:
  * No resources

Daemon Status:
  corosync: active/enabled
  pacemaker: active/enabled
  pcsd: active/enabled
```

在配置资源之前，需要处理警告消息

```bash
WARNINGS:
No stonith devices and stonith-enabled is not false
```

选择

- 禁用 `stonith`，在生产环境中，切勿禁用 `stonith`！
- 配置它

```bash
# 禁用 stonith
pcs property set stonith-enabled=false
```

## 创建 VIP 资源

使用 `pcs resource standards` 命令列出可用的标准资源

```bash
pcs resource standards

# ocf
```

此 VIP 对应于客户的 IP 地址，以便他够访问未来的集群服务。必须将其分配给其中一个节点。然后，如果发生故障，集群会将此资源从一个节点切换到另一个节点，以确保服务连续性。

```bash
pcs resource create haclusterVIP ocf:heartbeat:IPaddr2 ip=192.168.16.209 cidr_netmask=24 op monitor interval=30s
```

查看状态

```bash
# pcs status

# ...
Full List of Resources:
  * haclusterVIP	(ocf::heartbeat:IPaddr2):	 Started 192.168.16.206
# ...
```

在这种情况下，VIP 在 `192.168.16.206` 上处于活动状态。可以使用 `ip` 命令进行验证

```bash
# ip a |grep 209
    inet 192.168.16.209/24 brd 192.168.16.255 scope global secondary enp7s0
```

从网络上的任何位置，运行 ping 命令到 VIP

```bash
ping 192.168.16.209
```

将活动节点置于待机状态

```bash
pcs node standby 192.168.16.206
```

