## 配置服务端

安装 OpenVPN

```bash
dnf install -y epel-release

dnf install -y openvpn easy-rsa lzo openssl
```

OpenVPN 服务器需要四个文件 `ca.crt`、`server.crt`、`server.key` 和 `dh1024.pem`。这四个文件都与加密有关

Easy RSA 是 Open VPN 组织对 PKI 的实现，它是一个命令行工具，可以创建并管理 Root Certificate Authority (CA)，包括签发、吊销数字证书、创建公钥私钥对等

```bash
dnf install -y easy-rsa

mkdir -p /etc/openvpn/easy-rsa
```

配置编辑 vars 文件

```bash
cd /etc/openvpn/easy-rsa

cp /usr/share/doc/easy-rsa/vars.example ./vars
```

根据自己的环境修改

```bash
set_var EASYRSA_REQ_COUNTRY    "CN"                     # 国家
set_var EASYRSA_REQ_PROVINCE   "Sichuan"                # 省份
set_var EASYRSA_REQ_CITY       "Yibin"                  # 城市
set_var EASYRSA_REQ_ORG        "AlphaQuant Cop."        # 组织/公司
set_var EASYRSA_REQ_EMAIL      "vpn@alpha-quant.com.cn" # 邮箱
set_var EASYRSA_REQ_OU         "AlphaQuant OpenVPN"     # 单位

```

开始逐步生成所需证书

```bash
# 初始化，成功后出现 pki 目录
/usr/share/easy-rsa/3/easyrsa init-pki
```

创建根证书

```bash
/usr/share/easy-rsa/3/easyrsa build-ca nopass <<ANSWERS
vpn-ca
ANSWERS
```

创建服务器端证书

```bash
/usr/share/easy-rsa/3/easyrsa build-server-full server nopass <<ANSWERS
yes
ANSWERS
```

创建 Diffie-Hellman，确保 key 穿越不安全网络的命令

```bash
/usr/share/easy-rsa/3/easyrsa gen-dh
```

生成 ta 密钥文件

```bash
openvpn --genkey --secret ta.key
```

拷贝文件

```bash
# 拷贝根与服务器端的相关证书
cp -r pki /etc/openvpn/server/pki
cp ta.key vars /etc/openvpn/server
```

修改 `/etc/openvpn/server/alpha-quant.conf` 配置文件

```ini
local 0.0.0.0
port 1194
proto tcp
dev tun
ca /etc/openvpn/server/pki/ca.crt
cert /etc/openvpn/server/pki/issued/server.crt
key /etc/openvpn/server/pki/private/server.key
dh /etc/openvpn/server/pki/dh.pem
server 10.9.0.0 255.255.255.0
;route 10.244.244.0 255.255.255.0
ifconfig-pool-persist ipp.txt
;push "redirect-gateway def1 bypass-dhcp"
;push "route 10.244.244.0 255.255.255.0"
;push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
tls-auth /etc/openvpn/server/ta.key 0
cipher AES-256-GCM
compress lz4-v2
push "compress lz4-v2"
max-clients 100
persist-key
persist-tun
status     /var/log/openvpn-status.log
log        /var/log/openvpn.log
verb 3
client-config-dir /etc/openvpn/ccd
```

含义如下：

```ini
# 监听地址
local 0.0.0.0
# 监听端口
port 1194
# 监听协议
proto tcp
# 采用路由隧道模式
dev tun

# ca证书路径
ca /etc/openvpn/server/pki/ca.crt
# 服务器证书
cert /etc/openvpn/server/pki/issued/server.crt
# This file should be kept secret 服务器秘钥
key /etc/openvpn/server/pki/private/server.key
# 密钥交换协议文件
dh /etc/openvpn/server/pki/dh.pem

# VPN 服务端为自己和客户端分配 IP 的地址池，服务端自己获取网段的第一个地址（这里为 10.8.0.1），后为客户端分配其他的可用地址。以后客户端就可以和 10.8.0.1 进行通信。注意：该网段地址池不要和已有网段冲突或重复
server 10.8.0.0 255.255.255.0

# 使用一个文件记录已分配虚拟 IP 的客户端和虚拟 IP 的对应关系，以后 openvpn 重启时，将可以按照此文件继续为对应的客户端分配此前相同的 IP。也就是自动续借 IP 的意思
ifconfig-pool-persist ipp.txt

# 重启时仍保留一些状态
persist-key
persist-tun

# 客户端所有流量都通过 openvpn 转发，类似于代理（本机的 IP 会显示远端的 IP）
;push "redirect-gateway def1 bypass-dhcp"

# 当上面全局流量开启后, 但部分不想走全局，只需求 10.244.244.0 网段走 vpn 隧道，访问其他还是走本地网络
# 可通过下面两条进行配置（客户端配置）
;route-nopull
;route 10.244.244.0 255.255.255.0 vpn_gateway

# 将服务器端的内网地址推给客户端，添加到客户端的路由表中，可以添加多条
;push "route 10.244.244.0 255.255.255.0"

# 服务端推送客户端 dhcp 分配 dns
;push "dhcp-option DNS 8.8.8.8"

# 客户端之间互相通信
# 允许客户端与客户端相连接，默认情况下客户端只能与服务器相连接
client-to-client

# 存活时间，10 秒 ping 一次, 120 如未收到响应则视为离线
keepalive 10 120 

# openvpn 2.4 版本的 vpn 才能设置此选项。表示服务端启用 lz4 的压缩功能，传输数据给客户端时会压缩数据包。Push 后在客户端也配置启用 lz4 的压缩功能，向服务端发数据时也会压缩。如果是 2.4 版本以下的老版本，则使用用 comp-lzo 指令
compress lz4-v2
push "compress lz4-v2"

# 启用lzo数据压缩格式。此指令用于低于2.4版本的老版本。且如果服务端配置了该指令，客户端也必须要配置
comp-lzo

# 最多允许 100 客户端连接
max-clients 100

# 用户
user openvpn

# 用户组
group openvpn

# 参数 0 可以省略，如果不省略，那么客户端配置相应的参数该配成 1；如果省略，那么客户端不需要 tls-auth 配置
# 开启 TLS-auth，使用 ta.key 防御攻击。服务器端的第二个参数值为 0，客户端的为 1
tls-auth /etc/openvpn/server/ta.key 0
```

