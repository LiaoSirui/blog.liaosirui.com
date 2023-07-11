访问 NodePort 类型的 Service 时，出现延迟

## 分析

### 内层封包

在 10.0.0.11 向 localhost:30153 发起请求，并且抓取卡住时的封包：

```bash
# 经过 iptables 时，DNAT 为 POD_IP:9153，SNAT 为宿主机 eth0 地址
curl http://127.0.0.1:30153
 
tcpdump -ttttt -nn -vvv -i any 'tcp port 9153'
 
# 请求端
# SYN 0
 00:00:00.000000 IP (tos 0x0, ttl 64, id 42199, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5a6c (incorrect -> 0xd480), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19658463 ecr 0,nop,wscale 9], length 0
# SYN 1
 00:00:01.000549 IP (tos 0x0, ttl 64, id 42200, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5a6c (incorrect -> 0xd097), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19659464 ecr 0,nop,wscale 9], length 0
# SYN 2
 00:00:03.005510 IP (tos 0x0, ttl 64, id 42201, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5a6c (incorrect -> 0xc8c2), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19661469 ecr 0,nop,wscale 9], length 0
# SYN 3
 00:00:07.008579 IP (tos 0x0, ttl 64, id 42202, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5a6c (incorrect -> 0xb91f), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19665472 ecr 0,nop,wscale 9], length 0
# SYN 4
 00:00:15.024516 IP (tos 0x0, ttl 64, id 42203, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5a6c (incorrect -> 0x99cf), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19673488 ecr 0,nop,wscale 9], length 0
# SYN 5
 00:00:31.072562 IP (tos 0x0, ttl 64, id 42204, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5a6c (incorrect -> 0x5b1f), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19689536 ecr 0,nop,wscale 9], length 0
# SYN 6   63秒
 00:01:03.136526 IP (tos 0x0, ttl 64, id 42205, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5a6c (incorrect -> 0xddde), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19721600 ecr 0,nop,wscale 9], length 0
# SYN+ACK 通讯建立
 00:01:03.137188 IP (tos 0x0, ttl 63, id 0, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.2.3.9153 > 172.29.0.0.40233: Flags [S.], cksum 0xbdbe (correct), seq 4208932479, ack 1769165321, win 27960, options [mss 1410,sackOK,TS val 19735883 ecr 19721600,nop,wscale 9], length 0
 
 
# 服务端
 
# 这个报文在63秒后才收到
# SYN 6
 00:00:00.000000 IP (tos 0x0, ttl 64, id 42205, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xddde (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19721600 ecr 0,nop,wscale 9], length 0
 00:00:00.000025 IP (tos 0x0, ttl 63, id 42205, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xddde (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19721600 ecr 0,nop,wscale 9], length 0
 00:00:00.000065 IP (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.2.3.9153 > 172.29.0.0.40233: Flags [S.], cksum 0x5a6c (incorrect -> 0xbdbe), seq 4208932479, ack 1769165321, win 27960, options [mss 1410,sackOK,TS val 19735883 ecr 19721600,nop,wscale 9], length 0

```

可以注意到：

1. 当 Service 负载均衡到本机的 Pod 时畅通，负载均衡到其它节点的 Pod 时卡住。这就是 50% 卡住的原因
2. 并非彻底卡死，在 63 秒后，SYN 成功

### iptables规则

从上面的抓包结果分析，初步判断故障和 iptables 没有关系。iptables 导致的问题可能是无限卡死直到超时（静默的丢弃了报文）、ICMP 错误、TCP RST 等，通常不会出现过了一段时间自动恢复的情况。

然后，这个故障很特别，它的确是由 iptables 规则所触发的。其中 PREROUTING 阶段的规则如下

