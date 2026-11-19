图形工具

- nm-connection-editor

字符工具

-  nmtui

- nmtui-connect

- nmtui-edit

- nmtui-hostname

## nmcli

`nmcli` 命令是 `NetworkManager client` 网络管理客户端

使用 `nmcli` 命令做的那些更改都将永久保存在文件  `/etc/sysconfig/network-scripts/ifcfg-enp0s3` 

### connection

```bash
nmcli con show 					     # 查看网卡列表和网卡 uuid
nmcli con show eth0          # 显示指定一个网络连接配置
nmcli con show -active       # 显示活动的连接
nmcli con add			           # 添加一个网卡配置文件
nmcli con mod                # 修改网卡配置
nmcli con delete			       # 删除一个网卡配置文件
nmcli con down <interface>   # 关闭指定接口
nmcli con up <interface>     # 打开指定接口
nmcli con reload             # 重新加载网卡配置文件
nmcli con 				           # 检查设备的连接情况
```

常见的参数：

| 参数                 | 解释                                           | 简写 |
| -------------------- | ---------------------------------------------- | ---- |
| `con-name`           | 连接名                                         |      |
| `ifname`             | 网络接口名                                     |      |
| `type`               | 一般就是 ethernet                              |      |
| `ipv4.address`       | IP 地址 / 掩码 形式                            | ip4  |
| `ipv4.gateway`       | 网关                                           | gw4  |
| `ipv4.dns`           | DNS 服务器                                     |      |
| `autoconnect yes`    | 对应配置文件中的 `ONBOOT=yes`，默认为 yes      |      |
| `autoconnect no`     | 对应配置文件中的 `ONBOOT=no`                   |      |
| `ipv4.method auto`   | 对应配置文件中的 `BOOTPROTO=dhcp`，默认为 auto |      |
| `ipv4.method manual` | 对应配置文件中的 `BOOTPROTO=none`，表示静态IP  |      |

### device

```
nmcli dev status             # 显示设备状态
nmcli dev show eno16777736   # 显示指定接口属性
nmcli dev show               # 显示全部接口属性
nmcli con up static          # 启用名为 static连 接配置
nmcli con up default         # 启用 default 连接配置 
nmcli c reload               # 重新读取配置
nmcli con add help           # 查看帮助
```

### 配置静态路由

给 eth0 网卡添加一个到达 192.168.2.0/24 网络，下一跳为 192.168.1.254 的路由

```bash
nmcli connection modify eth0 +ipv4.routes "192.168.2.0/24 192.168.1.254"
```

如果需要添加多个路由，可以用逗号分隔的方式添加：

```bash
nmcli connection modify eth0 +ipv4.routes "192.168.2.0/24 192.168.1.254,192.168.3.0/24 192.168.1.254"
```

删除静态路由

```bash
nmcli connection modify eth0 -ipv4.routes "192.168.2.0/24 192.168.1.254"
```

### 常见故障处理

关闭 dns 自动配置

```bash
nmcli connection modify eth0 ipv4.ignore-auto-dns yes

nmcli device modify eth0 ipv4.ignore-auto-dns yes
```

桥接配置
```bash
# 添加网桥和网卡
mcli connection add type bridge con-name br1 ifname br1
nmcli connection modify br1 \
  ipv4.addresses 192.168.220.222/24 \
  ipv4.gateway 192.168.220.2 \
  ipv4.method manual
nmcli connection add type bridge-slave con-name br1-port1 ifname eth0 master br1
nmcli connection up br1-port1

# 删除网桥和网卡
brctl delif <bridge> <device>
brctl delbr <bridge>
```

### 不作为路由网卡

```bash
nmcli connection modify "Vlan ens6f0np0.103" ipv4.never-default yes
```

## NetworkManager-wait-online.service

 让 NM 不管理 CNI 虚拟网卡

```bash
cat > /etc/NetworkManager/conf.d/99-k8s-unmanaged.conf <<'EOF'
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico;interface-name:vxlan-v6.calico;interface-name:wireguard.cali;interface-name:wg-v6.cali;interface-name:flannel*;interface-name:cni*;interface-name:veth*;interface-name:kube-ipvs0;interface-name:nodelocaldns;interface-name:cilium_*;interface-name:lxc*;interface-name:docker0;interface-name:kube-bridge
EOF

systemctl reload NetworkManager
```

处理没用的物理网卡和连接

```bash
# 没插线或不用的网口，关闭自动连接
nmcli connection modify <连接名> connection.autoconnect no

# 或者直接删除多余的连接配置
nmcli connection delete <连接名>
```

bond 或交换机协商慢时，加大超时

```bash
systemctl edit NetworkManager-wait-online.service
```

加入以下配置

```ini
[Service]
Environment=NM_ONLINE_TIMEOUT=300
```

也可以针对某个连接设置等待设备出现的时间：

```bash
nmcli connection modify <conn> connection.wait-device-timeout 30000
# 单位毫秒
```
