## Nvidia GPU 插件

Kubernetes 提供了一个设备插件框架， 可以用它来将系统硬件资源发布到 Kubelet。

供应商可以实现设备插件，由手动部署或作为 DaemonSet 来部署，而不必定制 Kubernetes 本身的代码。目标设备包括 GPU、高性能 NIC、FPGA、 InfiniBand 适配器以及其他类似的、可能需要特定于供应商的初始化和设置的计算资源。

代码仓库： <https://github.com/NVIDIA/k8s-device-plugin#quick-start>

安装了插件，集群就会暴露一个自定义可调度的资源，`nvidia.com/gpu`。

可以通过请求这个自定义的 GPU 资源在你的容器中使用这些 GPU，其请求方式与请求 cpu 或 memory 时相同。 不过，在如何指定自定义设备的资源请求方面存在一些限制。

GPU 只能在 limits 部分指定，这意味着：

- 可以指定 GPU 的 limits 而不指定其 requests，因为 Kubernetes 将默认使用限制值作为请求值。
- 可以同时指定 limits 和 requests，不过这两个值必须相等。
- 不可以仅指定 requests 而不指定 limits。

## 安装

### 安装插件

文档地址：<https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html>

软件源如下：

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    
# rocky9 暂时没有支持，使用：
curl -s -L https://nvidia.github.io/libnvidia-container/rhel9.0/libnvidia-container.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
```

内容如下：

```plain
[libnvidia-container]
name=libnvidia-container
baseurl=https://nvidia.github.io/libnvidia-container/stable/centos8/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://nvidia.github.io/libnvidia-container/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt

[libnvidia-container-experimental]
name=libnvidia-container-experimental
baseurl=https://nvidia.github.io/libnvidia-container/experimental/centos8/$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=0
gpgkey=https://nvidia.github.io/libnvidia-container/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
```

安装

```bash
dnf clean expire-cache \
    && dnf install -y nvidia-container-toolkit
    
