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

## 部署场景

- 防止在某些节点上安装操作（operands）组件

默认情况下，GPU Operator 的操作组件会部署在集群中所有 GPU 工作节点上。GPU 工作节点通过标签 `feature.node.kubernetes.io/pci-10de.present=true` 进行识别，其中 `0x10de` 是分配给 NVIDIA 的 PCI 供应商 ID。

要禁止操作组件在某个 GPU 工作节点上部署，可以为该节点添加标签`nvidia.com/gpu.deploy.operands=false`：

```bash
kubectl label nodes $NODE nvidia.com/gpu.deploy.operands=false
```

- 防止在某些节点上安装 NVIDIA GPU 驱动程序

默认情况下，GPU Operator 会在集群中所有 GPU 工作节点上部署驱动程序。要防止在某个 GPU 工作节点上安装驱动程序，可以通过以下命令为该节点添加标签：

```bash
kubectl label nodes $NODE nvidia.com/gpu.deploy.driver=false
```

- 预安装的 NVIDIA GPU 驱动程序

如果没有指定 `driver.enabled=false` 参数，而集群中的节点已经预安装了 GPU 驱动程序，则驱动程序 Pod 中的初始化容器会检测到驱动程序已安装，并给节点打上标签，以终止驱动程序 Pod 并防止其重新调度到该节点上。随后，Operator 将继续启动其他 Pod，例如容器工具包 Pod

下面的命令将阻止 Operator 在集群的任何节点上安装 GPU 驱动程序。

```bash
helm install --wait --generate-name \
     -n gpu-operator --create-namespace \
     nvidia/gpu-operator \
     --set driver.enabled=false
```

- 预安装的 NVIDIA GPU 驱动程序和 NVIDIA 容器工具包

```bash
helm install --wait --generate-name \
     -n gpu-operator --create-namespace \
     nvidia/gpu-operator \
     --set driver.enabled=false \
     --set toolkit.enabled=false
```

- 为 containerd 指定配置选项

在使用 containerd 作为容器运行时时，可以为 GPU Operator 部署的容器工具包设置以下配置选项：

```yaml
toolkit:
   env:
   - name: CONTAINERD_CONFIG
     value: /etc/containerd/config.toml
   - name: CONTAINERD_SOCKET
     value: /run/containerd/containerd.sock
   - name: CONTAINERD_RUNTIME_CLASS
     value: nvidia
   - name: CONTAINERD_SET_AS_DEFAULT
     value: true

```

## 验证

运行一个简单的 CUDA 示例，将两个向量相加。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
  restartPolicy: OnFailure
  containers:
  - name: cuda-vectoradd
    image: "nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda11.7.1-ubuntu20.04"
    resources:
      limits:
        nvidia.com/gpu: 1

```

## 参考资料

- <https://www.lixueduan.com/posts/ai/02-gpu-operator/>

- <https://volcengine.csdn.net/695253295b9f5f31781b8bca.html>

- <https://kubernetes.feisky.xyz/practice/gpu#duo-zhong-xing-hao-de-gpu>