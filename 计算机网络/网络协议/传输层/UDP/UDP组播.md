## 多播基础概念

### 多播地址

多播的地址是特定的，D 类地址用于多播。D 类 IP 地址就是多播 IP 地址，即 224.0.0.0 至 239.255.255.255 之间的 IP 地址，并被划分为局部连接多播地址、预留多播地址和管理权限多播地址 3 类：

　　1、局部多播地址：在 224.0.0.0～224.0.0.255 之间，这是为路由协议和其他用途保留的地址，路由器并不转发属于此范围的IP包。

　　2、预留多播地址：在 224.0.1.0～238.255.255.255 之间，可用于全球范围（如Internet）或网络协议。

　　3、管理权限多播地址：在 239.0.0.0～239.255.255.255 之间，可供组织内部使用，类似于私有 IP 地址，不能用于 Internet，可限制多播范围

## Linux UDP 组播

### Rp_filter

rp_filter （Reverse Path Filtering）参数定义了网卡对接收到的数据包进行反向路由验证的规则。有三个值，0、1、2，具体含意如下：

- 0：关闭反向路由校验
- 1：开启严格的反向路由校验。对每个进来的数据包，校验其反向路由是否是最佳路由。如果反向路由不是最佳路由，则直接丢弃该数据包。
- 2：开启松散的反向路由校验。对每个进来的数据包，校验其源地址是否可达，即反向路由是否能通（通过任意网口），如果反向路径不通，则直接丢弃该数据包。

反向路由校验，就是在一个网卡收到数据包后，把源地址和目标地址对调后查找路由出口，从而得到反身后路由出口。然后根据反向路由出口进行过滤。

- 当 rp_filter 的值为 1 时，要求反向路由的出口必须与数据包的入口网卡是同一块，否则就会丢弃数据包。
- 当 rp_filter 的值为 2 时，要求反向路由必须是可达的，如果反路由不可达，则会丢弃数据

看接受组播的网卡是否过滤

```
cat /proc/sys/net/ipv4/conf/eth0/rp_filter
cat /proc/sys/net/ipv4/conf/all/rp_filter
```

临时修改过滤

```bash
sysctl -w net.ipv4.conf.eth0.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0
```

 参考资料：<https://www.cnblogs.com/dissipate/p/13741595.html>

配置内核参数

```bash
sysctl -w net.ipv4.conf.eth0.mc_forwarding=1
```

开启网卡组播

```bash
ethtool -s eth0 multicast on
```

- <https://www.cnblogs.com/newjiang/p/13706485.html>

### Python 发送 UDP 组播

使用 `ip route` 命令为多播流量添加路由规则，从而指定多播流量通过特定的接口传输

```bash
ip route add 239.255.255.250/32 dev eth0
# ip route del 239.255.255.250/32 dev eth0
```

发送端

```python
import socket
import time

# 多播地址和端口
MCAST_GRP = "232.8.0.19"
MCAST_PORT = 23110

# 指定要使用的网卡IP（修改为要使用的网卡IP地址）
interface_ip = "192.168.152.134"

# 创建 UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

# 设置 TTL 为 1，限制多播范围在本地网段
sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 1)

# 指定从哪个网卡发送组播数据
sock.setsockopt(
    socket.IPPROTO_IP, socket.IP_MULTICAST_IF, socket.inet_aton(interface_ip)
)

try:
    while True:
        message = f"来自 {interface_ip} 的组播消息"
        sock.sendto(message.encode(), (MCAST_GRP, MCAST_PORT))
        print(f"已发送: {message}")
        time.sleep(1)
except KeyboardInterrupt:
    print("服务器退出")
finally:
    sock.close()

```

接收端

```python
import socket

# 多播地址和端口
MCAST_GRP = "232.8.0.19"
MCAST_PORT = 23110

# 指定要使用的网卡 IP（修改为要使用的网卡 IP 地址）
interface_ip = "192.168.152.129"

# 创建 UDP socket 并允许地址复用
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

# 绑定到组播端口，'' 表示所有本地地址
sock.bind(("", MCAST_PORT))

# 加入组播组：mreq 包含组播地址和本地接口 IP
mreq = socket.inet_aton(MCAST_GRP) + socket.inet_aton(interface_ip)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)

print("客户端已启动, 等待接收消息...")
try:
    while True:
        data, addr = sock.recvfrom(1024)
        # 打印收到的原始组播报文（字节）
        print(f"从 {addr} 收到数据: {data}")
except KeyboardInterrupt:
    print("客户端退出")
finally:
    sock.close()

```

- 组播地址范围：有效的 IPv4 组播地址范围是 `224.0.0.0` 到 `239.255.255.255`。

- TTL 设置：TTL 值决定组播消息的传播范围。

  - `1`：仅本地子网。

  - 大于 `1`：跨越多个路由器（需要路由器支持）。

- 防火墙规则：确保防火墙未阻止组播流量。

- 网络配置：某些虚拟网络可能需要特殊配置以支持组播。