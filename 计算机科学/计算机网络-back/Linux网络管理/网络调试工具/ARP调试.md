## arp

https://blog.csdn.net/u012206617/article/details/119115346

如果是暂时性 arp 欺骗攻击至此即可，如果网络中常有此问题，继续以下：

```bash
# 如下命令建立 /ect/ip-mac 文件
echo '网关IP地址 网关MAC地址' > /etc/ip-mac
 
# 通过下面的命令查看文件是否写的正确
more /etc/ip-mac
 
# 加载静态绑定 arp 记录
arp -f /etc/ip-mac 
```

例如

```bash
# /etc/ip-mac 
10.244.244.1 00:e2:69:59:b8:82

```



如果想开机自动绑定

```bash
echo 'arp -f /ect/ip-mac' >> /etc/rc.d/rc.local
```

https://cloud.tencent.com/developer/article/1850460

## arping

https://commandnotfound.cn/linux/1/112/arping-%E5%91%BD%E4%BB%A4

arping 命令是用于发送 arp 请求到一个相邻主机的工具，arping 使用 arp 数据包，通过 ping 命令检查设备上的硬件地址。能够测试一个 `ip` 地址是否是在网络上已经被使用，并能够获取更多设备信息。功能类似于 [ping](https://commandnotfound.cn/linux/1/323/ping-命令)。



https://commandnotfound.cn/linux/1/113/arptables-%E5%91%BD%E4%BB%A4



arping 命令是用于发送 arp 请求到一个相邻主机的工具，arping使用arp数据包，通过ping命令检查设备上的硬件地址。

能够测试一个ip地址是否是在网络上已经被使用，并能够获取更多设备信息。功能类似于ping。

arping命令选项：

```
-b：用于发送以太网广播帧（FFFFFFFFFFFF）。arping一开始使用广播地址，在收到响应后就使用unicast地址。
-q：quiet output不显示任何信息；
-f：表示在收到第一个响应报文后就退出；
-timeout：设定一个超时时间，单位是秒。如果到了指定时间，arping还没到完全收到响应则退出；
-c count：表示发送指定数量的ARP请求数据包后就停止。如果指定了deadline选项，则arping会等待相同数量的arp响应包，直到超时为止；
-s source：设定arping发送的arp数据包中的SPA字段的值。如果为空，则按下面处理，如果是DAD模式（冲突地址探测），则设置为0.0.0.0，如果是Unsolicited ARP模式（Gratutious ARP）则设置为目标地址，否则从路由表得出；
-I interface：设置ping使用的网络接口

```

IP 地址冲突检测：

在出问题的主机上，可以使用

```
arping -I ethN x.x.x.x
# 其中x.x.x.x为本接口的IP地址
```

命令检测地址冲突

- 如果没有任何输出，则表示本IP地址无冲突
- 如果有冲突的话，该命令会显示冲突的 IP 地址使用的 MAC 地址

## arptables

arptables 命令用来设置、维护和检查 Linux 内核中的 arp 包过滤规则表

安装

```bash
root at devmaster1 in /etc
# dnf provides arptables
Last metadata expiration check: 2:36:47 ago on Tue 20 Dec 2022 07:47:30 AM CST.
iptables-nft-1.8.8-4.el9.x86_64 : nftables compatibility for iptables, arptables and ebtables
Repo        : @System
Matched from:
Provide    : arptables

iptables-nft-1.8.8-4.el9.x86_64 : nftables compatibility for iptables, arptables and ebtables
Repo        : baseos
Matched from:
Provide    : arptables


root at devmaster1 in /etc
# dnf install iptables-nft
Last metadata expiration check: 2:36:52 ago on Tue 20 Dec 2022 07:47:30 AM CST.
Package iptables-nft-1.8.8-4.el9.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
```

使用

arptables 命令语法

```
arptables(选项)
```

arptables 命令选项


```
-A：向规则链中追加规则；
-D：从指定的链中删除规则；
-l：向规则链中插入一条新的规则；
-R：替换指定规则；
-P：设置规则链的默认策略；
-F：刷新指定规则链，将其中的所有规则链删除，但是不改变规则链的默认策略；
-Z：将规则链计数器清零；
-L：显示规则链中的规则列表；
-X：删除指定的空用户自定义规则链；
-h：显示指令帮助信息；
-j：指定满足规则的添加时的目标；
-s：指定要匹配ARP包的源ip地址；
-d：指定要匹配ARP包的目的IP地址
```

## arpwatch

https://commandnotfound.cn/linux/1/114/arpwatch-%E5%91%BD%E4%BB%A4

arpwatch 命令用来监听网络上 arp 的记录

