## 固件升级

固件下载地址：<https://www.h3c.com/en/Support/Resource_Center/EN/Routers/Catalog/MSR3600/MSR3600/Software_Download/MSR_3620-DP/>

## 初始化

初始默认密码：admin / admin

初始化

```bash
# 命名路由器
sysname Router_H3C
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

# 额外创建用户
local-user h3c class manage
  # 设置密码
	password simple 'H3c@123'
  # 允许用户使用 http 服务
  service-type http
  # 允许用户使用 https 服务
  service-type https
  # 允许用户使用 ssh 服务
  service-type ssh
  authorization-attribute user-role network-admin

# 配置 SSH 用户 h3c 的服务为 netconf，认证类型为 password
ssh user h3c service-type all authentication-type password
ssh user h3c service-type netconf authentication-type password

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
  ip address 192.168.71.201 255.255.255.0
  quit

# 配置网关
ip route-static 0.0.0.0 0.0.0.0 192.168.71.1

# NAT 转换
acl basic 2000
  rule permit source 192.168.71.0 0.0.0.255
  quit
interface gigabitethernet 0/0
  nat outbound 2000

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

