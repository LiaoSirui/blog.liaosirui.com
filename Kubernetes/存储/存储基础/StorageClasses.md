## 存储类

存储类简介：

<https://kubernetes.io/zh-cn/docs/concepts/storage/storage-classes/>

## 回收策略

由 StorageClass 动态创建的 PersistentVolume 会在类的 `reclaimPolicy` 字段中指定回收策略，可以是 `Delete` 或者 `Retain`。如果 StorageClass 对象被创建时没有指定 `reclaimPolicy`，它将默认为 `Delete`。

通过 StorageClass 手动创建并管理的 PersistentVolume 会使用它们被创建时指定的回收策略。
