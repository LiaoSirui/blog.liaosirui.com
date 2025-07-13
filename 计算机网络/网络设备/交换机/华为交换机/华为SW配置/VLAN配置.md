## 基础概念

对于一个企业网络，通常需要根据部门划分不同的 VLAN，用于隔离广播域和网络隔离

- 首先配置交换机全局的 VLAN，根据端口所连接的终端，给端口分配不同的 VLAN，端口类型配置成 access 模式；
- 交换机和交换机之间的互联端口配置成 trunk 模式，并且允许所有的 VLAN 通过，实现局域网内部的互联

### 端口

以太网端口的三种链路类型：Access、Hybrid 和 Trunk：

- Access 类型的端口只能属于 1 个 VLAN，一般用于连接计算机的端口；
- Trunk 类型的端口可以允许多个 VLAN 通过，可以接收和发送多个 VLAN 的报文，一般用于交换机之间连接的端口；
- Hybrid 类型的端口可以允许多个 VLAN 通过，可以接收和发送多个 VLAN 的报文，可以用于交换机之间连接，也可以用于连接用户的计算机。

### VLANIF 接口

VLANIF 接口是交换机上的一个逻辑三层接口，用于实现不同 VLAN 之间的路由和通信

简单来说，每个 VLAN 可以对应一个 VLANIF 接口，并且配置 IP 地址后，这个接口就成为了该 VLAN 的网关，负责处理跨 VLAN 的报文转发。﻿

## VLAN 配置

创建 VLAN 23，并进入 vlan23 配置视图，如果 vlan23 存在就直接进入 vlan23 配置视图

```
<HW-SW-01>sys
[HW-SW-01]vlan 23
```

将端口加入到 VLAN 中

```bash
[HW-SW-01]display interface brief
[HW-SW-01]interface GigabitEthernet0/0/1
[HW-SW-01-GigabitEthernet0/0/1]undo shutdown
[HW-SW-01-GigabitEthernet0/0/1]port link-type access
[HW-SW-01-GigabitEthernet0/0/1]port default vlan 10
# 配置连接终端设备的交换机接口为边缘端口
[HW-SW-01-GigabitEthernet0/0/1]stp edged-port enable
[HW-SW-01-GigabitEthernet0/0/1]quit
```

将多个端口加入到 VLAN 中

```bash
[HW-SW-01]vlan 23
[HW-SW-01-vlan10]port GigabitEthernet 0/0/3 to 0/0/4
```

交换机配置 IP 地址，定义 vlan10 管理 IP 三层交换网关路由

```bash
[HW-SW-01]interface Vlanif23
[HW-SW-01-Vlanif10]ip address 172.31.23.254 255.255.255.0
[HW-SW-01-Vlanif10]quit
```

配置默认静态路由

```bash
[HW-SW-01]ip route-static 0.0.0.0 0.0.0.0 192.168.1.1
```

交换机保存设置

```bash
<HW-SW-01>save
```

交换机常用的显示命令

```bash
# 显示现在交换机正在运行的配置明细
[HW-SW-01]display current-configuration

# 显示各设备状态
[HW-SW-01]display device

# 显示端口状态，用 ? 可以查看后边跟的选项
[HW-SW-01]display interface ?

# 查看交换机固件版本信息
[HW-SW-01]display version

# 查看 VALN 的配置信息
[HW-SW-01]display vlan ?
```

