```yaml
apiVersion: storage.k8s.io/v1
kind: CSIDriver
metadata:
  name: hostpath.csi.k8s.io
spec:
  # Supports persistent and ephemeral inline volumes.
  volumeLifecycleModes:
  - Persistent
  - Ephemeral
  # To determine at runtime which mode a volume uses, pod info and its
  # "csi.storage.k8s.io/ephemeral" entry are needed.
  podInfoOnMount: true
  fsGroupPolicy: None
```

- fsGroup

官方文档：<https://kubernetes-csi.github.io/docs/support-fsgroup.html>

- volumeLifecycleModes - Ephemeral

Kubernetes 利用外部存储驱动提供出来的存储卷一般来说都是持久化的，它的生命周期可以完全独立于 Pod，（特定情况下）也可以和第一个用到该卷的 Pod（[后绑定模式](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode)）有着宽松的耦合关系。在 Kubernetes 中使用 PVC 和 PV 对象完成了存储卷的申请和供给机制。起初，容器存储接口（CSI）支持的存储卷只能用于 PVC/PV 的场合。

但有些情况下，数据卷的内容和生命周期是和 Pod 紧密相关的。例如有的驱动会使用动态的创建 Secret 生成卷，这个 Secret 是为了运行在 Pod 中的应用特意创建的。这种卷需要和 Pod 一起生成，并且作为 Pod 的一部分，和 Pod 一起终结。可以在 Pod Spec 中（用内联/inline 的方式）定义这种卷。

