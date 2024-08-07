## 参考配置

```ini
# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    # debug
    # log         127.0.0.1 local0 debug 
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    # option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s

    timeout tunnel 1h
    timeout client-fin 30s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 200000

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend route-80
    bind *:80
    acl denylist src 171.83.9.9 113.108.77.24 139.224.229.201
    tcp-request connection reject if denylist
    redirect scheme https if !{ ssl_fc }
    capture request header Host len 20
    capture request header Referer len 60
    default_backend route-80
    mode http
    option tcplog
    option httplog

backend route-80
    balance source
    mode http
    option forwardfor
    server      master1 192.168.146.211:80  send-proxy  check inter 3000 fall 3 rise 5
    server      master2 192.168.146.212:80  send-proxy  check inter 3000 fall 3 rise 5
    server      master3 192.168.146.213:80  send-proxy  check inter 3000 fall 3 rise 5

frontend route-443
    bind *:443
    acl denylist src 171.83.9.9 113.108.77.24 139.224.229.201
    tcp-request connection reject if denylist
    default_backend route-443
    mode tcp
    option tcplog
    option httplog

backend route-443
    balance source
    option forwardfor
    mode tcp
    server      master1 192.168.146.211:443  send-proxy  check inter 3000 fall 3 rise 5
    server      master2 192.168.146.212:443  send-proxy  check inter 3000 fall 3 rise 5
    server      master3 192.168.146.213:443  send-proxy  check inter 3000 fall 3 rise 5

frontend route-6443
    bind *:6443 npn spdy/2 alpn h2,http/1.1
    #bind *:6443
    default_backend route-6443
    mode tcp
    option forwardfor

backend route-6443
    balance source
    mode tcp
    option forwardfor
    maxconn         8000
    timeout client  60s
    server      master1 192.168.146.211:6443   check inter 3000 fall 3 rise 5
    server      master2 192.168.146.212:6443   check inter 3000 fall 3 rise 5
    server      master3 192.168.146.213:6443   check inter 3000 fall 3 rise 5
```

如果不需要 proxy protocol 的话，去掉 `send-proxy` 参数

## 内核参数调整

```bash
fs.file-max = 12453500
# 表示单个进程较大可以打开的句柄数；

fs.nr_open = 12453500
# 单个进程所允许的文件句柄的最大数目

kernel.shmall = 4294967296
# 内核允许使用的共享内存大 Controls the maximum number of shared memory segments, in pages

kernel.shmmax = 68719476736
# 单个共享内存段的最大值 Controls the maximum shared segment size, in bytes

kernel.msgmax = 65536
# 内核中消息队列中消息的最大值 Controls the maximum size of a message, in bytes

net.ipv4.tcp_tw_reuse = 1
# 参数设置为 1 ，表示允许将 TIME_WAIT 状态的 socket 重新用于新的 TCP 链接，这对于服务器来说意义重大，因为总有大量 TIME_WAIT 状态的链接存在；

ner.ipv4.tcp_keepalive_time = 600
# 当 keepalive 启动时，TCP 发送 keepalive 消息的频度；默认是 2 小时，将其设置为 10 分钟，可以更快的清理无效链接。

net.ipv4.tcp_fin_timeout = 30
# 当服务器主动关闭链接时，socket 保持在 FIN_WAIT_2 状态的较大时间

net.ipv4.tcp_max_tw_buckets = 5000
# 这个参数表示操作系统允许 TIME_WAIT 套接字数量的较大值，如果超过这个数字，TIME_WAIT 套接字将立刻被清除并打印警告信息。
# 该参数默认为 180000，过多的 TIME_WAIT 套接字会使 Web 服务器变慢。

net.ipv4.ip_local_port_range = 1025 65000
# 定义 UDP 和 TCP 链接的本地端口的取值范围。

net.ipv4.tcp_rmem = 10240 87380 12582912
# 定义了 TCP 接受缓存的最小值、默认值、较大值。

net.ipv4.tcp_wmem = 10240 87380 12582912
# 定义 TCP 发送缓存的最小值、默认值、较大值。

net.core.netdev_max_backlog = 8096
# 当网卡接收数据包的速度大于内核处理速度时，会有一个列队保存这些数据包。这个参数表示该列队的较大值。

net.core.rmem_default = 6291456
# 表示内核套接字接受缓存区默认大小。

net.core.wmem_default = 6291456
# 表示内核套接字发送缓存区默认大小。

net.core.rmem_max = 12582912
# 表示内核套接字接受缓存区较大大小。

net.core.wmem_max = 12582912
# 表示内核套接字发送缓存区较大大小。

# 注意：以上的四个参数，需要根据业务逻辑和实际的硬件成本来综合考虑；

net.ipv4.tcp_syncookies = 1
# 与性能无关。用于解决 TCP 的 SYN 攻击。

net.ipv4.tcp_max_syn_backlog = 8192
# 这个参数表示 TCP 三次握手建立阶段接受 SYN 请求列队的较大长度，默认 1024，将其设置的大一些可以使出现繁忙来不及 accept 新连接的情况时，Linux 不至于丢失客户端发起的链接请求。

net.ipv4.tcp_tw_recycle = 1
# 这个参数用于设置启用 timewait 快速回收。

net.core.somaxconn=262114
# 选项默认值是 128，这个参数用于调节系统同时发起的 TCP 连接数，在高并发的请求中，默认的值可能会导致链接超时或者重传，因此需要结合高并发请求数来调节此值。

net.ipv4.tcp_max_orphans=262114
# 选项用于设定系统中最多有多少个 TCP 套接字不被关联到任何一个用户文件句柄上。如果超过这个数字，孤立链接将立即被复位并输出警告信息。这个限制指示为了防止简单的 DOS 攻击，不用过分依靠这个限制甚至认为的减小这个值，更多的情况是增加这个值。
```



