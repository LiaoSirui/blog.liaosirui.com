
CRI-O 是 Kubernetes 容器运行时接口（CRI）的基于 OCI 的实现。

CRI-O 旨在在符合 OCI 的运行时和 kubelet 之间提供集成路径。

CRI-O 的范围仅限于以下功能：

- 支持多种镜像格式，包括现有的 Docker 镜像格式
- 支持多种下载镜像的方式，包括信任和镜像验证
- 容器镜像管理（管理镜像层，overlay 文件系统等）
- 容器过程生命周期管理
- 满足 CRI 所需的监视和记录
- CRI 要求的资源隔离

CRI-O在不同方面使用了最佳的品种库：

运行时：runc(或者任何OCI运行时规范实现)和oci运行时工具

- 镜像：使用 `containers/image` 进行镜像管理
- 存储：使用 `containers/storage` 来存储和管理镜像层
- 联网：通过使用 CNI的 联网支持

![img](.assets/image-20221217135749579.png)