```bash
# iptables -L -n -v -t nat
 
Chain PREROUTING (policy ACCEPT 1 packets, 60 bytes)
 pkts bytes target                prot opt in  out  source     destination         
# 所有封包都要这经过这个链
# kubernetes service portals
46185 2817K KUBE-SERVICES         all  --  *   *    0.0.0.0/0  0.0.0.0/0            
 
Chain KUBE-SERVICES (2 references)
 pkts bytes target                prot opt in  out  source      destination         
# 这些会匹配 ClusterIP，和本场景无关
# kube-system/kube-dns:metrics cluster IP 
# 0  0 KUBE-SVC-JD5MR3NA4I4DYORP  tcp  --  *  *     0.0.0.0/0  172.29.255.10  tcp dpt:9153
#kube-system/kube-dns-nodeport:metrics cluster IP                   
# 0  0 KUBE-SVC-CZA6AQQ7F4S64XIF  tcp  --  *  *     0.0.0.0/0  172.29.255.56  tcp dpt:9153
# default/kubernetes:https cluster IP                             
# 0  0 KUBE-SVC-NPX46M4PTMTKRN6Y  tcp  --  *  *     0.0.0.0/0  172.29.255.1   tcp dpt:443
# kube-system/kube-dns:dns cluster IP                           
# 0  0 KUBE-SVC-TCOU7JCQXEZGVUNU  udp  --  *  *     0.0.0.0/0  172.29.255.10  udp dpt:53
#kube-system/kube-dns:dns-tcp cluster IP                         
# 0  0 KUBE-SVC-ERIFXISQEP7F7OF4  tcp  --  *  *     0.0.0.0/0  172.29.255.10  tcp dpt:53
# 不是访问 ClusterIP 的、目的地址是本机绑定地址的封包，都要经过这个链
# kubernetes service nodeports; NOTE: this must be the last rule in this chain 
  678 40680 KUBE-NODEPORTS        all  --  *  *     0.0.0.0/0  0.0.0.0/0  ADDRTYPE match dst-type LOCAL
 
 
Chain KUBE-NODEPORTS (1 references)
 pkts bytes target                prot opt in out   source     destination         
# 匹配本场景（目标端口30153），会给封包打标记，因此不会终止规则链遍历
# kube-system/kube-dns-nodeport:metrics 
    0     0 KUBE-MARK-MASQ        tcp  --  *  *     0.0.0.0/0  0.0.0.0/0  tcp dpt:30153
# 匹配本场景（目标端口30153），跳转到NodePort的目标服务的专属规则链
# kube-system/kube-dns-nodeport:metrics 
    0     0 KUBE-SVC-CZAXXX       tcp  --  *  *     0.0.0.0/0  0.0.0.0/0  tcp dpt:30153
 
 
Chain KUBE-MARK-MASQ (8 references)
 pkts bytes target                prot opt in out   source     destination         
# 封包会被打上 0x4000标记
    0     0 MARK                  all  --  *  *     0.0.0.0/0  0.0.0.0/0  MARK or 0x4000
 
 
# 这个是 NodePort 的目标服务的专属规则链，随机转发给某个服务端点
Chain KUBE-SVC-CZAXXX (2 references)
 pkts bytes target                prot opt in out   source     destination    
# kube-system/kube-dns-nodeport:metrics     
    0     0 KUBE-SEP-DZXXXX       all  --  *  *     0.0.0.0/0  0.0.0.0/0  statistic mode random probability 0.50000000000
# kube-system/kube-dns-nodeport:metrics 
    0     0 KUBE-SEP-COSXXX       all  --  *  *     0.0.0.0/0  0.0.0.0/0           
 
 
# 这是 NodePort 服务的某个端点的专属规则链
Chain KUBE-SEP-DZXXXX (1 references)
 pkts bytes target                prot opt in out   source     destination         
# kube-system/kube-dns-nodeport:metrics
    0     0 KUBE-MARK-MASQ        all  --  *  *     172.29.2.3 0.0.0.0/0            
# 匹配本场景，进行 DNAT，将目的地址从本机地址转为服务端点地址，如果端点不在本机，报文会从 flannel.1 接口发出
# kube-system/kube-dns-nodeport:metrics 
    0     0 DNAT                  tcp  --  *  *     0.0.0.0/0  0.0.0.0/0  tcp to:172.29.2.3:9153
```

我们可以看到，如果服务端点不在本机，发往 localhost:30153 的封包，会被先打上 `0x4000` 标记，然后 DNAT 到服务端点的 IP:PORT（例如 172.29.2.3:9153），这会保证封包从 flannel.1 发出。

POSTROUTING 阶段的规则如下：

```bash
Chain POSTROUTING (policy ACCEPT 2 packets, 120 bytes)
pkts bytes target   prot opt in  out  source     destination         
# kubernetes postrouting rules
83159 5015K KUBE-POSTROUTING all  --  *   *    0.0.0.0/0  0.0.0.0/0            
 
Chain KUBE-POSTROUTING (1 references)
pkts bytes target prot opt in out source destination   
# kubernetes service traffic requiring SNAT      
0   0 MASQUERADE  all  --  *  *  0.0.0.0/0 0.0.0.0/0  mark match 0x4000/0x4000 random-fully
```

