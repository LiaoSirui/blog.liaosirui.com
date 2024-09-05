## bonding

`bonding` 是一个 linux kernel 的 driver，加载了它以后，linux 支持将多个物理网卡捆绑成一个虚拟的 bond 网卡

```bash
# lsmod | grep bond
bonding               155648  0

```

利用 bonding 技术与交换机的端口动态聚合实现双网口的绑定

bond 模式

| mode   | 别名               | 描述                                                         |
| ------ | ------------------ | ------------------------------------------------------------ |
| mode=0 | mode=balance-rr    | 平衡抡循环策略，传输数据包顺序是依次传输，此模式提供负载平衡和容错能力 |
| mode=1 | mode=active-backup | 主 - 备份策略，只有一个设备处于活动状态，当一个宕掉另一个马上由备份转换为主设备，其中一条线若断线，其他线路将会自动备援 |
| mode=2 | mode=balance-xor   | 平衡策略，基于指定的传输 HASH 策略传输数据包。缺省的策略是：(源 MAC 地址 XOR 目标 MAC 地址)% slave 数量。传输策略可以通过 xmit_hash_policy 选项指定 |
| mode=3 | mode=broadcast     | 广播策略，在每个 slave 接口上传输每个数据包，此模式提供了容错能力 |
| mode=4 | mode=802.3ad       | IEEE802.3ad 动态链接聚合（LACP）。xmit_hash_policy 选项从缺省的 XOR 策略改变到其他策略。交换机支持 IEEE 802.3ad 动态链路聚合，及开启 LACP 功能 |
| mode=5 | mode=balance-tlb   | 适配器传输负载均衡。不需要交换机支持                         |
| mode=6 | mode=balance-alb   | 适配器适应性负载均衡                                         |

注： 除了 `balance-rr` 模式外的其它 bonding 负载均衡模式一样，任何连接都不能使用多于一个接口的带宽

## RDMA 网卡

RoCE LAG 是一种用于模拟 IB 设备的以太网绑定的功能，仅适用于双端口卡。部分网卡支持一下 3 种模式

- active-backup (mode 1)
- balance-xor (mode 2)
- 802.3ad (LACP) (mode 4)

> 在 mode4 模式下，进行数据传输的始终只有一个端口，带宽与一个端口传输一样，但是将其中任意一个端口拔掉后，数据传输切换到另一个端口，实际业务不受影响。也是一种主备模式，在 IB 模式下只支持主备模式