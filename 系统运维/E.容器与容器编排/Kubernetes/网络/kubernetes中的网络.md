讲到网络通信，kubernetes 首先得有”三通”基础：

1. node 到 pod 之间可以通
2. node 的 pod 之间可以通
3. 不同 node 之间的 pod 可以通

![img](.assets/640-20221208102601005.png)

简单来说，不同 pod 之间通过 cni0/docker0 网桥实现了通信，node 访问 pod 也是通过 cni0/docker0 网桥通信即可。

而不同 node 之间的 pod 通信有很多种实现方案，包括现在比较普遍的 flannel 的 vxlan/hostgw 模式等。flannel 通过 etcd 获知其他 node 的网络信息，并会为本 node 创建路由表，最终使得不同 node 间可以实现跨主机通信。