可以看到，这里做了 SNAT，任何具有 0x4000 标记的封包，都被 SNAT，确保使用 flannel.1 的地址作为源 IP。

### 63 秒现象

经过反复测试， 发现卡住时，总是会消耗 63 秒左右，然后接收到响应。

63 秒这个数字，和 TCP 默认的 SYN 重试机制有关。SYN 如果没有收到 ACK，发送端会自动重发 SYN，每次重试的延迟时间指数增长，依次为 1, 2, 4, 8, 16, 32，这会引发合计 63 秒的总延迟。

令人费解的是，为什么 63 秒之后，不是超时，而是连接成功

### 外层封包

从上文抓取的 TCP 封包看，服务端的 Pod 网卡没有收到前面 6 次 SYN，这些封包应该在链路的某个位置被丢弃了。

在 VXLAN 模式下，上面抓的 TCP 封包，会封装在 UDP 报文中，并通过节点物理网卡的 8472 端口发出。我们从外层报文的角度分析一下

```bash
# tcpdump -ttttt -n -v -i eth0 'udp port 8472'
# 畅通时，没有输出，因为访问本机的Pod时不走VXLAN
 
# 卡住时，请求端封包
 00:00:00.000000 IP (tos 0x0, ttl 64, id 43516, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42199, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xd480 (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19658463 ecr 0,nop,wscale 9], length 0
 00:00:01.000542 IP (tos 0x0, ttl 64, id 44011, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42200, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xd097 (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19659464 ecr 0,nop,wscale 9], length 0
 00:00:03.005505 IP (tos 0x0, ttl 64, id 45443, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42201, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xc8c2 (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19661469 ecr 0,nop,wscale 9], length 0
 00:00:07.008579 IP (tos 0x0, ttl 64, id 46574, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42202, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xb91f (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19665472 ecr 0,nop,wscale 9], length 0
 00:00:15.024518 IP (tos 0x0, ttl 64, id 50068, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42203, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x99cf (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19673488 ecr 0,nop,wscale 9], length 0
 00:00:31.072564 IP (tos 0x0, ttl 64, id 65085, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42204, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5b1f (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19689536 ecr 0,nop,wscale 9], length 0
 00:01:03.136538 IP (tos 0x0, ttl 64, id 19809, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.50024 > 10.0.0.13.8472: [no cksum] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42205, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xddde (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19721600 ecr 0,nop,wscale 9], length 0
 00:01:03.137105 IP (tos 0x0, ttl 64, id 63229, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.13.50017 > 10.0.0.11.8472: [no cksum] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 63, id 0, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.2.3.9153 > 172.29.0.0.40233: Flags [S.], cksum 0xbdbe (correct), seq 4208932479, ack 1769165321, win 27960, options [mss 1410,sackOK,TS val 19735883 ecr 19721600,nop,wscale 9], length 0
 
 
# 卡住时，服务端封包
# SYN 0
 00:00:00.000000 IP (tos 0x0, ttl 64, id 43516, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42199, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xd480 (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19658463 ecr 0,nop,wscale 9], length 0
# SYN 1
 00:00:01.000543 IP (tos 0x0, ttl 64, id 44011, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42200, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xd097 (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19659464 ecr 0,nop,wscale 9], length 0
# SYN 2
 00:00:03.005514 IP (tos 0x0, ttl 64, id 45443, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42201, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xc8c2 (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19661469 ecr 0,nop,wscale 9], length 0
# SYN 3
 00:00:07.008577 IP (tos 0x0, ttl 64, id 46574, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42202, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xb91f (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19665472 ecr 0,nop,wscale 9], length 0
# SYN 4
 00:00:15.024575 IP (tos 0x0, ttl 64, id 50068, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42203, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x99cf (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19673488 ecr 0,nop,wscale 9], length 0
# SYN 5
 00:00:31.072593 IP (tos 0x0, ttl 64, id 65085, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.60142 > 10.0.0.13.8472: [bad udp cksum 0xffff -> 0x4b80!] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42204, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0x5b1f (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19689536 ecr 0,nop,wscale 9], length 0
# SYN 6 63秒，可以看到这次没有UDP封包没有chksum了，服务端也收到SYN了
 00:01:03.136659 IP (tos 0x0, ttl 64, id 19809, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.11.50024 > 10.0.0.13.8472: [no cksum] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 64, id 42205, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.0.0.40233 > 172.29.2.3.9153: Flags [S], cksum 0xddde (correct), seq 1769165320, win 43690, options [mss 65495,sackOK,TS val 19721600 ecr 0,nop,wscale 9], length 0
 00:01:03.136830 IP (tos 0x0, ttl 64, id 63229, offset 0, flags [none], proto UDP (17), length 110)
    10.0.0.13.50017 > 10.0.0.11.8472: [no cksum] OTV, flags [I] (0x08), overlay 0, instance 1
IP (tos 0x0, ttl 63, id 0, offset 0, flags [DF], proto TCP (6), length 60)
    172.29.2.3.9153 > 172.29.0.0.40233: Flags [S.], cksum 0xbdbe (correct), seq 4208932479, ack 1769165321, win 27960, options [mss 1410,sackOK,TS val 19735883 ecr 19721600,nop,wscale 9], length 0
```

