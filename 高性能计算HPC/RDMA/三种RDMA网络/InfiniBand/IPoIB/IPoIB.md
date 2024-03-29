InfiniBand 不使用 IP 进行通信。但是，IP over InfiniBand(IPoIB) 在 InfiniBand 远程直接访问 (RDMA) 网络之上提供一个 IP 网络模拟层。这允许现有未经修改的应用程序通过 InfiniBand 网络传输数据，但性能低于应用程序原生使用 RDMA 时的数据。

## IPoIB 通讯模式

IPoIB 设备可在 `Datagram` 或 `Connected` 模式中配置。区别在于 IPoIB 层试图在通信的另一端机器打开的队列对类型：

- 在 `Datagram` 模式中，系统会打开一个不可靠、断开连接的队列对。

  这个模式不支持大于 InfiniBand 链路层的最大传输单元(MTU)的软件包。在传输数据时，IPoIB 层在 IP 数据包之上添加了一个 4 字节 IPoIB 标头。因此，IPoIB MTU 比 InfiniBand link-layer MTU 小 4 字节。因为 `2048` 是一个常见的 InfiniBand 链路层 MTU，`Datagram` 模式中的通用 IPoIB 设备 MTU 为 `2044`。

- 在 `Connected` 模式中，系统会打开一个可靠、连接的队列对。

  这个模式允许消息大于 InfiniBand link-layer MTU。主机适配器处理数据包分段和重新装配。因此，在 `Connected` 模式中，从 Infiniband 适配器发送的消息没有大小限制。但是，由于 `data` 字段和 TCP/IP `标头字段` 导致 IP 数据包有限。因此，`Connected` 模式中的 IPoIB MTU 是 `65520` 字节。

  `连接` 模式的性能更高，但会消耗更多内核内存。

虽然将系统配置为使用连接模式，但系统仍然使用 `Datagram` 模式发送多播流量，因为 InfiniBand 交换机和光纤无法在 `连接` 模式中传递多播流量。另外，当主机没有配置为使用 连接 模式时，系统会返回 `Datagram` 模式。

在运行应用程序时，将多播数据发送到接口中的 MTU 时，使用 `Datagram` 模式配置接口，或将应用配置为以以数据报报数据包中的发送大小上限。

## IPoIB 硬件地址

ipoIB 设备有 `20` 字节硬件地址，它由以下部分组成：

- 前 4 字节是标志和队列对号

- 下一个 8 字节是子网前缀

  默认子网前缀为 `0xfe:80:00:00:00:00:00:00`。设备连接到子网管理器后，设备会更改此前缀以匹配配置的子网管理器。

- 最后一个 8 字节是 InfiniBand 端口的全球唯一标识符(GUID)，附加到 IPoIB 设备

## 使用命令行工具 nmcli 配置

开启内核模块

```bash
modprobe ib_ipoib
```

创建 InfiniBand 连接，在 `Connected` 传输模式中使用 `ib0` 接口，以及最大 MTU `65520` 字节：

```bash
nmcli connection add type infiniband con-name ib0 ifname ib0 transport-mode Connected mtu 65520
```

还可以将 `0x8002` 设置为 `mlx4_ib0` 连接的 `P_Key` 接口：

```bash
# nmcli connection modify ib0 infiniband.p-key 0x8002
```

要配置 IPv4 设置，设置 `ib0` 连接的静态 IPv4 地址、网络掩码、默认网关和 DNS 服务器：

```
nmcli connection modify ib0 ipv4.addresses 10.245.245.101/24
# nmcli connection modify ib0 ipv4.gateway 10.244.245.254
# nmcli connection modify ib0 ipv4.dns 10.244.245.253
# nmcli connection modify ib0 ipv4.method manual
```
