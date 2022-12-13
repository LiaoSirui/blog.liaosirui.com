## arping命令
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

## IP 地址冲突检测

在出问题的主机上，可以使用

```
arping -I ethN x.x.x.x
# 其中x.x.x.x为本接口的IP地址
```

命令检测地址冲突，如果没有任何输出，则表示本IP地址无冲突。如果有冲突的话，该命令会显示冲突的IP地址使用的MAC地址。