## OpenShift 架构

![img](.assets/Openshift%E7%AE%80%E4%BB%8B/9f371f3f4505c02eaab37b93c7ddd31c.png)

### OpenShift projects and Applications

OpenShift 管理 projects 和 users。 OpenShift 使用project分组Kubernetes资源(可以直接理解为 k8s 中命名空间的角色),以便将访问权限分配给用户。针对 project 也可以分配配额,限制 pods、卷、服务和其他资源的数量。OpenShift 客户端提供new-app命令,用于在项目内创建资源。

### Building Images with Source-to-Image

开发人员和系统管理员可以直接使用 OpenShift 中传统 Docker 和 Kubernetes,但是这要求他们知道如何构建容器镜像文件、使用 registries 和其他低级功能。

OpenShift 允许开发人员使用标准源代码管理(source control management--SCM)存储库和集成开发环境(integrated development environments--IDE)。

OpenShift 中 Source-to-Image (S2I)从 SCM 仓库获取代码,自动检测源代码需要哪种类型runtime(可以理解为语言环境 SDK),并且使用具有特定类型 runtime 的基本 image 启动 pod。

在这个 POD 中, OpenShift 以与开发人员相同的方式构建应用(例如,运行 Java 应用的 Maven)。如果生成成功,则会创建另外一个 image,在其运行时将应用二进制文件分层,并将此 image 推送到 OpenShift 内的 image 注册表。之后,可以使用新的 image 构建 POD。S21可以看作是OpenShift中自带的完整CI/CD管道。启动装配线的过程称为“持续集成”（CI）。如何完成这项工作的总体设计称为“持续交付”（CD）。

### Managing OpenShift Resources

OpenShift 资源,例如 images, containers, pods, services, builders, templates等等,存储在Etcd,可通过OpenShift CLI, web console,或者 REST API 管理。这些资源可以在 SCM 系统(例如 Git 或者 Subversion)上以 JSON 或者 YAML 格式查看和分享。

### OpenShift Networking

Docker 的网络非常简单。Docker 创建虚拟内核网桥,连接每个容器网络接口。Docker 本身不提供 host 上 pod 连接另外一个 host 上 pod(跨主机网络通信),而且不提供分配固定公网 IP 地址给应用,以便外部用户可以访问。

Kubernetes 提供服务和路由资源来管理 pods 之间网络和 pod 与外部通信网络。oad-balances服务接收 pods 之间网络请求,同时为所有客户端提供单个内部地址。(通常是其他 pods)。容器和 pods 不需要知道其他 pods 在哪里,他们只需要连接到服务。路由为服务提供固定唯一的 DNS 名称,以便 OpenShift 集群之外的客户端可以看到。

### Persistent StoragePods

可以在任何时候在某个 node 上停止,然后在其他 node 上重启。因此临时存储是无法满足这个要求的。Kubernetes 提供了一种用于管理容器的外部持久存储的框架。Kubernetes 使用 PersitentVolume 资源,可以定义本地或网络存储。pod 资源可以引用 PersitentVolumeClaim 资源访问特定大小 PersitentVolume 存储。

### OpenShift High Availability

OpenShift 容器平台集群的 HA 包括两个方面:

- OpenShift 基础架构本身高可用(多 masters)
- OpenShift 集群中应用高可用

OpenShift 本身就完全支持 master 得 HA。对于应用(pods), OpenShift 模式也会支持。如果 pod 因为某个原因丢失, Kubernetes 调度另外一个副本,将它连接到服务层和永久存储。如果整个 node 丢失, Kubernetes 将 node 上所有 pods 调度到其他 nodes,这些 pods 继续对外提供服务。但是 pods 中应用要维护自己的状态,例如 http 会话, database 复制等。

### Image Streams

在 OpenShift 中创建一个新的应用,除了应用源代码之外,还需要base image,(S21构建的image)。这两个组件中任一个更新,都会创建一个新的容器 image。使用之前容器 image 创建的 pod,都会被重新使用新的 image 创建的 pod 替换。所以 openshift 创建应用可以通过 S2I 创建，也可以直接使用 image 创建，或者使用模板，pipeline 的方式

Image Stream包含了通过 tags标识的images。它代表相关image的单一虚拟视图。应用可以通过 Image Stream 构建的。当创建新 images 时, Image Stream 可用于自动执行动作。例如添加了新的 image,构建和部署会接受到消息,然后针对新的 image 进行构建和部署 pod。

OpenShift 默认提供多个 Image Stream,包括许多流行的语言 runtime 和框架。Image Stream tag 是指向 image 的别名,简写为 istag,包含 tag 曾经指向的 image 记录。当新的 image 使用了新的 istag 标记,那么该标记会放到记录中第一个位置。之前标记的第一位置变更为第二,可以轻松实现回滚,使标签再次指向旧的 image