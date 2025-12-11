## 问题复现

使用 UDP 查询

```bash
nslookup kubernetes.default.svc.cluster.local  10.96.0.10
```

抓包结果如下


```bash
# tcpdump -vv -i vxlan.calico port 53

master02.xc.test..28565 > 100.78.115.61.domain: [bad udp cksum 0xc067 -> 0xf612!] 6039+ A? kubernetes.default.svc.cluster.local. (54)
17:44:04.516502 IP (tos 0x0, ttl 63, id 57450, offset 0, flags [none], proto UDP (17), length 82)
    master02.xc.test..28565 > 100.78.115.61.domain: [bad udp cksum 0xc067 -> 0xf612!] 6039+ A? kubernetes.default.svc.cluster.local. (54)
17:44:09.517487 IP (tos 0x0, ttl 63, id 58352, offset 0, flags [none], proto UDP (17), length 82)
    master02.xc.test..28565 > 100.78.115.61.domain: [bad udp cksum 0xc067 -> 0xf612!] 6039+ A? kubernetes.default.svc.cluster.local. (54)


```

使用 TCP 查询

```bash
nslookup -vc kubernetes.default.svc.cluster.local  10.96.0.10
```

抓包结果如下

```bash
# tcpdump -vv -i vxlan.calico port 53
tcpdump: listening on vxlan.calico, link-type EN10MB (Ethernet), capture size 262144 bytes
17:46:04.529606 IP (tos 0x0, ttl 63, id 26799, offset 0, flags [DF], proto TCP (6), length 60)
    master02.xc.test..40627 > 100.95.31.182.domain: Flags [S], cksum 0x6cd0 (incorrect -> 0xbd48), seq 1268752456, win 65495, options [mss 65495,sackOK,TS val 4278819391 ecr 0,nop,wscale 7], length 0
17:46:05.588442 IP (tos 0x0, ttl 63, id 26800, offset 0, flags [DF], proto TCP (6), length 60)
    master02.xc.b
```

解决方案如下：

```bash
ethtool --offload vxlan.calico rx off tx off
# OR
ethtool -K vxlan.calico tx-checksum-ip-generic off
# OR
route add 10.96.0.0/16 vxlan.calico
# OR
iptables -t nat -D POSTROUTING -m comment --comment "kubernetes postrouting rules" -j KUBE-POSTROUTING
    # -t nat：指定要操作的表，这里是NAT表。
    # -D POSTROUTING：删除一个规则。POSTROUTING是链的名称。
    # -m comment：使用额外的模块comment，它允许你对规则添加注释。
    # --comment "kubernetes postrouting rules"：规则的注释是"kubernetes postrouting rules"。
    # -j KUBE-POSTROUTING：如果规则匹配，跳转到KUBE-POSTROUTING链。
# OR
iptables -t nat -I POSTROUTING 1 -o eth0 -j ACCEPT
# OR
iptables -t nat -I KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -m mark --mark 0x4000/0x4000 -j MASQUERADE
```

参考链接

- <https://github.com/kubernetes/kubernetes/issues/88986>
- <https://github.com/projectcalico/calico/issues/3145>
- <https://github.com/projectcalico/calico/issues/4865>
- <https://github.com/coreos/flannel/issues/1243>
- <https://github.com/flannel-io/flannel/issues/1279>
- <https://github.com/rancher/rke2/issues/1541>
- <https://github.com/kubernetes-sigs/kubespray/issues/8992>
- <https://docs.rancher.cn/docs/rke2/known_issues/_index/#calico-%E4%B8%8E-vxlan-%E5%B0%81%E8%A3%85>
- <https://lyyao09.github.io/2022/03/19/k8s/K8S%E9%97%AE%E9%A2%98%E6%8E%92%E6%9F%A5-Calico%E7%9A%84Vxlan%E6%A8%A1%E5%BC%8F%E4%B8%8B%E8%8A%82%E7%82%B9%E5%8F%91%E8%B5%B7K8s%20Service%E8%AF%B7%E6%B1%82%E5%BB%B6%E8%BF%9F/>

通过 tcpdump 抓包发现是因为 checksum 错误导致对端拒收了数据包。

修复版本 k8s 1.19：<https://github.com/kubernetes/kubernetes/pull/92035>

```bash
Fixes a problem with 63-second or 1-second connection delays with some VXLAN-based
network plugins which was first widely noticed in 1.16 (though some users saw it
earlier than that, possibly only with specific network plugins). If you were previously
using ethtool to disable checksum offload on your primary network interface, you should
now be able to stop doing that.
```

升级`calico >=v3.20.0`或升级内核到`5.6.13, 5.4.41, 4.19.123, 4.14.181`，单独升级`K8S >= v1.18.5`版本待确认是否能解决

