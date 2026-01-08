## 简介

NVIDIA GPU Operator 包含如下的几个组件：

- NFD (Node Feature Discovery)

用于给节点打上某些标签，这些标签包括 cpu id、内核版本、操作系统版本、是不是 GPU 节点等，其中需要关注的标签是 `nvidia.com/gpu.present=true`，如果节点存在该标签，那么说明该节点是 GPU 节点。

- NVIDIA Driver Installer

基于容器的方式在节点上安装 NVIDIA GPU 驱动，在 k8s 集群中以 DaemonSet 方式部署，只有节点拥有标签 `nvidia.com/gpu.present=true` 时，DaemonSet 控制的 Pod 才会在该节点上运行。

- NVIDIA Container Toolkit Installer

能够实现在容器中使用 GPU 设备，在 k8s 集群中以 DaemonSet 方式部署，只有节点拥有标签 `nvidia.com/gpu.present=true` 时，DaemonSet 控制的 Pod 才会在该节点上运行。

- NVIDIA Device Plugin

NVIDIA Device Plugin 用于实现将 GPU 设备以 Kubernetes 扩展资源的方式供用户使用，在 k8s 集群中以 DaemonSet 方式部署，只有节点拥有标签 `nvidia.com/gpu.present=true` 时，DaemonSet 控制的 Pod 才会在该节点上运行。

- DCGM Exporter

周期性的收集节点 GPU 设备的状态（当前温度、总的显存、已使用显存、使用率等），然后结合 Prometheus 和 Grafana 将这些指标用丰富的仪表盘展示给用户。在 k8s 集群中以 DaemonSet 方式部署，只有节点拥有标签 `nvidia.com/gpu.present=true` 时，DaemonSet 控制的 Pod 才会在该节点上运行。

- GFD (GPU Feature Discovery)

用于收集节点的 GPU 设备属性（GPU 驱动版本、GPU 型号等），并将这些属性以节点标签的方式透出。在 k8s 集群中以 DaemonSet 方式部署，只有节点拥有标签 `nvidia.com/gpu.present=true` 时，DaemonSet 控制的 Pod 才会在该节点上运行。

## 参考资料

- <https://www.lixueduan.com/posts/ai/02-gpu-operator/>

- <https://volcengine.csdn.net/695253295b9f5f31781b8bca.html>