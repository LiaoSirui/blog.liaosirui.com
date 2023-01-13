Fluentd 有多种安装方式，比如可以通过 Docker 或者手动进行安装，在手动安装 Fluentd 之前，请确保你的环境已正确设置，以避免以后出现任何不一致。

## 环境配置

建议执行：

- 设置 NTP

节点上设置 NTP 守护进程（例如 `chrony`、`ntpd` 等）以获得准确的当前时间戳，这对于所有生产服务至关重要

- 增加文件描述符的最大数量

可以使用 `ulimit -n` 命令查看现有配置：

```bash
> ulimit -n

65535
```

如果控制台显示 1024，那是不够的。

请将以下几行添加到 `/etc/security/limits.conf` 文件并重启机器：

```bash
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536

```

如果使用 `systemd` 下运行 fluentd，也可以使用选项 `LimitNOFILE=65536` 进行配置，如果你使用的是 `td-agent` 包，则默认会设置该值

- 优化网络内核参数

对于具有许多 Fluentd 实例的高负载环境，可以将以下配置添加到 `/etc/sysctl.conf` 文件中：

```bash
# fluentd
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535
```

使用 `sysctl -p` 命令或重新启动节点使更改生效

## td-agent 包

