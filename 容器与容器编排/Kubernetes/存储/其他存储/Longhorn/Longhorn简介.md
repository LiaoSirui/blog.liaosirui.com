## Longhorn 简介

Rancher 开源的一款 Kubernetes 的云原生分布式块存储方案 - Longhorn。

使用 Longhorn，可以：

- 使用 Longhorn 卷作为 Kubernetes 集群中分布式有状态应用程序的持久存储
- 将你的块存储分区为 Longhorn 卷，以便你可以在有或没有云提供商的情况下使用 Kubernetes 卷
- 跨多个节点和数据中心复制块存储以提高可用性
- 将备份数据存储在 NFS 或 AWS S3 等外部存储中
- 创建跨集群灾难恢复卷，以便可以从第二个 Kubernetes 集群中的备份中快速恢复主 Kubernetes 集群中的数据
- 调度一个卷的快照，并将备份调度到 NFS 或 S3 兼容的二级存储
- 从备份还原卷
- 不中断持久卷的情况下升级 Longhorn

Longhorn 还带有独立的 UI，可以使用 Helm、kubectl 或 Rancher 应用程序目录进行安装。

<https://www.qikqiak.com/k3s/storage/longhorn/>