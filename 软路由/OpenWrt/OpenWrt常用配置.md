## 配置

### 升级所有可以更新的软件

```bash
opkg upgrade $(opkg list-upgradable | awk '{print $1}')
```

### wget/curl/opkg 支持 https

```bash
opkg update
opkg install libustream-openssl ca-bundle ca-certificates
```

### 设置 LuCI 登录密码

- 系统 - 管理权 - 主机密码
- 密码
- 确认密码
- 保存

这个密码既是 root 用户的 LuCI 登录密码，也是 root 用户的 ssh 登录密码。

### 修改时区

- 系统 - 系统 - 系统属性 - 常规设置
- 时区: Asia/Shanghai
- 保存并应用

### 禁用 IPv6

- 关闭 LAN 口分配 IPv6 IP。
  - 网络 - 接口 - LAN - 编辑 - 常规设置
  - IPv6 分配长度：已禁用
  - 保存
- 关闭 IPv6 DHCP
  - 网络 - 接口 - LAN - 编辑 - DHCP 服务器 - IPv6 设置
  - 路由通告服务：已禁用
  - DHCPv6 服务：已禁用
  - 保存
- 关闭 IPv6 WAN 口
  - 网络 - 接口 - WAN6
  - 停止
- 禁止 IPv6 WAN 功能自动启动
  - 网络 - 接口 - WAN6 - 编辑 - 常规设置
  - 开机自动运行：取消勾选
  - 保存
- 保存并应用

### 默认 Shell 改用 bash

默认为 ash

```bash
opkg install bash

> vim /etc/passwd
root:x:0:0:root:/root:/bin/bash
```

## 插件

### 简单插件-无需配置

- 中文支持：`luci-i18n-base-zh-cn`
- sftp

安装对应的软件：

```bash
opkg install vsftpd openssh-sftp-server
```

设置系统开启后自动启动 sftp 服务：

```bash
/etc/init.d/vsftpd enable
```

启动 sftp 服务：

```bash
/etc/init.d/vsftpd start
```

- 主题

```bash
opkg install luci-compat
opkg install luci-lib-ipkg

wget --no-check-certificate https://github.com/jerrykuku/luci-theme-argon/releases/download/v2.3/luci-theme-argon_2.3_all.ipk
opkg install luci-theme-argon*.ipk
```

- 开启 bbr 算法

```bash
opkg install kmod-tcp-bbr

> lsmod | grep bbr
tcp_bbr                 4832  0 

> sysctl net.ipv4.tcp_congestion_control
net.ipv4.tcp_congestion_control = bbr
> sysctl net.ipv4.tcp_available_congestion_control
net.ipv4.tcp_available_congestion_control = cubic reno bbr
> sysctl net.core.default_qdisc
net.core.default_qdisc = fq_codel

> cat /etc/sysctl.d/12-tcp-bbr.conf 
# Do not edit, changes to this file will be lost on upgrades
# /etc/sysctl.conf can be used to customize sysctl settings
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
```

- 文件传输插件 `luci-app-filetransfer`

- 用 frp 来在 OpenWrt 下实现内网穿透

```bash
# https://github.com/kuoruan/openwrt-frp/releases
https://github.com/kuoruan/openwrt-frp/releases/download/v0.47.0-1/frpc_0.47.0-1_x86_64.ipk
opkg install frpc_*.ipk

# https://github.com/kuoruan/luci-app-frpc/releases
wget https://github.com/kuoruan/luci-app-frpc/releases/download/v1.2.1-1/luci-app-frpc_1.2.1-1_all.ipk
wget https://github.com/kuoruan/luci-app-frpc/releases/download/v1.2.1-1/luci-i18n-frpc-zh-cn_1.2.1-1_all.ipk
opkg install luci-app-frpc_*.ipk
```

- OpenClash

如果使用 nftables

```bash
# nftables
opkg update
opkg install coreutils-nohup bash dnsmasq-full curl ca-certificates ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base
```

如果使用 iptables

```bash
# iptables
opkg update
opkg install coreutils-nohup bash iptables dnsmasq-full curl ca-certificates ipset ip-full iptables-mod-tproxy iptables-mod-extra libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip luci-compat luci luci-base
```

然后安装 OpenClash

```bash
# https://github.com/vernesong/OpenClash/releases
wget https://github.com/vernesong/OpenClash/releases/download/v0.45.112-beta/luci-app-openclash_0.45.112-beta_all.ipk
opkg -i luci-app-openclash*.ipk
```
