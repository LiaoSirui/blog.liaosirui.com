## kubernetes 架构

依托着 Borg 项目的理论优势，确定了一个如下图所示的全局架构图：

<img src=".assets/20200510122933.png" alt="kubernetes arch" style="zoom:50%;" />

Kubernetes 由 Master 和 Node 两种节点组成，这两种角色分别对应着控制节点和工作节点

<img src=".assets/640-0465006.png" alt="图片" style="zoom:50%;" />

从宏观上来看 kubernetes 的整体架构，包括 Master、Node 以及 Etcd

Master 即主节点，负责控制整个 kubernetes 集群。它包括 Api Server、Scheduler、Controller 等组成部分。它们都需要和 Etcd 进行交互以存储数据

- Api Server：主要提供资源操作的统一入口，这样就屏蔽了与 Etcd 的直接交互。功能包括安全、注册与发现等
- Scheduler：负责按照一定的调度规则将 Pod 调度到 Node 上
- Controller：资源控制中心，确保资源处于预期的工作状态

Node 即工作节点，为整个集群提供计算力，是容器真正运行的地方，包括运行容器、kubelet、kube-proxy

- kubelet：主要工作包括管理容器的生命周期、结合 cAdvisor 进行监控、健康检查以及定期上报节点状态
- kube-proxy: 主要利用 service 提供集群内部的服务发现和负载均衡，同时监听 service/endpoints 变化并刷新负载均衡