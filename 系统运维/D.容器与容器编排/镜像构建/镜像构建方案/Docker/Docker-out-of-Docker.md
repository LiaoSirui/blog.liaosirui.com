在 Kubernetes 集群中，部分 CI/CD 流水线业务可能需要使用 Docker 来提供镜像打包服务。可通过宿主机的 Docker 实现，将 Docker 的 `UNIX Socket（/var/run/docker.sock）` 通过 hostPath 挂载到 CI/CD 的业务 Pod 中，之后在容器里通过 UNIX Socket 来调用宿主机上的 Docker 进行构建，这个就是之前我们使用较多的 `Docker outside of Docker` 方案。该方式操作简单，比真正意义上的 `Docker in Docker` 更节省资源，但该方式可能会遇到以下问题：

- 无法运行在 Runtime 是 containerd 的集群中。
- 如果不加以控制，可能会覆盖掉节点上已有的镜像。
- 在需要修改 Docker Daemon 配置文件的情况下，可能会影响到其他业务。
- 在多租户的场景下并不安全，当拥有特权的 Pod 获取到 Docker 的 UNIX Socket 之后，Pod 中的容器不仅可以调用宿主机的 Docker 构建镜像、删除已有镜像或容器，甚至可以通过 `docker exec` 接口操作其他容器。

对于部分需要 containerd 集群，而不改变 CI/CD 业务流程仍使用 Docker 构建镜像一部分的场景，我们可以通过在原有 Pod 上添加 `DinD` 容器作为 Sidecar 或者使用 DaemonSet 在节点上部署专门用于构建镜像的 Docker 服务。

