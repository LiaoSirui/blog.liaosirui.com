## RDMA 技术类型

目前，有三种类型的 RDMA 网络：

- InfiniBand
- 以太网上的 RDMA（RoCE）
- iWARP

![img](.assets/RDMA技术类型/download-20231208222907217.png)

InfiniBand 网络专为 RDMA 设计，以确保在硬件级别上可靠传输。这项技术很先进，但成本很高

RoCE 和 iWARP 都是基于以太网的 RDMA 技术，可以在最广泛使用的以太网上部署具有高速、超低延迟和极低 CPU 使用率的 RDMA

RoCE 有两个版本：RoCEv1 和 RoCEv2

- RoCEv1 是基于以太网链路层实现的 RDMA 协议。交换机需要支持 PFC 等流量控制技术，以确保在物理层上可靠传输
- RoCEv2 是在以太网 TCP/IP 协议的 UDP 层实现的，引入 IP 协议来解决可扩展性问题

如下从成本、性能等几个方面对 IB、RoCE 以及 iWARP 进行对比

|        | InfiniBand   | iWARP      | RoCE         |
| ------ | ------------ | ---------- | ------------ |
| 性能   | 高           | 中         | 基本与IB相当 |
| 成本   | 高           | 中         | 低           |
| 稳定性 | 高           | 差         | 中           |
| 交换机 | IB专用交换机 | 以太交换机 | 以太交换机   |

- InfiniBand：设计之初就考虑了 RDMA，保证硬件层面的可靠传输，提供更高的带宽和更低的延迟。但需要支持 IB 网卡和交换机，成本较高
- RoCE：基于以太网的 RDMA 比 iWARP 消耗更少的资源，并且比 iWARP 支持更多的功能
- iWARP：基于 TCP 的 RDMA 网络，利用 TCP 实现可靠传输。与 RoCE 相比，在大规模网络中，iWARP 的大量 TCP 连接会占用大量内存资源。因此，iWARP 对系统规格的要求比 RoCE 更高

## RDMA Over Ethernet

由于 Infiniband 协议本身定义了一套全新的层次架构，从链路层到传输层，都无法与现有的以太网设备兼容。也就是说，如果某个数据中心因为性能瓶颈，想要把数据交换方式从以太网切换到 Infiniband 技术，那么需要购买全套的 Infiniband 设备，包括网卡、线缆、交换机和路由器等等，成本是非常高的

而 RoCE 和 iWARP 协议的出现解决了这一问题，如果用户想要在以太网中使用 RDMA 技术获得高性能，那么只需要购买支持 RoCE/iWARP 的网卡就可以了，线缆、交换机和路由器等网络设备都是兼容的 —— 因为只是在以太网传输层基础上又定义了一套协议而已

- RoCE

2010 年，IBTA 发布了 RoCE v1 规范。2014 年，IBTA 发布了 RoCE v2 规范。RoCE 与 InfiniBand 是一脉相承，RoCEv2 使用 UDP 作为传输层协议，可以跨路由转发，也是目前相对比较主流的 RDMA 使用方式

- iWARP

2007 年，IETF 发布了 iWARP（Internet Wide Area RDMA Protocol）的一系列 RFC。iWARP 使用 TCP 作为传输层协议，相比于 RoCE 协议栈更复杂，需要再硬件上实现 TCP 协议，并且由于 TCP 的限制，只能支持可靠传输，即无法支持 UDP 等传输类型。所以目前 iWARP 的发展并不如 RoCE 和 Infiniband

![The differences between RoCE VS iWARP Layers](.assets/RDMA技术类型/667934561650216960.png)

总结一下两者的差别如下：

|              | iWARP                           | RoCE v2                            |
| ------------ | ------------------------------- | ---------------------------------- |
| 标准组织     | IETF                            | IBTA                               |
| 规范         | RFC 5040~5045、6580、6581、7306 | IB Architecture Specification      |
| 传输层协议   | TCP                             | UDP                                |
| 总协议层数   | 7                               | 5                                  |
| 主要厂商     | Intel、Chelsio                  | NVIDIA（Mellanox）、Broadcom、华为 |
| 网络环境     | 有损/无损                       | 无损                               |
| 诞生时间     | 2003年                          | 2014年                             |
| 重传机制     | 选择性重传                      | Go back N，选择性重传(新硬件)      |
| 拥塞控制算法 | TCP、DCTCP、TIMELY等            | DCQCN、LDCP、TIMELY等              |
| 支持服务类型 | RC                              | RC、UD、XRC、UC等                  |
| 支持建链类型 | CM                              | Socket、CM                         |
| 通信时延     | 大                              | 小                                 |
| 可扩展性     | 强                              | 弱                                 |
| 部署难度     | 低                              | 高                                 |
| 实现复杂度   | 高                              | 低                                 |
| 灵活性       | 低                              | 高                                 |

## 容损网络 vs 无损网络

容损网络：Chelsio 公司主导的 iWarp

- iWarp 的 “选择重传协议” 是丢哪个报文就重传哪个报文，因此对丢包不敏感

无损网络：Mellanox 公司主导的 InfiniBand,  RoCE

- RoCE 的 “回退N帧协议” 是丢失报文序号之后的全部报文都要重发，因此对丢包非常敏感

![rdma-net.png](.assets/RDMA技术类型/rdma-net.png)

参考文档：<https://www.cnblogs.com/longbowchi/p/14802046.html>

- iWARP

互联网区 RDMA 协议(iWARP)：通过 IP 网络实现 RDMA 的网络协议

- RoCE

RDMA over Converged Ethernet(RoCE)，也称为 InfiniBand over Ethernet(IBoE)：实现通过以太网网络实施 RDMA 的网络协议