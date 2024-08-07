VXLAN（`Virtual eXtensible Local Area Network`，虚拟可扩展局域网），是一种虚拟化隧道通信技术。它是一种 Overlay（覆盖网络）技术，通过三层的网络来搭建虚拟的二层网络。

![img](./.assets/VXLAN简介/1737323-20200414113233675-1728120253.png)

## 参考资料

- <https://www.cnblogs.com/ryanyangcs/p/12696837.html>
- <https://www.cnblogs.com/zhouhaibing/p/11075046.html>

## 隧道

```bash
在host1上配置如下命令

#ip link add vxlan0 type vxlan id 42 dstport 4789 remote 192.168.16.29 local 192.168.199.248 dev ens33
#ip addr add 20.0.0.1/24 dev vxlan0
#ip link set vxlan0 up

在host2上进行对应配置（remote/local互换，以及ip）

#ip link add vxlan0 type vxlan id 42 dstport 4789 remote 192.168.199.248 local 192.168.16.29 dev ens33
#ip addr add 20.0.0.2/24 dev vxlan0
#ip link set vxlan0 up

# host2 开启转发和 nat
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -i vxlan0 -o ens33 -j ACCEPT
iptables -A FORWARD -i ens33 -o vxlan0 -j ACCEPT
iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

```