nvidia-ctk --version
```

### 配置 containerd

```bash
> cat <<EOF > containerd-config.patch
--- config.toml.orig    2020-12-18 18:21:41.884984894 +0000
+++ /etc/containerd/config.toml 2020-12-18 18:23:38.137796223 +0000
@@ -94,6 +94,15 @@
        privileged_without_host_devices = false
        base_runtime_spec = ""
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
+            SystemdCgroup = true
+       [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
+          privileged_without_host_devices = false
+          runtime_engine = ""
+          runtime_root = ""
+          runtime_type = "io.containerd.runc.v1"
+          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
+            BinaryName = "/usr/bin/nvidia-container-runtime"
+            SystemdCgroup = true
    [plugins."io.containerd.grpc.v1.cri".cni]
    bin_dir = "/opt/cni/bin"
    conf_dir = "/etc/cni/net.d"
EOF
```

即：

```toml
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "nvidia"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v1"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
            BinaryName = "/usr/bin/nvidia-container-runtime"
            SystemdCgroup = true
```

重启 containerd

```yaml
systemctl restart containerd
```

测试安装

```bash
ctr image pull docker.io/nvidia/cuda:11.6.2-base-ubuntu20.04

ctr run --rm -t \
    --runc-binary=/usr/bin/nvidia-container-runtime \
    --env NVIDIA_VISIBLE_DEVICES=all \
    docker.io/nvidia/cuda:11.6.2-base-ubuntu20.04 \
    cuda-11.6.2-base-ubuntu20.04 nvidia-smi
```

### 在 k8s 中启用

配置 GPU 插件的 yaml 如下：

```yaml
version: v1
flags:
  migStrategy: "none"
  failOnInitError: true
  nvidiaDriverRoot: "/"
  plugin:
    passDeviceSpecs: false
    deviceListStrategy: "envvar"
    deviceIDStrategy: "uuid"
```

创建配置文件

```bash
kubectl create cm -n nvidia-device-plugin nvidia-plugin-configs \
    --from-file=config=/tmp/dp-example-config0.yaml
```

helm chart 地址：<https://github.com/NVIDIA/k8s-device-plugin/blob/v0.13.0/deployments/helm/nvidia-device-plugin/values.yaml>

```yaml
# refer: https://github.com/NVIDIA/k8s-device-plugin/releases

# kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.13.0/nvidia-device-plugin.yml

helm upgrade -i nvdp \
    --namespace nvidia-device-plugin \
    --create-namespace \
    --set config.name=nvidia-plugin-configs \
    --set gfd.enabled=true \
    --set nodeSelector.gpu="enabled" \
    https://nvidia.github.io/k8s-device-plugin/stable/nvidia-device-plugin-0.13.0.tgz 
```

### 启动一个 GPU Pod

```yaml
$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  restartPolicy: Never
  containers:
    - name: cuda-container
      image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda10.2
      resources:
        limits:
          nvidia.com/gpu: "1" # requesting 1 GPU
  tolerations:
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule
EOF
```

## 其他

### 查看 GPU 资源是否上报

```bash
#!/bin/bash

# 获取所有符合条件的 NVIDIA Device Plugin Pod及其所在节点
PODS=$(kubectl get po -n kube-system -l component=nvidia-device-plugin -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}')

# 遍历每个 Pod 的节点
echo "$PODS" | while IFS=$'\t' read -r pod_name node_name; do
    # 获取节点的 nvidia.com/gpu 资源分配值
    gpu_allocatable=$(kubectl get node "$node_name" -o jsonpath='{.status.allocatable.nvidia\.com/gpu}' 2>/dev/null)

    # 检查资源值是否为 0
    if [ "$gpu_allocatable" == "0" ]; then
        echo "Error: node=$node_name, pod=$pod_name, resource(nvidia.com/gpu) is 0"
    fi
done
```

### 修改 NVIDIA Device Plugin 设备标识符

Device-Plugin 在为 Pod 分配设备时会在节点上创建一份 Checkpoint 文件，用于记录和保存哪些设备已经被分配，以及它们对应 Pod 的信息。在 NVIDIA Device Plugin 中，Checkpoint 文件默认使用 GPU 的 UUID 作为每个 GPU 设备的唯一标识符（Key）。可以参见下文将该 Key 修改为设备的 Index，以解决 VM 冷迁移导致的 UUID 丢失等问题。

添加如下环境变量`CHECKPOINT_DEVICE_ID_STRATEGY`。

```yaml
    env:
      - name: CHECKPOINT_DEVICE_ID_STRATEGY
        value: index
```

## 故障处理

### 开启 GPU 设备隔离功能

对节点上的某个设备进行隔离，以避免新的 GPU 应用 Pod 被分配到这张 GPU 卡

在目标节点 `/etc/nvidia-device-plugin/` 的目录下操作 `unhealthyDevices.json` 这个文件，如果此文件不存在，新建此文件

```json
{
  "index": ["x", "x" ..],
  "uuid": ["xxx", "xxx" ..]
}
```

在 JSON 中填写目标隔离设备的 `index` 或 `uuid`（同一个设备只需填写任意一个）

### GPU 容器出现 Failed to initialize NVML: Unknown Error

若节点操作系统为 Ubuntu 22.04 或 Red Hat Enterprise Linux(RHEL) 9.3 64 位时，在 GPU 容器内部执行`nvidia-smi`可能会出现如下报错。

```bash
sudo nvidia-smi

Failed to initialize NVML: Unknown Error
```

在节点上执行 `systemctl daemon-reload`、`systemctl daemon-reexec` 等操作后，会更新 cgroup 相关配置，进而影响 NVIDIA GPU 设备在容器中的正常使用。

通过以下几种方式为 Pod 申请 GPU 资源将会受影响：

- 在 Pod 的 `resources.limits` 中指定资源。 
- 在 Pod 中为容器设置环境变量 `NVIDIA_VISIBLE_DEVICES`，以便 Pod 能够访问节点上的 GPU 资源。
- Pod 所使用的容器镜像在制作时默认设置 `NVIDIA_VISIBLE_DEVICES` 的环境变量，且 Pod 希望访问节点 GPU 资源。

可以通过重建该应用Pod的方式来临时修复此问题。应用 Pod 通过将环境变量`NVIDIA_VISIBLE_DEVICES=all`的方式来申请 GPU 资源时，可以为该应用容器添加`privileged`权限

## 参考文档

- <https://zhuanlan.zhihu.com/p/686793028>
