## GSO 简介

GSO（ Generic Segmentation Offload ），另外还有 GRO

由于 MTU 的限制，所以对于 UDP 的写入，如果写入的数据超过 MTU 大小，且没有禁用 IP 分片，那么将会被进行 IP 分片，但是 IP 分片是不利于做可靠传输协议的，因为丢包成本太高了，丢一个 IP 包就等于丢了所有。前面提到减少系统调用，如果使用 GSO 的话也是可以的，可以一次写入更大的 buffer 来达到减少系统调用的目的，不过这个有个前提是每次需要写入的数据足够大，且对内核版本要求较高。

另外 GSO 除了可以一次写入较大 buffer ，在支持的 GSO offload 的网卡还有相应的硬件加速，可以通过`ethtool -K eth0 tx-udp-segmentation on`来开启。

GSO 可以通过两种方式去使用，一种是设置 socket option 开启，一种是通过 oob 去对 msg 级别设置。 一般通过 oob 的方式去进行设置，因为这样比较灵活一些，缺点的话就是会多 copy 一点内存。

## TSO

TSO（TCP Segmentation Offload）

## LRO

LRO（Large Receive Offload）

## 其他

TCP fragmentation (TCP 分段)指的是，当 TCP 数据包的长度超过网络 MTU（最大传输单元）时，TCP 层会将数据包分割成多个小的片段，以便在网络中传输。这些片段被称为 TCP 分段，它们在发送端进行分段，并在接收端进行重组。

## 管理网卡 TSO 和 GSO

查看 TSO 和 GSO 是否开启

```bash
ethtool -k eth0

# generic-segmentation-offload: on
# tx-tcp-mangleid-segmentation: on
```

开启使用命令

```bash
ethtool -K eth0 tso on gso on
```

关闭则使用

```bash
ethtool -K eth0 tso off gso off
```

