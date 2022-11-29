## RDMA 简介

RDMA 提供两个计算机的主要内存访问，而无需涉及操作系统、缓存或存储。使用 RDMA，带有高吞吐量、低延迟和 CPU 使用率的数据传输。

在典型的 IP 数据传输中，当一个计算机上的应用程序向另一台机器上的应用程序发送数据时，接收终止时会出现以下操作：

- 内核必须接收数据。
- 内核必须确定该数据是否属于该应用程序。
- 内核唤醒应用程序。
- 内核会等待应用程序执行系统调用到内核。
- 应用程序将内核的内部内存空间中的数据复制到应用程序提供的缓冲中。

此过程意味着，如果主机适配器使用直接内存访问(DMA)或者至少两次，则大多数网络流量会被复制到系统的主内存中。另外，计算机执行一些上下文切换以在内核和应用程序间切换。这些上下文切换可能会导致 CPU 负载高，但会降低其他任务的速度。

与传统的 IP 通信不同，RDMA 通信会绕过通信过程中的内核干预。这可减少 CPU 开销。RDMA 协议可让主机适配器在数据包进入网络后决定应用程序应该接收的网络以及将其保存到应用程序的内存空间中。主机适配器不将处理发送到内核并将其复制到用户应用程序的内存中，主机适配器直接在应用程序缓冲中放置数据包内容。此过程需要单独的 API、InfiniBand Verbs API 和应用程序需要实施 InfiniBand Verbs API 来使用 RDMA。

## 容损网络 vs 无损网络

容损网络：Chelsio 公司主导的 iWarp

无损网络：Mellanox 公司主导的 InfiniBand,  RoCE

![rdma-net.png](.assets/rdma-net.png)

参考文档：<https://www.cnblogs.com/longbowchi/p/14802046.html>

- iWARP

互联网区 RDMA 协议(iWARP)：通过 IP 网络实现 RDMA 的网络协议

- RoCE

RDMA over Converged Ethernet(RoCE)，也称为 InfiniBand over Ethernet(IBoE)：实现通过以太网网络实施 RDMA 的网络协议
