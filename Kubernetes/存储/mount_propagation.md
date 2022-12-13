## 简介

Mount propagation  - 挂载命名空间的传播

挂载传播允许将 Container 挂载的卷共享到同一Pod中的其他Container，甚至可以共享到同一节点上的其他Pod。
一个卷的挂载传播由Container.volumeMounts中的mountPropagation字段控制。它的值是：

- None 此卷挂载不会接收到任何后续挂载到该卷或是挂载到该卷的子目录下的挂载。以类似的方式，在主机上不会显示Container创建的装载。这是默认模式。

此模式等同于Linux内核文档中所述的 private 传播。

- HostToContainer 此卷挂载将会接收到任何后续挂载到该卷或是挂载到该卷的子目录下的挂载。

换句话说，如果主机在卷挂载中挂载任何内容，则Container将看到它挂载在那里。
类似地，如果任何具有 Bidirectional 挂载传播设置的Pod挂载到同一个卷中，那么具有HostToContainer挂载传播的Container将会看到它。
此模式等同于Linux内核文档中描述的rslave挂载传播。

- Bidirectional 此卷挂载的行为与HostToContainer挂载相同。此外，Container创建的所有卷挂载都将传播回主机和所有使用相同卷的Pod的所有容器。

此模式的典型用例是具有Flexvolume或CSI驱动程序的Pod需要使用hostPath 卷模式 在主机上挂载内容。
此模式等同于Linux内核文档中描述的rshared安装传播。
PS：
Bidirectional 挂载传播可能很危险。它可能会损坏主机操作系统，因此只允许在特权容器中使用它。强烈建议您熟悉Linux内核行为。此外，容器在容器中创建的任何卷装入必须在终止时由容器销毁（卸载）。

Bidirectional一些使用场景：

- 在不同的pod之间共享设备，其中挂载发生在pod中，但是在pod之间共享。
- 从容器内部附加设备。例如，从容器内部附加ISCSI设备。这时候因为如果容器死掉，主机将不能获得所需的信息（除非使用双向安装传播）来正确刷新写入和分离设备。


<img src=".assets/20180705175218137.png" alt="img"  />

https://blog.csdn.net/weixin_34021089/article/details/88755548

https://blog.csdn.net/weixin_33974433/article/details/89566016
