## Tailscale

<https://github.com/tailscale/tailscale>

Tailscale 是一种基于 WireGuard 的虚拟组网工具，它在用户态实现了 WireGuard 协议，相比于内核态 WireGuard 性能会有所损失，但在功能和易用性上下了很大功夫：

- 开箱即用
  - 无需配置防火墙
  - 没有额外的配置
- 高安全性/私密性
  - 自动密钥轮换
  - 点对点连接
  - 支持用户审查端到端的访问记录
- 在原有的 ICE、STUN 等 UDP 协议外，实现了 DERP TCP 协议来实现 NAT 穿透
- 基于公网的控制服务器下发 ACL 和配置，实现节点动态更新
- 通过第三方（如 Google） SSO 服务生成用户和私钥，实现身份认证

Tailscale 是一款基于 WireGuard 的异地组网工具，它可以将不同网络环境的设备组成一个虚拟局域网，使其可以互相访问。我们只需要在路由器或者 Nas 上安装 Tailscale 进行组网，就可以实现以下效果：

- 连接到 Tailscale 的设备，可以直接使用内网 IP 访问家庭局域网
- 内网设备可以直接使用 Tailscale 分配的 IP 来访问连接到 Tailscale 的设备
- 支持多个局域网互相访问，每个局域网只需一台设备安装 Tailscale ( 每个局域网的网段不能相同 )

## Headscale

Tailscale 的控制服务器是不开源的，而且对免费用户有诸多限制

开源实现：<https://github.com/juanfont/headscale>

### Linux 上部署

下载最新版的二进制文件

```bash
export INST_HEADSCALE_VERSION=v0.23.0-beta2
wget -O /usr/local/bin/headscale_${INST_HEADSCALE_VERSION/v/}_linux_amd64 \
   https://github.com/juanfont/headscale/releases/download/${INST_HEADSCALE_VERSION}/headscale_${INST_HEADSCALE_VERSION/v/}_linux_amd64
wget -O /usr/local/bin/headscale_${INST_HEADSCALE_VERSION/v/}_linux_amd64-checksums.txt \
   https://github.com/juanfont/headscale/releases/download/v0.23.0-beta2/checksums.txt
chmod +x /usr/local/bin/headscale_${INST_HEADSCALE_VERSION/v/}_linux_amd64
cd /usr/local/bin/ || exit 1
grep "headscale_${INST_HEADSCALE_VERSION/v/}_linux_amd64" /usr/local/bin/headscale-v0.23.0-beta2-checksums.txt |grep -v deb | sha256sum --check || exit 1
update-alternatives --install /usr/local/bin/headscale headscale /usr/local/bin/headscale_${INST_HEADSCALE_VERSION/v/}_linux_amd64 1
alternatives --set headscale /usr/local/bin/headscale_${INST_HEADSCALE_VERSION/v/}_linux_amd64

```

创建配置目录：

```bash
mkdir -p /etc/headscale
```

创建目录用来存储数据与证书：

```bash
mkdir -p /var/lib/headscale
```

创建空的 SQLite 数据库文件：

```bash
touch /var/lib/headscale/db.sqlite
```

创建 Headscale 配置文件：

```bash
wget https://github.com/juanfont/headscale/raw/main/config-example.yaml -O /etc/headscale/config.yaml
```

- 修改配置文件，将 `server_url` 改为公网 IP 或域名。如果是国内服务器，域名必须要备案。也可以直接用公网 IP

- 修改 `listen_addr` 为 `0.0.0.0:8080`

- 如果暂时用不到 DNS 功能，可以先将 `magic_dns` 设为 false

- 建议打开随机端口，将 randomize_client_port 设为 true

- 可自定义私有网段，也可同时开启 IPv4 和 IPv6：

  ```yaml
  prefixes:
    # v6: fd7a:115c:a1e0::/48
    v4: 100.64.0.0/16
  ```

创建 SystemD service 配置文件：

```ini
# /etc/systemd/system/headscale.service
[Unit]
Description=headscale controller
After=syslog.target
After=network.target

[Service]
Type=simple
User=headscale
Group=headscale
ExecStart=/usr/local/bin/headscale serve
Restart=always
RestartSec=5

# Optional security enhancements
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/headscale /var/run/headscale
AmbientCapabilities=CAP_NET_BIND_SERVICE
RuntimeDirectory=headscale

[Install]
WantedBy=multi-user.target
```

创建 headscale 用户：

```bash
useradd headscale -d /home/headscale -m
```

修改 /var/lib/headscale 目录的 owner：

```bash
chown -R headscale:headscale /var/lib/headscale
```

修改配置文件中的 `unix_socket`：

```yaml
unix_socket: /var/run/headscale/headscale.sock
```

Reload SystemD 以加载新的配置文件：

```bash
systemctl daemon-reload
```

启动 Headscale 服务并设置开机自启：

