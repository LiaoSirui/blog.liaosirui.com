## 简介

针对 AI、大数据等多任务协作场景，对调度有 “All-or-Nothing” 的需求，即所有的任务在同一时间被调度。CoScheduling 是一套开源的方案，在 Kubernetes 集群中将一组 Pod（或称为 PodGroup）同时调度到同一个节点上。

在 Coscheduling 的场景中，最主要的原则是保证所有相关联的进程能够同时启动。防止部分进程的异常，导致整个关联进程组的阻塞。这种导致阻塞的部分异常进程，称之为 “碎片（fragement）”。

将 CoScheduler 作为第二调度器完成安装，pod 调度时需要指定 schedulerName 为 scheduler-plugins-scheduler

## 如何使用

PodGroup 是 CoScheduling 组件自定义资源，用来定义最少需要同时调度的 Pod 数。通过设置标签定义 Pod 属于哪一个 PodGroup。以下是 PodGroup 的 CRD 规范示例：

```yaml
# PodGroup CRD spec
apiVersion: scheduling.x-k8s.io/v1alpha1
kind: PodGroup
metadata:
  name: nginx
spec:
  scheduleTimeoutSeconds: 10
  minMember: 3
---
# Add a label `scheduling.x-k8s.io/pod-group` to mark the pod belongs to a group
labels:
  scheduling.x-k8s.io/pod-group: nginx
```

在调度程序中计算正在运行的 pod 和正在等待的 pod（假设但未绑定）的总和，如果总和大于或等于 minMember，则将创建等待 pod。同一 PodGroup 中具有不同优先级的 Pod 可能会导致意外行为，因此需要确保同一 PodGroup 中的 Pod 具有相同的优先级。

假设有一个只能容纳 3 个 nginx pod 的集群。创建一个 replicas = 6 的 ReplicaSet，并将 minMember 的值设置为 3。

```yaml
apiVersion: scheduling.x-k8s.io/v1alpha1
kind: PodGroup
metadata:
  name: nginx
spec:
  scheduleTimeoutSeconds: 10
  minMember: 3
---
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      name: nginx
      labels:
        app: nginx
        scheduling.x-k8s.io/pod-group: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          resources:
            limits:
              cpu: 3000m
              memory: 500Mi
            requests:
              cpu: 3000m
              memory: 500Mi

```

3 个 Pod 将一起被调度

如果此时修改 minMember 为 4，因不满足 PodGroup 定义的 minMember 为 3 的要求，所有的 nginx pod 都处于 pending 状态