设置路由
```bash
# 如果不设置，连上 VPN 后将无法正常上网
iptables -t nat -A POSTROUTING -s 10.7.7.0/24 -j MASQUERADE
iptables-save >> /etc/sysconfig/iptables

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

```

拷贝启动文件

```bash
cp /usr/lib/systemd/system/openvpn-server@.service /usr/lib/systemd/system/openvpn-server@alpha-quant.service

systemctl enable --now openvpn-server@alpha-quant.service
```

查看端口监听

```bash
# 查看
netstat -lntp | grep 1194
tcp        0      0 0.0.0.0:1194       0.0.0.0:*     LISTEN      1470/openvpn
```

## 配置客户端

### 手动管理

创建客户端证书和 key

```bash
mkdir /etc/openvpn/client/router && cd /etc/openvpn/client/router || exit 1

cd /etc/openvpn/easy-rsa || exit 1

# 生成 router 对应姓名的客户端证书
/usr/share/easy-rsa/3/easyrsa build-client-full router nopass <<ANSWERS
yes
ANSWERS
```

拷贝证书

```bash
# 拷贝客户端相关证书
cp pki/ca.crt /etc/openvpn/client/router
cp pki/issued/router.crt /etc/openvpn/client/router
cp pki/private/router.key /etc/openvpn/client/router
cp /etc/openvpn/easy-rsa/ta.key /etc/openvpn/client/router
```

备注：移除证书

```bash
/usr/share/easy-rsa/3/easyrsa revoke 证书名
```

### 新增用户脚本

客户端配置如下

```ini
client
dev tun
proto tcp
remote 47.108.13.23 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert tomma.crt
key tomma.key
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-GCM
compress lz4-v2
verb 3
auth-nocache
<ca>
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN ENCRYPTED PRIVATE KEY-----
-----END ENCRYPTED PRIVATE KEY-----
</key>
<tls-auth>
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
-----END OpenVPN Static key V1-----
</tls-auth>
```

创建一个模版文件

```ini
client
dev tun
proto tcp
remote 47.108.13.23 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert INST_AUTH_USERNAME.crt
key INST_AUTH_USERNAME.key
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-GCM
compress lz4-v2
verb 3
auth-nocache
<ca>
INST_AUTH_CA
</ca>
<cert>
INST_AUTH_CERT
</cert>
<key>
INST_AUTH_KEY
</key>
<tls-auth>
INST_AUTH_TLS_AUTH
</tls-auth>
```

使用如下脚本创建



### 移除用户脚本

移除用户脚本

```bash
#!/usr/bin/env bash

keys_dir=/etc/openvpn/client/keys
easyras_dir=/etc/openvpn/easy-rsa/

for user in "$@"
do
    user_dir="${keys_dir}/${user}"
    cd ${easyras_dir} || exit 1
    echo -e 'yes\n' | ./easyrsa revoke 
/usr/share/easy-rsa/3/easyrsa revoke "${user}"<<ANSWERS
yes
ANSWERS
    /usr/share/easy-rsa/3/easyrsa  gen-crl
    if [ -d "${user_dir}" ]; then
        rm -rf "${user_dir}*"
    fi
    systemctl restart openvpn-server@alpha-quant.service 
done

exit 0

```

### 固定 IP

```bash
# 这里的 router 为客户端登陆名
vim /etc/openvpn/ccd/router
 
# 添加指定 IP
ifconfig-push 10.8.0.6 255.255.255.0
```

## Mac 客户端额外设置

在一部分 Mac 上使用 OpenVPN 进行连接网络，出现错误：

```bash
Transport Error: socket_protect error (UDP)
Client terminated, restarting in 2000 ms...
```

出现原因：在启动这个 OpenVPN 时，不知道什么原因导致 `/var/run/agent_ovpnconnect.sock` 服务没有正常启动

手动启动相关服务

```bash
sudo /Library/Frameworks/OpenVPNConnect.framework/Versions/Current/usr/sbin/ovpnagent
```

设置自动加载命令，加载并启动相关服务，重启电脑后不用重新手动启用

```bash
sudo launchctl load -w /Library/LaunchDaemons/org.openvpn.client.plist
```

参考来源：<https://github.com/OpenVPN/openvpn3/issues/139>
