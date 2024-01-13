每个 Deployment 就对应集群中的一次部署

![img](.assets/640-20221208102220294.png)

创建 deployment 资源做了如下工作：

1. 首先是 kubectl 发起一个创建 deployment 的请求
2. apiserver 接收到创建 deployment 请求，将相关资源写入 etcd；之后所有组件与 apiserver/etcd 的交互都是类似的
3. deployment controller list/watch 资源变化并发起创建 replicaSet 请求
4. replicaSet controller list/watch 资源变化并发起创建 pod 请求
5. scheduler 检测到未绑定的 pod 资源，通过一系列匹配以及过滤选择合适的 node 进行绑定
6. kubelet 发现自己 node 上需创建新 pod，负责 pod 的创建及后续生命周期管理
7. kube-proxy 负责初始化 service 相关的资源，包括服务发现、负载均衡等网络规则

至此，经过 kubenetes 各组件的分工协调，完成了从创建一个 deployment 请求开始到具体各 pod 正常运行的全过程。