```bash
systemctl enable --now headscale
```

查看运行状态：

```bash
systemctl status headscale
```

## 使用

Tailscale 中有一个概念叫 tailnet，可以理解成租户，租户与租户之间是相互隔离的，具体看参考 Tailscale 的官方文档：[What is a tailnet](https://tailscale.com/kb/1136/tailnet/)。Headscale 也有类似的实现叫 user，即用户。需要先创建一个 user，以便后续客户端接入，例如：

```
headscale user create default
```

查看命名空间：

```
headscale user list
```

## 可视化界面

<https://github.com/GoodiesHQ/headscale-admin>

需要通过 API Key 来接入 Headscale，所以在使用之前需要先创建一个 API key

```bash
headscale apikey create
```

将 Headscale 公网域名和 API Key 填入 Headscale-Admin 的设置页面，同时取消勾选 Legacy API，然后点击「Save」

接入成功后，点击左边侧栏的「Users」，然后点击「Create」开始创建用户

## Tailscale 客户端接入

Tailscale 接入 Headscale：

```bash
# 如果在自己的服务器上部署的，请将 <HEADSCALE_PUB_ENDPOINT> 换成 Headscale 公网 IP 或域名
tailscale up --login-server=http://<HEADSCALE_PUB_ENDPOINT>:8080 --accept-routes=true --accept-dns=false

# macos
tailscale login --login-server http://116.196.100.159:8080
```

将其中的命令复制粘贴到 headscale 所在机器的终端中，并将 USERNAME 替换为前面所创建的 user

```
headscale nodes register --user default --key mkey:016f63275a41d8a8d87319ca1c9e8e1adfd6aab66b34710978c60e3d64377b31
```

注册成功，查看注册的节点：

```
headscale nodes list
```

回到 Tailscale 客户端所在的 Linux 主机，可以看到 Tailscale 会自动创建相关的路由表和 iptables 规则。路由表可通过以下命令查看：

```
ip route show table 52
```

### Linux

```bash
# 官方提供了静态编译的二进制文件
curl -fsSL https://tailscale.com/install.sh | sh

# 例如
https://tailscale.com/download/linux/rhel-9

# 启动 tailscaled.service 并设置开机自启
systemctl enable --now tailscaled
```

### MacOS

```
brew install go@1.22
go install tailscale.com/cmd/tailscale{,d}@v1.72.1

sudo $HOME/go/bin/tailscaled install-system-daemon
# 卸载守护进程：$HOME/go/bin/tailscaled uninstall-system-daemon

tailscale ping 100.64.0.1
```

<https://github.com/tailscale/tailscale/wiki/Tailscaled-on-macOS>

在浏览器中打开 URL：`https://<HEADSCALE_PUB_ENDPOINT>/apple`

### 其他 Linux 发行版

- OpenWrt：https://github.com/adyanth/openwrt-tailscale-enabler
- 群晖：https://github.com/tailscale/tailscale-synology
- 威联通：https://github.com/tailscale/tailscale-qpkg

### Pre-Authkeys 接入

首先在服务端生成 pre-authkey 的 token，有效期可以设置为 24 小时：

```
headscale preauthkeys create -e 24h --user default
```

查看已经生成的 key：

```
headscale --user default preauthkeys list
```

现在新节点就可以无需服务端同意直接接入

````bash
tailscale up --login-server=http://<HEADSCALE_PUB_ENDPOINT>:8080 --accept-routes=true --accept-dns=false --authkey $KEY
````

## 打通局域网

只是打造了一个点对点的 Mesh 网络，各个节点之间都可以通过 WireGuard 的私有网络 IP 进行直连

配置方法很简单，首先需要设置 IPv4 与 IPv6 路由转发：

```
echo 'net.ipv4.ip_forward = 1' | tee /etc/sysctl.d/ipforwarding.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/ipforwarding.conf

sysctl -p /etc/sysctl.d/ipforwarding.conf
```

客户端修改注册节点的命令，在原来命令的基础上加上参数 `--advertise-routes=192.168.100.0/24`，告诉 Headscale 服务器“我这个节点可以转发这些地址的路由”。

在 Headscale 端查看路由，可以看到相关路由是关闭

```bash
headscale nodes list
 
# 替换为节点 ID
headscale routes list -i 3
```

开启路由：

```
headscale routes enable -r 1
```

其他节点启动时需要增加 `--accept-routes=true` 选项来声明 “我接受外部其他节点发布的路由”

## 参考文档

- <https://www.cnblogs.com/ryanyangcs/p/17954172>
- <https://littlenewton.uk/2023/09/tutorial-deployment-and-introduction-of-tailscale/index.html#1-Tailscale-%E7%AE%80%E4%BB%8B>

- 部署 DERP 中继服务器：<https://www.linkinstars.com/post/f1b8c428.html>