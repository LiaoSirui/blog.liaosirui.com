## kubernetes 架构

依托着 Borg 项目的理论优势，确定了一个如下图所示的全局架构图：

![img](.assets/20200510122933.png)

Kubernetes 由 Master 和 Node 两种节点组成，这两种角色分别对应着控制节点和工作节点

![img](.assets/640-0465006.png)

从宏观上来看 kubernetes 的整体架构，包括 Master、Node 以及 Etcd

Master 即主节点，负责控制整个 kubernetes 集群。它包括 Api Server、Scheduler、Controller 等组成部分。它们都需要和 Etcd 进行交互以存储数据

- Api Server：主要提供资源操作的统一入口，这样就屏蔽了与 Etcd 的直接交互。功能包括安全、注册与发现等
- Scheduler：负责按照一定的调度规则将 Pod 调度到 Node 上
- Controller：资源控制中心，确保资源处于预期的工作状态

Node 即工作节点，为整个集群提供计算力，是容器真正运行的地方，包括运行容器、kubelet、kube-proxy

- kubelet：主要工作包括管理容器的生命周期、结合 cAdvisor 进行监控、健康检查以及定期上报节点状态
- kube-proxy: 主要利用 service 提供集群内部的服务发现和负载均衡，同时监听 service/endpoints 变化并刷新负载均衡

### kube-apiserver

API Server 提供了资源对象的唯一操作入口，其它所有组件都必须通过它提供的 API 来操作资源数据。只有 API Server 会与 etcd 进行通信，其它模块都必须通过 API Server 访问集群状态。API Server 作为 Kubernetes 系统的入口，封装了核心对象的增删改查操作。API Server 以 RESTFul 接口方式提供给外部客户端和内部组件调用，API Server 再对相关的资源数据（全量查询 + 变化监听）进行操作，以达到实时完成相关的业务功能。以 API Server 为 Kubernetes 入口的设计主要有以下好处：

- 保证了集群状态访问的安全
- API Server 隔离了集群状态访问和后端存储实现，这样 API Server 状态访问的方式不会因为后端存储技术 Etcd 的改变而改变，让后端存储方式选择更加灵活，方便了整个架构的扩展

### kube-controller-manager

### kube-scheduler

### kubelet

### kube-proxy

### kubectl
