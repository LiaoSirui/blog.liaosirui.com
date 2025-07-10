## 基础概念

MTU：链路层具有最大传输单元 MTU 这个特性，限制了数据帧的最大长度，不同的网络类型都有一个上限值。如以太网 Ethernet II 和 802.3 规范对帧中的数据字段长度都有一个限制，其最大值分别是 1500 和 1492 个字节。 如果 IP 层有数据包要传，而且数据包的长度（包括 IP 头）超过了 MTU，那么 IP 层就要对数据包进行分片（fragmentation）操作，使每一片的长度都小于或等于 MTU。

MSS：TCP 数据包每次能够传输的最大数据分段称为 MSS （Maxitum Segment Size），为了达到最佳的传输效能，在建立 TCP 连接时双方协商 MSS 值，双方提供的 MSS 值的最小值为这次连接的最大 MSS 值。MSS 往往基于 MTU 计算出来，通常 MSS=MTU-sizeof (IP Header)-sizeof (TCPHeader)=1500-20-20=1460

IP 分片产生的原因是网络层的 MTU；TCP 分段产生原因是 MSS

## GSO 简介

GSO（ Generic Segmentation Offload ），另外还有 GRO

由于 MTU 的限制，所以对于 UDP 的写入，如果写入的数据超过 MTU 大小，且没有禁用 IP 分片，那么将会被进行 IP 分片，但是 IP 分片是不利于做可靠传输协议的，因为丢包成本太高了，丢一个 IP 包就等于丢了所有。前面提到减少系统调用，如果使用 GSO 的话也是可以的，可以一次写入更大的 buffer 来达到减少系统调用的目的，不过这个有个前提是每次需要写入的数据足够大，且对内核版本要求较高。

另外 GSO 除了可以一次写入较大 buffer ，在支持的 GSO offload 的网卡还有相应的硬件加速，可以通过`ethtool -K eth0 tx-udp-segmentation on`来开启。

GSO 可以通过两种方式去使用，一种是设置 socket option 开启，一种是通过 oob 去对 msg 级别设置。 一般通过 oob 的方式去进行设置，因为这样比较灵活一些，缺点的话就是会多 copy 一点内存。

GSO 是一种类似于 TSO 的技术，但是不仅限于 TCP 协议，也适用于其他协议，如 UDP。与 TSO 不同的是，GSO 通过将多个小的数据包组合成一个大的数据包来减少网络流量的开销。这样做有助于减少 CPU 的负担，并提高网络性能。

软件实现包拆分，若网卡不支持分片、重组 offload 能力（如 TSO、UFO、LRO）的情况下，GSO 推迟数据分片直至数据发送到网卡驱动之前进行分片后再发往网卡。

## TSO

TSO（TCP Segmentation Offload）

对 TSO 的简单理解就是：比如：我们要用汽车把 3000 本书送到另一个城市，每趟车只能装下 1000 本书，那么我们就要书分成 3 次来发。如何把 3000 本书分成 3 份的事情是我们做的，汽车司机只负责运输。TSO 的概念就是：我们把 3000 本书一起给司机，由他去负责拆分的事情，这样我们就有更多的时间处理其他事情。对应到计算机系统中，“我们” 就是 CPU，“司机” 就是网卡。

在网络系统中，发送 TCP 数据之前，CPU 需要根据 MTU（一般为 1500）来将数据放到多个包中发送，对每个数据包都要添加 IP 头，TCP 头，分别计算 IP 校验和，TCP 校验和。如果有了支持 TSO 的网卡，CPU 可以直接将要发送的大数据发送到网卡上，由网卡硬件去负责分片和计算校验和。

