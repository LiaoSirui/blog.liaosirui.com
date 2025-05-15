## VRRP 简介

虚拟路由冗余协议 VRRP（Virtual Router Redundancy Protocol）是一种用于提高网络可靠性的容错协议。通过 VRRP，可以在主机的下一跳设备出现故障时，及时将业务切换到备份设备，从而保障网络通信的连续性和可靠性。

VRRP 协议中定义了三种状态机：初始状态（Initialize）、活动状态（Master）、备份状态（Backup）。其中，只有处于 Master 状态的设备才可以转发那些发送到虚拟 IP 地址的报文。

| 状态       | 说明                                                         |
| ---------- | ------------------------------------------------------------ |
| Initialize | 该状态为 VRRP 不可用状态，在此状态时设备不会对 VRRP 通告报文做任何处理。通常设备启动时或设备检测到故障时会进入 Initialize 状态 |
| Master     | 当 VRRP 设备处于 Master 状态时，它将会承担虚拟路由设备的所有转发工作，并定期向整个虚拟内发送 VRRP 通告报文 |
| Backup     | 当 VRRP 设备处于 Backup 状态时，它不会承担虚拟路由设备的转发工作，并定期接受 Master 设备的 VRRP 通告报文，判断 Master 的工作状态是否正常 |

## 参考资料

- <https://info.support.huawei.com/info-finder/encyclopedia/zh/VRRP.html>

