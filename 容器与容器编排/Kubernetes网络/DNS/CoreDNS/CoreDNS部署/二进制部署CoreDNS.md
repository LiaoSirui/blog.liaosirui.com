## 预编译二进制

CoreDNS 在 GitHub上面提供了各种版本的预编译包，只需要下载对应的版本即可

- GitHub Release：<https://github.com/coredns/coredns/releases/>

```bash
cd $(mktemp -d)

export INST_COREDNS_VERSION=v1.15.0
export INST_COREDNS_ARCH="amd64"

curl -sL "https://gh-proxy.org/https://github.com/coredns/coredns/releases/download/${INST_COREDNS_VERSION}/coredns_${INST_COREDNS_VERSION/v/}_linux_${INST_COREDNS_ARCH}.tgz" -o ./coredns_${INST_COREDNS_VERSION/v/}_linux_${INST_COREDNS_ARCH}.tgz

tar zxvf ./coredns_${INST_COREDNS_VERSION/v/}_linux_${INST_COREDNS_ARCH}.tgz -C .
```

## 自建 DNS

### 配置 Coredns

CoreDNS 的核心配置文件是 Corefile，常规都会配置转发器、日志、缓存、监控、健康检测等功能。Corefile 文件可以通过 reload 插件来实现热加载，从而在不重启 CoreDNS 服务的情况下应用新的配置。这种热加载功能对于生产环境尤为重要，因为它确保了配置的动态更新和服务的连续性。

```bash
# 创建配置文件目录
mkdir -p /etc/coredns

# 创建 Corefile 文件
cat > /etc/coredns/Corefile << \EOF
.:53 {
  # 启用日志记录
  log
  # 防止 DNS 查询在多个 DNS 服务器之间循环，导致无限查询循环。如果检测到循环，CoreDNS 会中止查询。
  loop
  # 启用错误日志记录
  errors
  # 通过 reload 插件实现热加载功能，确保在不重启 CoreDNS 服务的情况下，动态应用新的配置
  # 每隔 30 秒重载一次 Corefile 配置文件。
  reload 30s
  # 配置 DNS 查询的缓存时间为 300 秒，减少重复查询，提高响应速度和性能。
  cache 300s
  # 在指定地址和端口上提供 readiness（就绪）探针。
  ready 0.0.0.0:8181
  # 在指定地址和端口上提供健康检查（health check）。
  health 0.0.0.0:8080
  # 在指定地址和端口上启用 Prometheus metrics。
  prometheus 0.0.0.0:9253
  # 使用轮询模式进行负载均衡。
  loadbalance round_robin
  # DNS 转发
  forward . 180.184.1.1 114.114.114.119
}
EOF
```

### 配置服务自启动

使用 systemd 对其进行管理

```bash
# 创建服务用户
useradd coredns -s /sbin/nologin -c 'coredns user'
 
# 配置 coredns systemd 文件
cat > /usr/lib/systemd/system/coredns.service << \EOF
[Unit]
Description=CoreDNS DNS server
Documentation=https://coredns.io
After=network.target
 
[Service]
PermissionsStartOnly=true
LimitNOFILE=1048576
LimitNPROC=512
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
User=coredns
WorkingDirectory=/home/coredns
# 指定 Corefile 文件路径
ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile
ExecReload=/bin/kill -SIGUSR1 $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动 CoreDNS 服务
systemctl enable coredns.service --now

# 默认监听 tcp & udp 53 端口
ss -antulp | grep coredns
```

### 性能测试

常用的 DNS 服务器性能测试工具包括 `dnsperf` 和 `queryperf`

```bash
dnsperf -d dnsfile -s 192.168.1.1 -T 2 -c 512 -l 60
```

dnsfile 示例：

```bash
rockylinux.cn MX
api.rockylinux.cn A
app.rockylinux.cn AAA
```

### 客户端配置

- Linux

```bash
nmcli connection modify eth0 ipv4.dns "192.168.1.1 192.168.1.2"
```

- Windows

```powershell
 # 查看网络接口名称
netsh interface ipv4 show config
 
# 配置 DNS 服务器（将对应 Interface Name 替换成上面命令查看到的网络接口名称 ）
netsh interface ipv4 set dnsservers name="Interface Name" source=static address=192.168.1.1 primary 
netsh interface ipv4 add dnsservers name="Interface Name" address=192.168.1.2 index=2
 
# 验证配置是否生效
netsh interface ipv4 show config
```
