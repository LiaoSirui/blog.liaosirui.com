sysctl 命令用于运行时配置内核参数，这些参数位于 `/proc/sys` 目录下。

sysctl 配置与显示在 `/proc/sys` 目录中的内核参数，可以用 sysctl 来设置或重新设置联网功能，如 IP 转发、IP 碎片去除以及源路由检查等。用户只需要编辑 `/etc/sysctl.conf` 文件，即可手工或自动执行由 sysctl 控制的功能。

sysctl命令的作用：在运行时配置内核参数

用法举例:

- `-w` 用此选项来改变一个 sysctl 设置，例：`sysctl -w net.ipv4.ip_forward=1`
- `-p` 载入 sysctl 配置文件，如 `-p` 后未指定路径，则载入 `/etc/sysctl.conf`，例：`sysctl -p /etc/sysctl.conf`





````
vm.swappiness = 0
kernel.sysrq = 1

net.ipv4.neigh.default.gc_stale_time = 120

# see details in https://help.aliyun.com/knowledge_detail/39428.html
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2

# see details in https://help.aliyun.com/knowledge_detail/41334.html
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_slow_start_after_idle = 0

````