## 根因分析

### checksum

所谓 Checksum 是一个固定长度的字段，网络协议使用该字段来纠正某些传输错误。

Checksum 通常是基于某些报文字段来计算摘要信息，算法决定了 Checksum 的可靠性和计算成本。IP 协议仅仅使用报文头，而大部分 L4 协议，同时使用报文头、报文体。

在 IPv4（IPV6 没有 IP Checksum）中，IP Checksum 是 16bit 字段，信息来自 IP 头所有字段。在任一跳发现 Checksum 错误，都会导致静默的丢弃，而不产生 ICMP 报文 —— L4 协议需要考虑这种静默丢弃的可能并进行相应处理，例如 TCP 在 ACK 没有及时收到时会进行重传。

IP 数据报在经过每一跳时，都需要更新 Checksum，至少 TTL 的变化需要重新计算 Checksum。除了 TTL，IP 头还可能因为以下原因变化：

1. NAT 导致的地址变化
2. IP 选项处理
3. IP 分片

计算 IP Checksum 时，报文被分隔为 16bit 的小段，将这些小段相加并取反（ones-complemented），就得到最后的 Checksum。在 Linux 中，可能分隔为 32bit 甚至 64bit 的小段，以提升计算速度，但是取反操作前需要一个额外的折叠（csum_fold）操作。

由于 IP Checksum 仅仅牵涉到报文头，成本很低，Linux 总是在 CPU 中进行计算，不会 Offload 给硬件。

L4 协议的 Checksum 牵涉完整报文，包括 L4 报文头、L4 报文体、以及所谓的伪头（pseudoheader）。伪头其实就是 IP 头中的源地址、目的地址、以及之后的 32bit。

IP 层在 NAT 等场景下，需要对 IP 头进行变更，这会导致 L4 协议计算的 Checksum 失效。如果没有更新失效的 Checksum，则在 IP 报文传输的每一跳都不会发现错误，因为中间路由仅仅会校验 IP Checksum。结果就是，只有目的地内核才能在 L4 发现这一情况。我们可以了解到 Checksum 算法具有可逆性，因此 NAT 这样导致很少字段变化的情况下，更新 Checksum 不需要从头计算。

### Offloading

前面提到过，L4 的 Checksum 计算涉及完整报文，成本较高。因此 Linux 支持将 L4 的 Checksum 委托给硬件完成，这就是 Checksum Offloading。

设备能否支持 Checksum Offloading，是通过 net_device->features 标记传递给内核的：

1. NETIF_F_HW_CSUM 驱动能够为任何协议组合、协议层计算 IP Checksum
2. NETIF_F_IP_CSUM 驱动支持 L4（仅限于 TCP/UDP over IPv4）的 Checksum 计算
3. NETIF_F_IPV6_CSUM 驱动支持 L4（仅限于 TCP/UDP over IPv6）的 Checksum 计算
4. NETIF_F_NO_CSUM 表示设备明确知道不需要计算 Checksum，通常用于 loopback 设备
5. NETIF_F_RXCSUM 驱动进行接收封包的 Checksum Offloading，仅仅用于禁用设备的 RX Checksum

skb->ip_summed 字段存放了 Checksum 的状态，其含义在接收封包、发送封包期间有所不同。

在接收封包期间：

1. CHECKSUM_NONE 提示设备没有对封包进行 Checksum 校验，可能由于缺少相关特性
2. CHECKSUM_UNNECESSARY 提示内核不再需要对 Checksum 进行校验
3. CHECKSUM_COMPLETE 提示设备已经提供了完整的 L4 Checksum，L4 代码只需要加上伪头即可进行校验

在发送封包期间：

1. CHECKSUM_NONE 提示内核已经完全处理好 Checksum 了，设备不需要做任何事情
2. CHECKSUM_UNNECESSARY 意义和 CHECKSUM_NONE 相同
3. CHECKSUM_PARTIAL 提示内核已经完成伪头部分的 Checksum，驱动必须计算从 skb->csum_start 到封包结尾部分的 Checksum，并且将其存放在 skb->csum_start + skb->csum_offset 这个位置
4. CHECKSUM_COMPLETE 不使用

可以看到，在发送封包时，如果 skb->ip_summed 的值为 CHECKSUM_PARTIAL，则意味着内核要求驱动 Checksum Offloading。

### 内核缺陷

基于上面的认识，牵涉到的内核缺陷：

