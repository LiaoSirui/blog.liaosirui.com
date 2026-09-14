## 概览

cgroup v2 + containerd + Kubernetes 环境下，Pod 和容器 cgroup 的目录层级规律，以及如何定位资源统计文件。

- cgroup v2 使用单一统一的层级结构（Unified Hierarchy）。
- cgroup 通常挂载在 `/sys/fs/cgroup/`。
- 使用 containerd 时，容器通常以 `cri-containerd-<ContainerID>.scope` 的形式出现在 Pod cgroup 下。
- Kubernetes Pod 的 cgroup 通常位于 `/sys/fs/cgroup/kubepods.slice/` 下。

## 目录层级规律

整体结构可以概括为：

```text
/sys/fs/cgroup/
└── kubepods.slice/
    ├── kubepods-pod<PodUID>.slice/                         # Guaranteed Pod
    │   └── cri-containerd-<ContainerID>.scope/               # Container
    ├── kubepods-besteffort.slice/                          # BestEffort QoS
    │   └── kubepods-besteffort-pod<PodUID>.slice/
    │       └── cri-containerd-<ContainerID>.scope/
    └── kubepods-burstable.slice/                           # Burstable QoS
        └── kubepods-burstable-pod<PodUID>.slice/
            └── cri-containerd-<ContainerID>.scope/
```

其中：

- `kubepods.slice`：所有 Kubernetes Pod 的父 cgroup。
- `kubepods-pod<PodUID>.slice`：Guaranteed Pod 的 cgroup。
- `kubepods-<qos>-pod<PodUID>.slice`：BestEffort 或 Burstable Pod 的 cgroup。
- `cri-containerd-<ContainerID>.scope`：containerd 创建的容器 cgroup。
- `<PodUID>`：Pod UID 在路径中通常将 `-` 转换为 `_`。
- `<ContainerID>`：容器的完整 container ID。

一个 Pod 下通常包含多个 `cri-containerd-*.scope`，例如业务容器和 pause 容器。

## Guaranteed

Guaranteed Pod 直接位于 `kubepods.slice` 下，不经过额外的 QoS slice：

```text
/sys/fs/cgroup/kubepods.slice/
└── kubepods-pod<PodUID>.slice/
    ├── cri-containerd-<ContainerID>.scope/
    │   ├── memory.current
    │   ├── memory.events
    │   ├── memory.high
    │   ├── memory.low
    │   ├── memory.max
    │   ├── memory.min
    │   ├── memory.oom.group
    │   ├── memory.pressure
    │   ├── memory.reclaim
    │   └── memory.stat
    └── cri-containerd-<ContainerID>.scope/
```

示例

以下是一个 Guaranteed Pod 的实际路径示例：

```text
/sys/fs/cgroup/kubepods.slice/
└── kubepods-pod05039cef_3327_4a8d_916c_a03cf9939b20.slice/
    ├── cri-containerd-6220c72065c29865873f5c1fcd371c96b8251225b09bf91655772a3443facaec.scope/
    │   ├── memory.current
    │   ├── memory.events
    │   ├── memory.high
    │   ├── memory.low
    │   ├── memory.max
    │   ├── memory.min
    │   ├── memory.oom.group
    │   ├── memory.pressure
    │   ├── memory.reclaim
    │   └── memory.stat
    └── cri-containerd-a93e5653f02834243c2f5d60f1f14709ce43a13f04eb3dac38b804cb43ff7d72.scope/
```

从该示例可以得到：

- Pod UID 为 `05039cef-3327-4a8d-916c-a03cf9939b20`，路径中显示为 `05039cef_3327_4a8d_916c_a03cf9939b20`。
- Pod 下至少有两个 container scope。
- 容器 cgroup 的目录名由 `cri-containerd-`、完整 Container ID 和 `.scope` 组成。

## BestEffort

BestEffort 目录层级如下：

```text
/sys/fs/cgroup/kubepods.slice/
└── kubepods-besteffort.slice/
    └── kubepods-besteffort-pod<PodUID>.slice/
        └── cri-containerd-<ContainerID>.scope/
```

示例

```text
/sys/fs/cgroup/kubepods.slice/
└── kubepods-besteffort.slice/
    ├── kubepods-besteffort-pod05039cef_3327_4a8d_916c_a03cf9939b20.slice/
    │   ├── cri-containerd-6220c72065c29865873f5c1fcd371c96b8251225b09bf91655772a3443facaec.scope/
    │   │   ├── memory.current
    │   │   ├── memory.events
    │   │   ├── memory.high
    │   │   ├── memory.low
    │   │   ├── memory.max
    │   │   ├── memory.min
    │   │   ├── memory.oom.group
    │   │   ├── memory.pressure
    │   │   ├── memory.reclaim
    │   │   └── memory.stat
    │   └── cri-containerd-a93e5653f02834243c2f5d60f1f14709ce43a13f04eb3dac38b804cb43ff7d72.scope/
    └── kubepods-besteffort-pod171c53c9_0a43_45ae_aacf_8eaf63fe7e74.slice/
```

## Burstable

Burstable 目录层级如下：

```text
/sys/fs/cgroup/kubepods.slice/
└── kubepods-burstable.slice/
    └── kubepods-burstable-pod<PodUID>.slice/
        └── cri-containerd-<ContainerID>.scope/
```

示例

```text
/sys/fs/cgroup/kubepods.slice/
└── kubepods-burstable.slice/
    ├── kubepods-burstable-pod05039cef_3327_4a8d_916c_a03cf9939b20.slice/
    │   ├── cri-containerd-6220c72065c29865873f5c1fcd371c96b8251225b09bf91655772a3443facaec.scope/
    │   │   ├── memory.current
    │   │   ├── memory.events
    │   │   ├── memory.high
    │   │   ├── memory.low
    │   │   ├── memory.max
    │   │   ├── memory.min
    │   │   ├── memory.oom.group
    │   │   ├── memory.pressure
    │   │   ├── memory.reclaim
    │   │   └── memory.stat
    │   └── cri-containerd-a93e5653f02834243c2f5d60f1f14709ce43a13f04eb3dac38b804cb43ff7d72.scope/
    └── kubepods-burstable-pod171c53c9_0a43_45ae_aacf_8eaf63fe7e74.slice/
```

## 常用资源文件

容器或 Pod cgroup 目录中的资源文件遵循 cgroup v2 命名规则。与内存和 PSI 相关的常用文件如下：

| 文件 | 作用 |
| --- | --- |
| `memory.current` | 当前内存使用量，通常以字节为单位 |
| `memory.max` | 内存硬上限；值为 `max` 时表示不限制 |
| `memory.high` | 内存高水位线，超过后可能触发回收或节流 |
| `memory.low` | 内存软保护下限 |
| `memory.min` | 内存强保护下限 |
| `memory.events` | 记录 high、OOM 等内存事件计数 |
| `memory.oom.group` | 是否以 cgroup 为单位处理 OOM |
| `memory.stat` | 详细内存统计 |
| `memory.pressure` | 内存 PSI 压力信息 |
| `memory.reclaim` | 请求回收 cgroup 中的内存 |

如果关注内存压力，主要读取 `memory.pressure`；如果关注 OOM 或达到限制的情况，主要读取 `memory.events`；如果需要比较当前使用量和上限，则读取 `memory.current` 与 `memory.max`。
