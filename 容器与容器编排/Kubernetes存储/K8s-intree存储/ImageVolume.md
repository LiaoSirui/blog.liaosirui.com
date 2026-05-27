## ImageVolume

允许在 Pod 中将 OCI 镜像作为卷使用。该功能可以将一个 OCI 镜像作为 volume 挂载到一个 Pod 中使用，从而可以在 Pod 中访问 OCI 镜像中存储的文件。

该功能是在当前 AI 技术大行其道背景下应运而生的，部署在 K8S 上的 AI 应用急需一种高效且通用的方式分发模型权重文件，此功能可以像分发镜像一样分发模型文件，用户只需要制作好包含了模型权重文件的 OCI 镜像，就可以在 POD 中挂载 OCI 镜像访问其内的模型文件，不再需要复制或者下载模型文件。

```yaml
kind: Pod
spec:
  containers:
    - …
      volumeMounts:
        - name: my-volume
          mountPath: /path/to/directory
  volumes:
    - name: my-volume
      image:
        pullPolicy: IfNotPresent
        reference: my-image:tag
```

这将为在 Kubernetes 中更灵活地管理镜像和卷的需求铺平道路，特别是对于 AI 和 ML 工作负载的复杂需求。

比如在大模型场景，有了 ImageVolume 支持，我们可以直接将大模型打包到镜像里，使用时直接挂载该镜像即可。

## 参考资料

- <https://www.lixueduan.com/posts/kubernetes/27-feature-image-volume/>