可以看到，请求端 / 服务端的 UDP 报文相互呼应， 至少可以说，请求端的全部报文都送到了服务端。

但是，前面 5 次重试的 UDP 报文都被标注了 bad udp cksum，最后一次 UDP 报文没有 chksum，连接成功建立。有理由怀疑，故障和 chksum 有关系。

通过查阅 [VXLAN 的 RFC](https://tools.ietf.org/html/rfc7348)，在 VXLAN Frame Format 一章中，关于 UDP 封包的 Checksum，具有如下说明：

> UDP Checksum 应该以零传递。接收端接收到零 Checksum 的 UDP 包后，它必须接受，用于解包（decapsulation）。但是，如果发送端的确提供了非零 Checksum，那么它必须是正确的、基于整个封包进行计算的 —— 包括 IP 头、UDP 头、VXLAN 头，以及最里层的 MAC 帧。接收端可以对非零 Checksum 进行校验，或者不去校验。但是，如果进行了校验，且校验结果不正确，则必须丢弃 UDP 封包

RFC 说的很明确，如果 Checksum 是错误的，并且进行了校验，则封包会被丢弃。带入我们的场景中，可以推测，服务端内核丢弃了那些 bad udp cksum 的封包，因而服务端的 Pod 网卡一直没有收到 SYN。

那么，Checksum 为什么会错了呢？根源应该在内核。

### 内核缺陷

现代操作系统都支持某些形式的 Network Offloading，将某些工作委托给网卡完成，从而减轻 CPU 的负担。从内核代码的演变情况来看，这种 Offloading 的种类越来越丰富。

Checksum 就可以 Offload 给网卡来完成，这样，IP、TCP 和 UDP 的 Checksum，会在报文即将从网络接口发送出去的时候进行计算。Offloading 需要内核的 TCP/IP 栈、设备驱动、硬件正确的配合才能完成。

通过查阅资料，了解到，内核中存在一个和 VXLAN 处理有关的缺陷，该缺陷会导致 Checksum Offloading 不能正确完成。这个缺陷仅仅在很边缘的场景下才会表现出来。

在 VXLAN 的 UDP 头被 NAT 过（见下文的二次 SNAT 问题）的前提下，如果：

1. VXLAN 设备禁用（这是 RFC 的建议）了 UDP Checksum
2. VXLAN 设备启用了 Tx Checksum Offloading

就会导致生成错误的 UDP Checksum。

### 二次 SNAT

前面提到内核缺陷必须在 VXLAN 的 UDP 封包被 NAT 时，才会触发。那么，在源、目标地址都是宿主机网段的情况下，为什么还对 UDP 封包进行 NAT 呢？

在上文的 iptables 分析中我们看到，访问 localhost:30153 的封包，会被：

1. DNAT 到服务端 Pod 的地址，这保证封包能够通过 flannel.1 发出
2. 打上 0x4000 标记，这个标记会在随后的 POSTROUTING 阶段，用于进行 SNAT。使用 flannel.1 的地址作为源地址

被 DNAT+SNAT 后的内层 TCP 报文，进入 flannel.1 接口，进而在内核的 VXLAN 驱动中处理，封装为 UDP 报文。需要注意，iptables 打标记，我们期望是针对内层报文的。然而，内层封包被 VXLAN 处理后包裹了外层 UDP，重新进入网络栈，内核自动将 0x4000 标记关联到外层 UDP 报文上，这导致了额外的一次 SNAT：

```bash
iptables -t nat -I  KUBE-POSTROUTING 1 -j LOG --log-prefix "0x4000-marked: " -m mark --mark 0x4000/0x4000
 
dmesg -wH
 
# 第一次NAT，针对内层报文，我们期望将127.0.0.1 SNAT为 flannel.1的地址
[  +3.851027] 0x4000-marked: IN= OUT=flannel.1 SRC=127.0.0.1 DST=172.29.2.3 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=44704 DF PROTO=TCP SPT=43326 DPT=9153 WINDOW=43690 RES=0x00 SYN URGP=0 MARK=0x4000 
# 第二次NAT，针对外层报文，我们并没有期望这次SNAT，因为源地址本来就是eth0的地址了
[  +0.000019] 0x4000-marked: IN= OUT=eth0 SRC=10.0.0.12 DST=10.0.0.11 LEN=110 TOS=0x00 PREC=0x00 TTL=64 ID=9697 PROTO=UDP SPT=60211 DPT=8472 LEN=90 MARK=0x4000 
```

在 Kubernetes 1.16.0 之前的版本，Kube Proxy 做 SNAT（ -j MASQUERADE）时，没有使用 `--random-fully` 参数。这意味着第二次 SNAT 不会有任何效果，因为内核会在 Masquerading 时尝试保持源端口不变，与此同时，源端口已经是期望的地址了。

但是，使用了 `--random-fully` 参数后，情况变得不同。该参数会强制的进行随机的源端口映射。这就触发了上文提到的内核缺陷。

### random-fully

这是 SNAT 目标的一个参数，它会使用伪随机数生成器，自动产生一个端口，来替换 NAT 前的端口。根据文档，它需要内核 3.14+ 才能支持。

然而，我们用的是 CentOS 7，内核版本是 `3.10.0-1127.13.1.el7.x86_64`，照理说应该不支持这个特性。

在宿主机上，用 `iptables-save` 导出规则，也是看不到 `--random-fully` 的。但是，从 Kube Proxy 容器里面导出规则，却能看见：

```bash
# iptables-save | egrep '\-A\sKUBE-POSTROUTING'
-A KUBE-POSTROUTING  -m mark --mark 0x4000/0x4000 -j MASQUERADE
 
# kubectl -n kube-system exec kube-proxy-7qtzm -- iptables-save | egrep '\-A\sKUBE-POSTROUTING'
-A KUBE-POSTROUTING  -m mark --mark 0x4000/0x4000 -j MASQUERADE --random-fully
```

原因可能是两个iptables的版本不同。有一点可以明确，`--random-fully` 在我们的环境下的确产生了影响，因为禁用该参数后，问题就消失了。

## 解决方法

### 临时方案

（1）关闭 Offloading

既然故障的根源是内核中，和 Offloading 有关的缺陷，因此，禁用 Offloading 是最直接的手段：

```
ethtool --offload flannel.1 rx off tx off
```

这个命令执行的时机很重要，如果主机重启，Calico 创建网卡后，才能执行该命令，否则会提示找不到设备。

（2）防止二次 SNAT

有两种方式防止对 VXLAN 的 UDP 封包进行 SNAT。第一种是禁用 `--random-fully` 参数。

```bash
iptables -t nat -R KUBE-POSTROUTING 1 -m mark --mark 0x4000/0x4000 -j MASQUERADE
```

第二种，将发往 8472 端口的 UDP 封包，做一个重置标记的操作。Kubernetes社区就是这种做法。

```bash
iptables -A OUTPUT -p udp -m udp --dport 8472 -j MARK --set-mark 0x0 
```

### 永久方案

升级K8S版本

查看 Kubernetes v1.18.5 的Changelog，可以发现PR [92035](https://github.com/kubernetes/kubernetes/pull/92035)修复了这个故障。这个PR会在不需要0x4000标记时，将其清除。

在Kubelet初始化期间，会在NAT表创建KUBE-MARK-MASQ、KUBE-MARK-DROP、KUBE-POSTROUTING等链，并添加一些规则。该PR对这部分的逻辑进行了修改：

```go
func (kl *Kubelet) syncNetworkUtil() {
    // ...
    if _, err := kl.iptClient.EnsureRule(utiliptables.Append, utiliptables.TableNAT,
    // 这里将原先有缺陷的--set-xmark 0x4000/0x4000 改为 --xor-mark 
      KubeMarkMasqChain, "-j", "MARK", "--or-mark", masqueradeMark); err != nil {
        klog.Errorf("Failed to ensure marking rule for %v: %v", KubeMarkMasqChain, err)
        return
    }
    // ...
    // 这里是关键的修改，在KUBE-POSTROUTING中添加以下规则：
    // 如果封包没有0x4000标记位，则不做处理
    // iptables -t NAT -A KUBE-POSTROUTING -m mark ! --mark=0x4000/0x4000 -j RETRUN
    if _, err := kl.iptClient.EnsureRule(utiliptables.Append, utiliptables.TableNAT, KubePostroutingChain,
        "-m", "mark", "!", "--mark", fmt.Sprintf("%s/%s", masqueradeMark, masqueradeMark),
        "-j", "RETURN"); err != nil {
        klog.Errorf("Failed to ensure filtering rule for %v: %v", KubePostroutingChain, err)
        return
    }
    // 否则，清除0x4000标记位，防止封包重新遍历网络栈时，被再次SNAT
    // 注意，在这里可以明确知道0x4000被设置，因此可以安全的用XOR将该位取消掉，不需要关心其它位
    // iptables -t NAT -A  KUBE-POSTROUTING  -j MARK --xor-mark=0x4000
    if _, err := kl.iptClient.EnsureRule(utiliptables.Append, utiliptables.TableNAT, KubePostroutingChain,
        "-j", "MARK", "--xor-mark", masqueradeMark); err != nil {
        klog.Errorf("Failed to ensure unmarking rule for %v: %v", KubePostroutingChain, err)
        return
    }
    // ...
}
```

已知内核版本 5.6.13, 5.4.41, 4.19.123, 4.14.181 修复了上文提到的内核缺陷，但是 CentOS 7 何时修复未知，可能需要自行 Patch

## 深入

### Checksum

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
5. NETIF_F_RXCSUM  驱动进行接收封包的 Checksum Offloading，仅仅用于禁用设备的 RX Checksum

skb->ip_summed 字段存放了 Checksum 的状态，其含义在接收封包、发送封包期间有所不同。

在接收封包期间：

1. CHECKSUM_NONE 提示设备没有对封包进行 Checksum 校验，可能由于缺少相关特性
2. CHECKSUM_UNNECESSARY 提示内核不再需要对 Checksum 进行校验
3. CHECKSUM_COMPLETE 提示设备已经提供了完整的 L4 Checksum，L4 代码只需要加上伪头即可进行校验

在发送封包期间：

1. CHECKSUM_NONE 提示内核已经完全处理好 Checksum 了，设备不需要做任何事情
2. CHECKSUM_UNNECESSARY 意义和 CHECKSUM_NONE 相同
3. CHECKSUM_PARTIAL  提示内核已经完成伪头部分的 Checksum，驱动必须计算从 skb->csum_start 到封包结尾部分的 Checksum，并且将其存放在 skb->csum_start + skb->csum_offset 这个位置
4. CHECKSUM_COMPLETE  不使用

可以看到，在发送封包时，如果 skb->ip_summed 的值为 CHECKSUM_PARTIAL，则意味着内核要求驱动 Checksum Offloading。

### 内核缺陷

基于上面的认识，牵涉到的内核缺陷：

```c
// linux-3.10.y
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

当 VXLAN 端点的 UDP 被 NAT 的情况下，上述代码会执行。如果 VXLAN 设备禁用了 UDP Checksum，它会将 `udphdr->check` 置零。如果同时 VXLAN 设备还启用了 Tx Checksum Offloading，`skb->ip_summed` 的值就会是 CHECKSUM_PARTIAL。

UDP Checksum 被禁用情况下，`udphdr->check` 是个零值，显然没有包含旧的伪头的 Checksum 信息，因为通过伪头计算的 Checksum，至少协议类型部分（UDP 0x11）是非零。

因此，判断是否需要更新 Checksum，应当只根据 VXLAN 接口是否禁用了 UDP Checksum，禁用了就不应该更新。