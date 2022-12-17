https://openkruise.io/docs/next/user-manuals/imagepulljob

OpenKruise 是一个基于 Kubernetes 的扩展套件，主要聚焦于云原生应用的自动化，比如部署、发布、运维以及可用性防护

- `CloneSet` 对原生 Deployment 的增强控制器
- `Advanced StatefulSet` 原生的 StatefulSet 基础上增强了发布能力
- `Advanced DaemonSet` 原生 DaemonSet 上增强了发布能力
- `BroadcastJob` BroadcastJob 管理的 Pod 并不是长期运行的 daemon 服务，而是类似于 Job 的任务类型 Pod，在每个节点上的 Pod 都执行完成退出后
- `AdvancedCronJob` AdvancedCronJob 是对于原生 CronJob 的扩展版本，根据用户设置的 schedule 规则，周期性创建 Job 执行任务
- `SidecarSet` SidecarSet 将 sidecar 容器的定义和生命周期与业务容器解耦，它主要用于管理无状态的 sidecar 容器，比如监控、日志等 agent
- `ContainerRestart` ContainerRecreateRequest 控制器可以帮助用户重启/重建存量 Pod 中一个或多个容器
- `ImagePullJob` NodeImage 和 ImagePullJob
- `ContainerLaunchPriority` 提供了控制一个 Pod 中容器启动顺序的方法

