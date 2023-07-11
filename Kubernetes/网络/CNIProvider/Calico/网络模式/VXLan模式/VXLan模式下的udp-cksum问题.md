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

