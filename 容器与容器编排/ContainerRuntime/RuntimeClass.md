Kubernetes 自 v1.12 起引入了`RuntimeClass`资源，用于表示不同的容器运行时配置。它是混排策略的基石。每个`RuntimeClass`可以关联不同的底层运行时（如`runc`、`runsc`），并可以携带调度相关的标签。

设计思路：

1. 定义运行时类：为 Docker（默认）和 gVisor 分别创建 RuntimeClass。
2. 节点标记：在 K8s 节点上打标签，标识其支持的运行时（例如，所有节点都支持`runc`，部分专门节点支持`runsc`）。
3. Pod 调度：在 Pod 的`.spec.runtimeClassName`字段中指定所需的运行时。K8s 调度器会将其调度到具有相应能力的节点上。
4. 网络与存储考量：确保两种运行时下的 Pod 网络互通（通常使用 CNI 插件如 Calico、Cilium），并且持久卷能被正确挂载（gVisor 通过 Gofer 访问，需确保 CSI 驱动兼容）。

```yaml
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor  # 运行时类的名称
handler: runsc  # 对应 containerd 配置中定义的运行时名称
scheduling:
  nodeSelector:
    # 这是一个可选但推荐的做法：将 gVisor Pod 调度到特定节点
    sandbox.gvisor.io/runtime: enabled

---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: runc  # 显式定义默认运行时类，可选但更清晰
handler: runc  # 默认的 runc 运行时

```

部署使用 gVisor 的 Pod 创建一个明确要求使用`gvisor` RuntimeClass 的 Nginx Pod

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-gvisor
spec:
  runtimeClassName: gvisor  # 关键字段，指定使用 gVisor 沙箱
  containers:
    - name: nginx
      image: nginx:1.25-alpine  # 建议使用基于musl libc的Alpine镜像，兼容性更好
      ports:
        - containerPort: 80
      resources:
        requests:
          memory: "128Mi"
          cpu: "100m"
        limits:
          memory: "256Mi"
          cpu: "500m"
```

