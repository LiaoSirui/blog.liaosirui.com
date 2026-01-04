## 简介

动态资源分配（Dynamic Resource Allocation，DRA）可实现在 Pod 之间请求和共享 GPU 资源，它是持久卷 API 针对通用资源的扩展。相比传统的设备插件模式，DRA 提供了更灵活、更细粒度的资源请求方式

NVIDIA 动态资源分配 GPU 驱动程序（NVIDIA DRA Driver for GPUs）通过实现 DRA API，为 Kubernetes 工作负载提供现代化的 GPU 分配方式，支持受控共享和动态重新配置 GPU

- DRA：<https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/>

- NVIDIA DRA：<https://github.com/NVIDIA/k8s-dra-driver-gpu>

## 部署

添加`NVIDIA Helm`仓库并更新

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
```

安装版本为`25.3.2`的`NVIDIA DRA GPU`驱动程序。

```bash
helm install \
    nvidia-dra-driver-gpu nvidia/nvidia-dra-driver-gpu \
    --version="25.3.2" \
    --create-namespace --namespace nvidia-dra-driver-gpu \
    --set gpuResourcesEnabledOverride=true
```

验证`NVIDIA DRA`驱动是否正常运行，并确认GPU资源已成功上报到Kubernetes集群。

```bash
kubectl get deviceclass,resourceslice
```

部署使用 DRA GPU 的工作负载

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaimTemplate
metadata:
  name: single-gpu
spec:
  spec:
    devices:
      requests:
        - exactly:
            allocationMode: ExactCount
            deviceClassName: gpu.nvidia.com
            count: 1
          name: gpu

```

创建`resource-claim-template-pod.yaml`文件

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod1
  labels:
    app: pod
spec:
  containers:
    - name: ctr
      image: ubuntu:22.04
      command: ["bash", "-c"]
      args: ["nvidia-smi -L; trap 'exit 0' TERM; sleep 9999 & wait"]
      resources:
        claims:
          - name: gpu
  resourceClaims:
    - name: gpu
      resourceClaimTemplateName: single-gpu

```

