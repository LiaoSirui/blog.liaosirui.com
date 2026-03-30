## TrueNAS

TrueNAS 由原 FreeNAS 演变而来，FreeNAS 和 TrueNAS 已经合并，统一使用 TrueNAS 这一名字

TrueNAS（12.0 版前称为 FreeNAS，是一套基于 FreeBSD 操作系统核心的开放源代码的网络存储设备服务器系统，支持众多服务，用户访问权限管理，提供网页设置接口

官方：

- 官网 <https://www.truenas.com/>

FreeNAS 主要由 iXsystems 领导开发, 现在 iXsystems 宣布了一个基于 Debian Linux 的版本叫 TrueNAS SCALE。TrueNAS SCALE 是 TrueNAS 系列的最新成员，并提供包括 Linux 容器和 VM 在内的开源 HyperConverged 基础架构。TrueNAS SCALE 包括集群系统和提供横向扩展存储的能力，容量最高可达数百 PB

### TrueNAS Core

- 特点：基于 FreeBSD 系统，使用 ZFS 文件系统，以稳定性和成熟度著称。
- 功能：
  - 高效的数据保护，支持 RAID - Z、快照、数据压缩和重复数据删除。
  - 支持多种协议，如 SMB、NFS、iSCSI 等，适用于多平台存储访问。
  - 提供基于 Web 的管理界面，易于配置和管理。
  - 适用场景：适合家庭用户和小型企业，对稳定性和数据完整性要求较高的场景。

### TrueNAS Scale

- 特点：基于 Debian Linux 系统，支持 Docker 容器和 Kubernetes 编排。
- 功能：
  - 提供原生 Docker 容器支持，适合需要容器化应用的用户。
  - 支持 Kubernetes 编排，适合需要大规模容器管理的场景。
  - 支持多种存储协议，如 SMB、NFS、iSCSI 等。
  - 适用场景：适合需要容器化和现代特性的用户，尤其是对新技术有需求的用户。

### TrueNAS Enterprise

- 特点：企业级解决方案，提供高级功能和专业支持。
- 功能：
  - 高可用性（HA）支持，确保系统持续运行。
  - 提供专业的技术支持和维护服务。
  - 支持大规模存储部署和复杂的企业级应用。
  - 适用场景：适合大型企业或数据中心，对性能、可靠性和支持有较高要求的场景。

## 支持的协议

- 文件共享协议：支持 SMB/CIFS（Windows）、NFS（Linux/Unix）、AFP（macOS）等多种文件共享协议。
- 块存储协议：支持 iSCSI，可用于虚拟化和数据库存储。
- 对象存储：通过 MinIO 插件支持 S3 兼容的对象存储。