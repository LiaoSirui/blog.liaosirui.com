如果 K8s 使用 Calico 作为网络方案的话，应该都会知道 Calico 是个纯 3 层的方案，也是就说，所有的数据包，都是通过路由的形式找到对应机器和容器的，然后通过 BGP 协议来将所有的路由同步到所有的机器或者数据中心，来完成整个网络的互联。

简单的来说，Calico 针对一个容器，在主机上创建了一堆 veth pair，其中一端在主机，一端在容器的网络空间里，然后在主机和容器中分别设置几条路由，来完成网络的互联，我们可以看一个例子：

主机上：

```bash
$ ip addr
...
771: cali45b9132fec1@if4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1440 qdisc noqueue state UP group default
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 14
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link
       valid_lft forever preferred_lft forever
...

$ ip route 
...
10.218.240.252 dev cali45b9132fec1 scope link
...
```

容器里：

```bash
$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
3: eth0@if771: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1440 qdisc noqueue state UP
    link/ether 66:fb:34:db:c9:b4 brd ff:ff:ff:ff:ff:ff
    inet 10.218.240.252/32 scope global eth0
       valid_lft forever preferred_lft forever

$ ip route
default via 169.254.1.1 dev eth0
169.254.1.1 dev eth0
```

按照上面的逻辑，可以理一下：

- 当目的地址是`10.218.240.252`的数据包，也就是目的是容器的数据包，到达主机，主机根据`10.218.240.252 dev cali45b9132fec1 scope link`这条路由，将数据包丢给`cali45b9132fec1`这个veth，然后容器中对应的`eth0`就可以收到数据包了。
- 当容器中的数据包需要发出，就是走默认路由，也就是`default via 169.254.1.1 dev eth0`，将数据包丢给`eth0`，这时主机对应的`cali45b9132fec1`可以收到包，然后继续进行路由选择，转发到对应端口。

Calico 利用了网卡的 proxy_arp 功能，具体的，是将 /proc/sys/net/ipv4/conf/DEV/proxy_arp 置为 1，当设置这个标志之后，主机就会看起来像一个网关，会响应所有的 ARP 请求，并将自己的 MAC 地址告诉客户端。

也就是说，当容器发送 ARP 请求时，主机会告诉容器，我拥有 169.254.1.1 这个 IP，我的 MAC 地址是 XXX，这样，容器就可以顺利的将数据包发出来了，于是网络就通了。

https://www.ichenfu.com/2019/03/14/proxy-arp-in-calico/