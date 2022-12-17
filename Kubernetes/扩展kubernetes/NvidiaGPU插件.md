## Nvidia GPU 插件

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
```

### 配置 containerd

```yaml
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
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
            BinaryName = "/usr/bin/nvidia-container-runtime"
```

重启 containerd

```yaml
systemctl restart containerd
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

helm chart 地址：<https://github.com/NVIDIA/k8s-device-plugin/blob/v0.12.3/deployments/helm/nvidia-device-plugin/values.yaml>

```yaml
# kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.12.3/nvidia-device-plugin.yml

helm upgrade -i nvdp \
    --namespace nvidia-device-plugin \
    --create-namespace \
    --set config.name=nvidia-plugin-configs \
    --set gfd.enabled=true \
    --set nodeSelector.gpu="enabled" \
    https://nvidia.github.io/k8s-device-plugin/stable/nvidia-device-plugin-0.12.3.tgz 
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
          nvidia.com/gpu: 1 # requesting 1 GPU
  tolerations:
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule
EOF
```
