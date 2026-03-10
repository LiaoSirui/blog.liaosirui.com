## 初始化

初始默认密码：admin / admin

初始化

```bash
# 进入系统视图
system-view

# 命名路由器
sysname Router_H3C
```



开启 web 登录

```bash
# 进入系统视图
system-view
# 开启 HTTP 服务
ip http enable
# 开启 HTTPS 服务
ip https enable

# 进入用户视图
local-user admin
  # 允许用户使用 http 服务
  service-type http
  # 允许用户使用 https 服务
  service-type https

```

开启 ssh

```bash
system-view

# 生成本地密钥对
public-key local create rsa

# 开启 SSH 服务器功能
ssh server enable

# 配置用户登录认证
local-user admin
  service-type ssh
  authorization-attribute user-role network-admin
  authorization-attribute user-role network-operator
  quit

# 配置 VTY 界面允许 SSH 登录
line vty 0 15
  authentication-mode scheme
  protocol inbound ssh
  quit

# 查看服务
display ssh server status
```



查看基础信息

```bash
# 设备查看 IP 地址
display ip interface brief
```

配置 IP

```bash
system-view

interface gigabitethernet 0/0
  ip address 192.168.71.254 255.255.255.0
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