```
static bool
udp_manip_pkt(struct sk_buff *skb,  // 当前操控的套接字缓冲
          const struct nf_nat_l3proto *l3proto,  // 持有NAT操作相关的若干函数指针
          unsigned int iphdroff, unsigned int hdroff,  // IP头、L4头的偏移量
          const struct nf_conntrack_tuple *tuple,  // 连接跟踪相关的信息，新旧IP端口
          enum nf_nat_manip_type maniptype)  // 是SNAT还是DNAT
{
    struct udphdr *hdr;
    __be16 *portptr, newport;
  
    if (!skb_make_writable(skb, hdroff + sizeof(*hdr)))
        return false;
  
    // 获得UDP头
    hdr = (struct udphdr *)(skb->data + hdroff);
  
    if (maniptype == NF_NAT_MANIP_SRC) {
        // NAT后的源端口
        newport = tuple->src.u.udp.port;
        // NAT前的源端口
        portptr = &hdr->source;
    } else {
        /* Get rid of dst port */
        newport = tuple->dst.u.udp.port;
        portptr = &hdr->dest;
    }
    // 如果Checksum不为零， 或者 开启了Offloading，则更新Checksum
    if (hdr->check || skb->ip_summed == CHECKSUM_PARTIAL) {
  
        //       这里调用的是 nf_nat_ipv4_csum_update
        l3proto->csum_update(skb, iphdroff, &hdr->check,
                     tuple, maniptype);
        inet_proto_csum_replace2(&hdr->check, skb, *portptr, newport,
                     0);
        if (!hdr->check)
            hdr->check = CSUM_MANGLED_0;
    }
    *portptr = newport;
    return true;
}
  
static void nf_nat_ipv4_csum_update(struct sk_buff *skb,
                    unsigned int iphdroff, __sum16 *check,
                    const struct nf_conntrack_tuple *t,
                    enum nf_nat_manip_type maniptype)
{
    struct iphdr *iph = (struct iphdr *)(skb->data + iphdroff);
    __be32 oldip, newip;
  
    if (maniptype == NF_NAT_MANIP_SRC) {
        oldip = iph->saddr;
        newip = t->src.u3.ip;
    } else {
        oldip = iph->daddr;
        newip = t->dst.u3.ip;
    }
    // 这里传入了无效的Checksum
    inet_proto_csum_replace4(check, skb, oldip, newip, 1);
}
  
void inet_proto_csum_replace4(__sum16 *sum, struct sk_buff *skb,
                  __be32 from, __be32 to, int pseudohdr)
{
    __be32 diff[] = { ~from, to };
    if (skb->ip_summed != CHECKSUM_PARTIAL) {
        *sum = csum_fold(csum_partial(diff, sizeof(diff),
                ~csum_unfold(*sum)));
        if (skb->ip_summed == CHECKSUM_COMPLETE && pseudohdr)
            skb->csum = ~csum_partial(diff, sizeof(diff),
                        ~skb->csum);
    } else if (pseudohdr)
        // 走这个分支，可以看到，更新Checksum依赖于先前的Checksum是正确值
        *sum = ~csum_fold(csum_partial(diff, sizeof(diff), csum_unfold(*sum)));
}
```

当 VXLAN 端点的 UDP 被 NAT 的情况下，上述代码会执行。如果 VXLAN 设备禁用了 UDP Checksum，它会将 udphdr->check 置零。如果同时 VXLAN 设备还启用了 Tx Checksum Offloading，skb->ip_summed 的值就会是 CHECKSUM_PARTIAL。

UDP Checksum 被禁用情况下，udphdr->check 是个零值，显然没有包含旧的伪头的 Checksum 信息，因为通过伪头计算的 Checksum，至少协议类型部分（UDP 0x11）是非零。

因此，判断是否需要更新 Checksum，应当只根据 VXLAN 接口是否禁用了 UDP Checksum，禁用了就不应该更新。

### Calico VXLan

通过 tcpdump 抓包发现是因为 checksum 错误导致对端拒收了数据包 。

过程：在被 VXLAN 封装后依然会被打上这个 mark，导致再次进入 MASQUERADE。

设置日志标记

```
iptables -t nat -I KUBE-POSTROUTING 1 -j LOG --log-prefix "0x4000-marked: " -m mark --mark 0x4000/0x4000
```

进行调试

```
dmesg -wH |grep "marked"
```

使用问题复现中的进行，可看到从主机发出的包被 SNAT 了一次

SNAT 规则

```
-A KUBE-POSTROUTING -m comment --comment "Kubernetes endpoints dst ip:port, source ip for solving hairpin purpose" -m set --match-set KUBE-LOOP-BACK dst,dst,src -j MASQUERADE
-A KUBE-POSTROUTING -m mark ! --mark 0x4000/0x4000 -j RETURN
-A KUBE-POSTROUTING -j MARK --set-xmark 0x4000/0x0
-A KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -j MASQUERADE --random-fully
```

