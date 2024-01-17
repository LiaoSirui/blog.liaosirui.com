## frp 简介

官方：

- 代码仓库：<https://github.com/fatedier/frp>
- 文档：<https://gofrp.org/docs/>

### 内网穿透类型

| 类型   | 描述                                                         |
| :----- | :----------------------------------------------------------- |
| tcp    | 单纯的 TCP 端口映射，服务端会根据不同的端口路由到不同的内网服务 |
| udp    | 单纯的 UDP 端口映射，服务端会根据不同的端口路由到不同的内网服务 |
| http   | 针对 HTTP 应用定制了一些额外的功能，例如修改 Host Header，增加鉴权 |
| https  | 针对 HTTPS 应用定制了一些额外的功能                          |
| stcp   | 安全的 TCP 内网代理，需要在被访问者和访问者的机器上都部署 frpc，不需要在服务端暴露端口 |
| sudp   | 安全的 UDP 内网代理，需要在被访问者和访问者的机器上都部署 frpc，不需要在服务端暴露端口 |
| xtcp   | 点对点内网穿透代理，功能同 stcp，但是流量不需要经过服务器中转 |
| tcpmux | 支持服务端 TCP 端口的多路复用，通过同一个端口访问不同的内网服务 |

## 服务端安装

使用 systemd 管理服务 `/usr/lib/systemd/system/frps.service` ：

```ini
[Unit]
Description = Frp Server Service
After = network.target syslog.target
Wants = network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=/root/frp_0.48.0_linux_amd64/frps -c /root/frps.ini
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target

```

设置开机自启

```bash
systemctl enable --now frps
```

参考配置如下：

```ini
[common]
bind_addr     = 0.0.0.0
bind_port     = 7000
bind_udp_port = 7001
kcp_bind_port = 7000

dashboard_addr = 0.0.0.0
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd  = admin
dashboard_tls_mode = false

enable_prometheus = true

log_file = /var/log/frp/frps.log
log_level = error
log_max_days = 3
disable_log_color = false

authentication_method = token
authenticate_heartbeats = false
authenticate_new_work_conns = false
token = 12345678

allow_ports = 22,80,443,11080,11443
max_pool_count = 10
max_ports_per_client = 10

```

### 客户端安装

使用 systemd 管理服务 `/usr/lib/systemd/system/frpc.service` ：

```ini
[Unit]
Description = Frp Client Service
After = network.target syslog.target
Wants = network.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStart=/root/frp_0.49.0_linux_amd64/frpc -c /root/frpc.ini
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target

```

设置开机自启

```bash
systemctl enable --now frpc
```

参考配置如下：

```ini
# frpc.ini
[common]
server_addr = 47.108.210.201
# Same as the 'kcp_bind_port' in frps.ini
server_port = 7000

# auth token
authentication_method = token
token = tk-token

# log
log_file = /var/log/frp/frpc.log
log_level = debug
log_max_days = 3
disable_log_color = false

[http]
type = tcp
local_port = 80
local_ip = 10.244.244.11
remote_port = 11080
use_encryption = true
use_compression = true

[https]
type = tcp
local_port = 443
local_ip = 10.244.244.11
remote_port = 11443
use_encryption = true
use_compression = true
```
