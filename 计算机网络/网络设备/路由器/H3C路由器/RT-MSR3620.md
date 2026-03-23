## 固件升级

固件下载地址：<https://www.h3c.com/en/Support/Resource_Center/EN/Routers/Catalog/MSR3600/MSR3600/Software_Download/MSR_3620-DP/>

## 初始化

初始默认密码：admin / admin

初始化

```bash
# 命名路由器
sysname RouterH3C
```

开启 web 登录

```bash
# 开启 HTTP 服务
ip http enable

# 开启 HTTPS 服务
ip https enable
```

开启 ssh

```bash
# 生成本地密钥对 ecdsa
public-key local create ecdsa
public-key local create rsa  # 4096

# ssh-keygen -f ~/.ssh/known_hosts -R "192.168.71.201"
# update-crypto-policies --set LEGACY
# ssh -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa user@ip

# 开启 SSH 服务器功能
ssh server enable

# 查看服务
display ssh server status
```

开启 NETCONF over SSH

```bash
# 开启 neconf 服务（NETCONF over SHH）
netconf ssh server enable

# 设置 netconf 的服务端口为 830(缺省端口号为：830)
netconf ssh server port 830

# 设置超时时间为 5 分钟（缺省超时间为：0 永不超时，为了安全性，建议修改超时时间）
netconf agent idle-timeout 5
```

开启 RESTCONF

```bash
restful http enable
restful https enable

# 查看配置
display current-configuration | include restful

display ip http
display ip https
```

用户

```bash
# 进入用户视图
local-user admin class manage
	# 设置密码
	password simple H3c@123
	# 允许用户使用 http 服务
  service-type http
  # 允许用户使用 https 服务
  service-type https
  # 允许用户使用 ssh 服务
  service-type ssh

# 额外创建用户
local-user h3c class manage
  # 设置密码
	password simple H3c@123
  # 允许用户使用 http 服务
  service-type http
  # 允许用户使用 https 服务
  service-type https
  # 允许用户使用 ssh 服务
  service-type ssh
  authorization-attribute user-role network-admin

# 配置 SSH 用户 h3c 的服务，认证类型为 password
ssh user h3c service-type all authentication-type password

# 配置 VTY 界面允许 SSH 登录
line vty 0 15
  # 配置 user-interface vty 的认证模式为 scheme
  authentication-mode scheme
  protocol inbound ssh
  quit
```

查看基础信息

```bash
# 设备查看 IP 地址
display ip interface brief
```

配置 IP

```bash
interface gigabitethernet 0/0
  ip address 192.168.254.201 255.255.255.0
  quit

# 配置网关
# ip route-static 0.0.0.0 0.0.0.0 192.168.71.1

# NAT 转换
# acl basic 2000
#   rule permit source 192.168.71.0 0.0.0.255
#   quit
# interface gigabitethernet 0/0
#   nat outbound 2000

```

开启对时

```bash
clock timezone Beijing add 08:00:00
clock protocol ntp

ntp-service enable
ntp-service unicast-server ntp.aliyun.com
ntp-service unicast-server ntp.ntsc.ac.cn
ntp-service unicast-server ntp1.aliyun.com
ntp-service unicast-server ntp2.aliyun.com
ntp-service unicast-server ntp3.aliyun.com
ntp-service unicast-server ntp4.aliyun.com
ntp-service unicast-server ntp5.aliyun.com
```

## 二层接口

vlan

```bash
# 配置安全策略允许域内通信
security-policy ip
  rule name Trust_Intra_Allow
    source-zone Trust
    destination-zone Trust
    action pass
    quit
  quit
display security-policy ip rule name Trust_Intra_Allow

# 将物理接口的 VLAN 10 流量关联到安全域 Trust
security-zone name Trust
  import interface GigabitEthernet 0/1
  import interface Vlan-interface 23
  import interface GigabitEthernet 2/2 VLAN 23
  import interface GigabitEthernet 4/3 VLAN 23
  import interface GigabitEthernet 5/0 VLAN 23
  import interface GigabitEthernet 6/4 VLAN 23
  import interface Vlan-interface 24
  import interface GigabitEthernet 2/0 VLAN 24
  import interface GigabitEthernet 2/1 VLAN 24
  import interface GigabitEthernet 4/0 VLAN 24
  import interface GigabitEthernet 4/1 VLAN 24
  import interface GigabitEthernet 5/4 VLAN 24
  import interface GigabitEthernet 5/5 VLAN 24
  import interface GigabitEthernet 6/0 VLAN 24
  import interface GigabitEthernet 6/1 VLAN 24
  import interface Bridge-Aggregation 1 VLAN 24
  import interface Bridge-Aggregation 2 VLAN 24
  import interface Bridge-Aggregation 3 VLAN 24
  import interface Bridge-Aggregation 4 VLAN 24
  import interface Vlan-interface 25
  import interface GigabitEthernet 4/3 VLAN 25
  quit
display security-zone
```

Bond

```bash
interface Bridge-Aggregation 1
    port access vlan 10
    link-aggregation mode dynamic
# 创建聚合口，划入vlan
int g 6/0
    port link-aggregation group 1
    link-aggregation port-priority 100
# 聚合的两个物理口都加入集合组
int g 6/1
    port link-aggregation g 1
    link-aggregation port-priority 100
```

## 开启 BGP

```bash
# 启用 BGP
bgp 65534
  # 配置邻居 IPv4 地址及 AS 号
  peer 10.1.1.2 as-number 65534
  # Graceful Restart，平滑重启
  graceful-restart
  # 进入 IPv4 单播地址族并激活邻居
  address-family ipv4 unicast
    peer 10.1.1.2 enable
```

## NETCONF

- 连接参数

```python
# NETCONF 连接参数
main_router = {
    "host": "192.168.1.1",
    "username": "h3c",
    "password": "netconf@123",
    "port": 830,
    "device_params": {"name": "h3c"},
    "hostkey_verify": False,
    "look_for_keys": False,
}
```

- 保存配置

```python
"""Save configuration."""

from ncclient import manager

from h3c_router.device import main_router
from h3c_router.log import logging

with manager.connect(**main_router) as netconf_connect:
    logging.info(f"H3C 设备 IP {(main_router.get('host', ''))}")
    if netconf_connect.save("startup.cfg").ok:
        logging.info("H3C 设备保存成功")
    else:
        logging.info("H3C 设备保存失败")

```

