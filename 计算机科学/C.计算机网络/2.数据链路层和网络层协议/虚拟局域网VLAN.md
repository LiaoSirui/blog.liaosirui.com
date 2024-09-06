VLAN（Virtual Local Area Network）即虚拟局域网，是将一个物理的 LAN 在逻辑上划分成多个广播域的通信技术。VLAN 内的主机间可以直接通信，而 VLAN 间不能直接互通，从而将广播报文限制在一个 VLAN 内

VLAN 主要用来解决如何将大型网络划分为多个小网络，隔离原本在同一个物理 LAN 中的不同主机间的二层通信，以使广播流量不会占据更多带宽资源，同时也提高网段间的安全性，因为广播域缩小了，广播风暴产生的可能性也大大降低

## VXLan 简介

VXLAN（`Virtual eXtensible Local Area Network`，虚拟可扩展局域网），是一种虚拟化隧道通信技术。它是一种 Overlay（覆盖网络）技术，通过三层的网络来搭建虚拟的二层网络。

简单来讲，`VXLAN` 是在底层物理网络（underlay）之上使用隧道技术，借助 `UDP` 层构建的 Overlay 的逻辑网络，使逻辑网络与物理网络解耦，实现灵活的组网需求。它对原有的网络架构几乎没有影响，不需要对原网络做任何改动，即可架设一层新的网络。也正是因为这个特性，很多 CNI 插件（Kubernetes 集群中的容器网络接口）才会选择 `VXLAN` 作为通信网络。

## 参考资料

- <https://www.modb.pro/db/149337>

- <https://support.huawei.com/enterprise/zh/doc/EDOC1100138284/c0f8a2a7>

