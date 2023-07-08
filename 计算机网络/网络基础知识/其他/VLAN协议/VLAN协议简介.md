## VXLan 简介

VXLAN（`Virtual eXtensible Local Area Network`，虚拟可扩展局域网），是一种虚拟化隧道通信技术。它是一种 Overlay（覆盖网络）技术，通过三层的网络来搭建虚拟的二层网络。

简单来讲，`VXLAN` 是在底层物理网络（underlay）之上使用隧道技术，借助 `UDP` 层构建的 Overlay 的逻辑网络，使逻辑网络与物理网络解耦，实现灵活的组网需求。它对原有的网络架构几乎没有影响，不需要对原网络做任何改动，即可架设一层新的网络。也正是因为这个特性，很多 CNI 插件（Kubernetes 集群中的容器网络接口）才会选择 `VXLAN` 作为通信网络。

## 参考资料

- <https://www.modb.pro/db/149337>

- <https://support.huawei.com/enterprise/zh/doc/EDOC1100138284/c0f8a2a7>