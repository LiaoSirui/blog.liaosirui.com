## Volcano

基于 Kubernetes 的高性能工作负载调度引擎。

主要是解决 Kubernetes (K8s) 在处理高性能、大规模批处理工作负载（如 AI 训练、大数据处理、科学计算、基因组学）时的不足。它通过提供高级调度算法（如 Gang Scheduling）、异构资源管理（CPU/GPU/FPGA）和完整的作业生命周期管理，弥补了原生 K8s 调度器的短板，实现高效资源利用、任务隔离和稳定执行，让批处理任务在 K8s 上能高效、公平地运行

> Gang scheduling 是一种保证一组相关任务同步执行的调度策略，多个任务的作业调度时，要么全部成功，要么全部失败，这种调度场景，称作为 Gang scheduling

主要解决的问题与能力：

1. 批处理调度：原生 K8s 对批处理任务支持不佳，Volcano 引入专业的批处理调度器，支持 Gang Scheduling（成组调度），确保一组相关的 Pod 要么全部运行，要么都不运行，避免死锁。
2. 资源管理：提供精细化资源管理（如资源预留、队列、优先级抢占），支持 CPU、GPU、FPGA 等异构硬件的混合调度。
3. 作业生命周期管理：提供强大的作业管理和队列管理功能，支持复杂的任务依赖和容错，例如支持多 Pod 模板、错误处理。
4. 框架集成：与 Spark、TensorFlow、PyTorch、Flink 等主流计算框架无缝集成，方便用户在 K8s 上容器化运行各种高性能计算应用。
5. 资源利用率：通过在线离线混部、资源超卖等技术，提升集群整体资源利用率。
6. 性能优化：针对 HPC 场景进行性能优化，提升调度吞吐量和伸缩性。

文档：

- <https://volcano.sh/zh/docs/tutorials/>
- 安装：<https://volcano.sh/zh/docs/installation/>
- GitHub 仓库：<https://github.com/volcano-sh/volcano>

## 架构

<img src="./.assets/Vocalno简介/volcano-arch2.png" alt="volcano-arch2.png" style="zoom:67%;" />

Volcano 包括以下组件:

- Volcano Scheduler：通过一系列的 action 和 plugin 调度 Job，并为它找到一个最适合的节点。与 Kubernetes default-scheduler 相比，Volcano 与众不同的 地方是它支持针对 Job 的多种调度算法。
- Volcano ControllerManager： Volcano controllermanager 管理 CRD 资源的生命周期。它主要由 Queue ControllerManager、 PodGroupControllerManager、 VCJob ControllerManager 构成。
- Volcano Admission： Volcano admission 负责对 CRD API 资源进行校验。
- CRD：Job、Queue、PodGroup 等自定义资源。
- vcctl：Volcano vcctl 是 Volcano 的命令行客户端工具。

Volcano 通过 CRD 扩展了 K8s 对象，然后自定义 Controller 和 Scheduler 进行管理以及调度。

## 部署

兼容性矩阵：<https://github.com/volcano-sh/volcano?tab=readme-ov-file#kubernetes-compatibility>

提供 helm chart 部署

```bash
helm repo add volcano-sh https://volcano-sh.github.io/helm-charts
```

## Volcano 简单使用

首先创建一个名为 test 的 Queue

```bash
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.volcano.sh/v1beta1
kind: Queue
metadata:
  name: test
  namespace: demo-workloads
spec:
  weight: 1
  reclaimable: false
  capability:
    cpu: 2
EOF

```

再创建一个名为`job-1` 的 Volcano Job。

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch.volcano.sh/v1alpha1
kind: Job
metadata:
  name: job-1
  namespace: demo-workloads
spec:
  minAvailable: 1
  schedulerName: volcano
  queue: test
  policies:
    - event: PodEvicted
      action: RestartJob
  tasks:
    - replicas: 1
      name: runner
      policies:
        - event: TaskCompleted
          action: CompleteJob
      template:
        spec:
          containers:
            - name: runner
              image: harbor.alpha-quant.tech/3rd_party/docker.io/rockylinux/rockylinux:9.6.20250531
              command:
                - sleep
                - 10m
              resources:
                requests:
                  cpu: 1
                limits:
                  cpu: 1
EOF
```

Volcano Job 和 K8s 原生 Job 类似，不过也多了几个字段：

```yaml
spec:
  minAvailable: 1
  schedulerName: volcano
  queue: test
  policies:
    - event: PodEvicted
      action: RestartJob
```

- minAvailable：需要满足最小数量后才进行调度
- schedulerName：指定调度器
- queue：指定 Job 所属的队列，就是前面创建的队列
- policies：一些特殊策略

检查 Job 的状态

```bash
kubectl get vcjob -n demo-workloads job-1 -oyaml
```

检查 PodGroup 的状态

```bash
kubectl get podgroup -n demo-workloads -oyaml
```

检查 Queue 的状态

```bash
kubectl get queue -n demo-workloads test -oyaml
```