TSO (TCP Segmentation Offload) 是一种利用网卡替代 CPU 对大数据包进行分片，降低 CPU 负载的技术。如果数据包的类型只能是 TCP，则被称之为 TSO。此功能需要网卡提供支持。TSO 是使得网络协议栈能够将大块 buffer 推送至网卡，然后网卡执行分片工作，这样减轻了 CPU 的负荷，其本质实际是延缓分片。这种技术在 Linux 中被叫做 GSO (Generic Segmentation Offload)，它不需要硬件的支持分片就可使用。对于支持 TSO 功能的硬件，则先经过 GSO 功能处理，然后使用网卡的硬件分片能力进行分片；而当网卡不支持 TSO 功能时，则将分片的执行放在了将数据推送的网卡之前，也就是在调用网卡驱动注册的 ndo_start_xmit 函数之前。

TSO (TCP Segmentation Offload): 是一种利用网卡来对大数据包进行自动分段，降低 CPU 负载的技术。 其主要是延迟分段。通过硬件（网卡）实现。

GSO (Generic Segmentation Offload): GSO 是协议栈是否推迟分段，在发送到网卡之前判断网卡是否支持 TSO，如果网卡支持 TSO 则让网卡分段，否则协议栈分完段再交给驱动。 如果 TSO 开启，GSO 会自动开启。 GSO 通过软件来实现。

以下是 TSO 和 GSO 的组合关系：

1. GSO 开启， TSO 开启：协议栈推迟分段，并直接传递大数据包到网卡，让网卡自动分段
2. GSO 开启， TSO 关闭：协议栈推迟分段，在最后发送到网卡前才执行分段
3. GSO 关闭， TSO 开启：同 GSO 开启， TSO 开启
4. GSO 关闭， TSO 关闭：不推迟分段，在 tcp_sendmsg 中直接发送 MSS 大小的数据包

| TSO  | GSO  | 分片阶段          |
| ---- | ---- | ----------------- |
| off  | on   | GSO、网卡驱动阶段 |
| on   | on   | TSO、网卡硬件阶段 |

## LRO

LRO（Large Receive Offload）

LRO 是一种由网卡卸载数据包重组的技术。在传统的方式中，当网络接收到多个小的数据包时，操作系统需要对这些小的数据包进行重组，这会增加 CPU 的负担。而使用 LRO 技术，网卡可以将多个小的数据包重组成一个大的数据包，而不需要 CPU 的介入。这可以提高网络性能并减少 CPU 的负担。
LRO 针对 TCP 在接收端网卡的组包。

## GRO

| LRO  | GRO  | 阶段         |
| ---- | ---- | ------------ |
| off  | off  | TCP 阶段     |
| on   | off  | 网卡硬件阶段 |
| off  | on   | 网卡驱动阶段 |

## 其他

TCP fragmentation (TCP 分段)指的是，当 TCP 数据包的长度超过网络 MTU（最大传输单元）时，TCP 层会将数据包分割成多个小的片段，以便在网络中传输。这些片段被称为 TCP 分段，它们在发送端进行分段，并在接收端进行重组。

## 管理网卡 TSO 和 GSO

查看 TSO 和 GSO 是否开启

```bash
ethtool -k eth0

# generic-segmentation-offload: on
# tcp-segmentation-offload: on
```

开启使用命令

```bash
ethtool -K eth0 tso on gso on
```

关闭则使用

```bash
ethtool -K eth0 tso off gso off
```

## 参考资料

- <https://pyer.dev/post/tcp-segmentation-offload-introduction-and-operation-2f0b8949>

- <https://luckymrwang.github.io/2022/07/27/SmartNIC-%E2%80%94-TSO%E3%80%81GSO%E3%80%81LRO%E3%80%81GRO-%E6%8A%80%E6%9C%AF/>
- <http://blog.leanote.com/post/heming/%E7%BD%91%E5%8D%A1%E7%9B%B8%E5%85%B3%E8%AE%BE%E7%BD%AE>

- <https://www.cnblogs.com/edisonfish/p/17509737.html>
- <https://blog.csdn.net/Rong_Toa/article/details/109109209>
