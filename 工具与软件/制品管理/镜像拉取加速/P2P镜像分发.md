## P2P 镜像分发技术

镜像分发规模达到一定数量时，首先面临压力的是 Harbor 服务或者后端存储的带宽。如果 100 个节点同时拉取镜像，镜像被压缩为 500MB，此时需要在 10 秒内完成拉取，则后端存储面临 5GB/s 的带宽。在一些较大的集群中，可能有上千个节点同时拉取一个镜像，带宽压力可想而知

P2P 镜像分发技术将需要分发的文件做分片处理，生成种子文件，每个 P2P 节点都根据种子文件下载分片。做分片时可以将文件拆分成多个任务并行执行，不同的节点可以从种子节点拉取不同的分片，下载完成之后自己再作为种子节点供别的节点下载。采用去中心化的拉取方式之后，流量被均匀分配到 P2P 网络中的节点上，可以显著提升分发速度

以下是一些常见的 P2P 镜像分发技术：

- Spegel: <https://github.com/XenitAB/spegel#spegel>

- Kraken：Uber 使用 Go 语言开发而开源的一个镜像 P2P 分发项目
- Dragonfly：阿里巴巴开源的 P2P 镜像和文件分发系统，可以解决原生云应用中面临的分发问题
- BitTorrent：BitTorrent 是一种常用的 P2P 文件分发协议，可以用于分发镜像文件。BitTorrent 协议将文件划分为多个块，每个块由多个节点共享，下载者可以同时从多个节点下载块，从而提高下载速度
- IPFS：IPFS（InterPlanetary File System）是一种分布式文件系统，可以用于存储和分发镜像文件。IPFS 将文件分割为多个块，每个块由多个节点存储，下载者可以从多个节点下载块，从而提高下载速度和可靠性

https://github.com/senthilrch/kube-fledged

Stargz Snapshotter：具有延迟拉动功能的快速容器镜像分发插件

（https://github.com/containerd/stargz-snapshotter）

Uber Kraken：Kraken 是一个 P2P Docker registry，能够在几秒钟内分发 TB数据

（https://github.com/uber/kraken）

Imagewolf：ImageWolf 是一种 PoC，它提供了一种将 Docker 镜像加载到集群上的极快方式，从而可以更快地推送更新

https://github.com/ContainerSolutions/ImageWolf）

## Kraken P2P 镜像分发



