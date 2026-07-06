## 核心概念

核心对象

```bash
┌──────────────────────────────────────────────────────┐
│                     Cohort                           │
│  ┌──────────────────┐   ┌──────────────────┐         │
│  │  ClusterQueue A  │   │  ClusterQueue B  │         │
│  │  (nominal: 5GPU) │   │  (nominal: 5GPU) │         │
│  │  borrowLimit: 5  │   │  borrowLimit: 5  │         │
│  └────────┬─────────┘   └────────┬─────────┘         │
│           │                      │                   │
│     ResourceFlavor: A100 / T4 / CPU                  │
└──────────────────────────────────────────────────────┘
         │                      │
    LocalQueue A            LocalQueue B    ← Namespaced
      (team-a)               (team-b)
         │                      │
    Workload 1             Workload 2       ← 用户的 Job
```

- ResourceFlavor：Flavor，代表不同类型的资源（如 A100 vs T4、Spot vs On-Demand），可以绑定 nodeLabels / taints

- ClusterQueue：集群级队列，定义资源配额（nominalQuota / borrowingLimit / lendingLimit），是配额管理的核心
- LocalQueue：命名空间级队列，用户直接和它打交道，指向一个 ClusterQueue
- Cohort：ClusterQueue 的组，同组内可以互相借调空闲配额
- Workload：Kueue 的调度单元，Kueue 会为每个 Job 自动创建对应的 Workload，用户一般不需要手动创建

一条完整的资源准入链路：

```bash
Job → LocalQueue → ClusterQueue → ResourceFlavor → Admission → Workload
```

一个 Job 从提交到运行，经过 Kueue 的完整流程：

```yaml
用户提交 Job (带 kueue.x-k8s.io/queue-name 标签)
  ↓
Kueue 自动创建 Workload 对象
  ↓
Workload 进入 LocalQueue → 找到对应的 ClusterQueue
  ↓
检查 ClusterQueue 是否有足够配额？（允许从 Cohort 借调）
  ├── 没有 → 询问 Cluster Autoscaler 能否扩容？ → 等待扩容
  ↓ (有配额 或 扩容完成)
检查 ClusterQueue 是否配置了 AdmissionCheck？
  ├── 有 → 等待所有 Check 通过 → 最终准入
  └── 没有 → 直接最终准入
  ↓
Kueue 注入 nodeAffinity/tolerations (锁定算力)
  ↓
Job Controller 创建 Pod
  ↓
Kube Scheduler 分配 Pod 到具体节点
  ↓
节点资源不足？ → 触发 Cluster Autoscaler 真正扩容节点 (Provision)
```

## ResourceFlavor

Kueue 要管资源，第一步得知道集群里有哪些 "种类" 的资源。集群里的 CPU、GPU 通常不是同构的：

- 价格和可用性 ：竞价型 vs 按需型虚拟机
- 架构 ：x86 vs ARM CPU
- 品牌和型号 ：Nvidia A100 vs T4 GPU

ResourceFlavor 就是干这个的 —— 给资源分个类，贴个标签，后面 ClusterQueue 按这个分类来管配额。

Kueue 在 Admission 阶段，会根据 ClusterQueue 中配置的 Flavor 顺序、Quota 是否满足、Flavor 是否匹配 Pod 等因素，选择一个可用的 ResourceFlavor。ResourceFlavor 定义资源的属性（标签、污点、容忍等），真正决定资源配额和公平性的仍然是 ClusterQueue。

### 空 Flavor

如果集群资源是同构的，或者不需要为不同资源规格分别管理配额，那直接创建一个不包含任何标签或污点的空 ResourceFlavor 即可：

```yaml
---
apiVersion: kueue.x-k8s.io/v1beta2
kind: ResourceFlavor
metadata:
  name: default-flavor
```

这类 ResourceFlavor 不承担节点筛选或污点控制的职责，仅作为统一的资源抽象存在，方便后续扩展不同资源类型。

### 只分类不加污点

```yaml
---
apiVersion: kueue.x-k8s.io/v1beta2
kind: ResourceFlavor
metadata:
  name: nvidia-gpu
spec:
  nodeLabels:
    node-role.kubernetes.io/nvidia-gpu: ""
```

`spec.nodeLabels`：通过 label 关联到对应的节点。具体实现上则是通过将 flavor 中 nodeLabels 部分自动注入到 Pod Spec 中的 nodeSelector，从而达到只将 Pod 调度到该 flavor 关联的节点上

这类 Flavor 实现了根据 label 将节点进行分类，算是名副其实。管理员先给节点打上对应 label 即可实现分类

但也只是简单做了分类，不是该 Flavor 中的 Job 也能手动调度到这些 GPU 节点。比较推荐的做法是给节点再打上污点，这样就不是随便能调度上去了：

```bash
kubectl taint node xxx nvidia.com/gpu=true:NoSchedule
```

节点打上污点后，Flavor 中的 Job 也不能调度了。Kueue 提供了两种模式来解决这个问题：

- 自动容忍模式 ：将污点容忍信息写到 ResourceFlavor，Kueue 自动给使用该 Flavor 的 Pod 加上容忍
- 手动容忍模式 ：将污点信息写到 ResourceFlavor，Kueue 做匹配拦截，只允许带了对应容忍的 Pod 使用该 Flavor

### 带污点

（1）自动污点容忍调度

```yaml
---
apiVersion: kueue.x-k8s.io/v1beta2
kind: ResourceFlavor
metadata:
  name: spot
spec:
  nodeLabels:
    instance-type: spot
  tolerations:
    - key: "spot-taint" # 节点上已有污点的 key
      operator: "Exists"
      effect: "NoSchedule" # 支持 NoSchedule 和 NoExecute

```

`spec.tolerations` ：声明该 flavor 关联节点上的污点容忍信息。Kueue 准入时自动注入到 Pod 的 `.spec.template.spec.tolerations`，确保 Pod 能容忍节点污点从而正常调度

（2）手动污点容忍

```yaml
---
apiVersion: kueue.x-k8s.io/v1beta2
kind: ResourceFlavor
metadata:
  name: spot
spec:
  nodeLabels:
    instance-type: spot
  nodeTaints:
    - key: spot
      effect: NoSchedule # 只支持 NoSchedule 和 NoExecute，PreferNoSchedule 会被忽略
      value: "true"

```

`spec.nodeTaints` ：在 flavor 上定义准入门槛。Kueue 不会自动注入容忍度，Pod 必须自己带对应 toleration 才能通过准入、拿到配额。

用户提交 Job 时必须自己带上 toleration，否则 Kueue 不批配额：

```yaml
spec:
  template:
    spec:
      tolerations:
        - key: spot
          operator: Exists
          effect: NoSchedule

```

`spec.nodeTaints` 通常应与节点上的真实污点保持一致。否则可能出现 Pod 过了 Kueue 准入、拿到配额，但 K8s 调度器发现节点有真污点而 Pod 没对应 toleration，最终调度失败 —— 白白占了配额。

本质就是把调度层面的拦截提前到 Kueue 准入层面。

## ClusterQueue

ClusterQueue 是 Kueue 配额管理的核心，定义了使用上限和公平共享规则

### 基础用法

一个基础的 ClusterQueue 示例如下：

```yaml
---
apiVersion: kueue.x-k8s.io/v1beta2
kind: ClusterQueue
metadata:
  name: "cluster-queue"
spec:
  namespaceSelector: {} # 匹配所有命名空间
  resourceGroups:
    - coveredResources: ["cpu", "memory", "pods"]
      flavors:
        - name: "default-flavor"
          resources:
            - name: "cpu"
              nominalQuota: 9
            - name: "memory"
              nominalQuota: 36Gi
            - name: "pods"
              nominalQuota: 5

```

字段解析：

- `spec.namespaceSelector`：指定该 ClusterQueue 可以在哪些 namespace 被使用。当前 ClusterQueue 可以被任意 Namespace 使用
- `resourceGroups`：资源组，定义 ClusterQueue 的资源额度，可以有多个，每个组都是独立的
  - `coveredResources`：管哪些资源，同一个 group 里面的资源必须在同一个 flavor 里面分配
  - `flavors`：可以有多个，分配是按顺序尝试
    - `name`：使用名称引用前面创建的 ResourceFlavor
    - `resources`：在这个 flavor 下，每种资源的配额上限
      - `nominalQuota`：保底配额，表示该 ClusterQueue 的名义配额，优先保障自身使用；未使用的部分可以按照 borrowing / lending 规则被其他 Queue 借用
      - `borrowingLimit`：最多能从 Cohort 里借入多少，所以最多能用 nominalQuota + borrowingLimit
      - `lendingLimit`：最多允许别人从这借走多少（当空闲时），需要时可通过预抢占收回
  

以 cpu 为例，基于上面三个配额字段，可以使用的范围是 nominalQuota ~ (nominalQuota + borrowingLimit)

### 调度顺序

排队策略

```yaml
spec:
  queueingStrategy: BestEffortFIFO
```

- `BestEffortFIFO`（默认）：前面的 Job 拿不到配额，后面的能插队先跑，资源利用率高。
- `StrictFIFO` ：前面的 Job 拿不到配额，后面的必须等，适合有顺序依赖的 Pipeline。

### 资源共享

加入 Cohort

```yaml
spec:
  cohortName: research-cohort
```

- `cohortName` ：关联到一个 Cohort，同一个 Cohort 里的 ClusterQueue 可以互相共享资源。

### 抢占相关

当 ClusterQueue 或其 Cohort 中没有足够的配额时，新进入的 Workload 可以触发预抢占，挤掉低优先级的 Workload。涉及两个配置项：

- 预抢占策略
- 优先抢占还是借用

（1）预抢占策略

```yaml
spec:
  preemption:
    reclaimWithinCohort: Any                # 可抢占 Cohort 中超过名义配额的 Workload
    borrowWithinCohort:
      policy: LowerPriority                 # 借用时只抢占低优先级（不能与 Fair Sharing 一同使用）
      maxPriorityThreshold: 100             # 且仅抢占优先级 ≤ 100 的 Workload
    withinClusterQueue: LowerPriority       # 同队列内，低优先级让路给高优先级
```

- `reclaimWithinCohort` ：是否可抢占 Cohort 中使用了超过其名义配额的 Workload
  - `Never`（默认）不抢占
  - `LowerPriority` 仅抢占低优先级
  - `Any` 可抢占任意优先级
- `borrowWithinCohort` ：当需要借用配额时是否触发抢占
  - `Never`（默认）不触发
  - `LowerPriority` 仅抢占 Cohort 中低优先级的 Workload（需同时启用 `reclaimWithinCohort`）
  - 注意：只能配置经典抢占，不能与 Fair Sharing 一同使用

- `withinClusterQueue` ：同队列内，当待处理 Workload 不适合配额时，是否可抢占同队列中的活动 Workload。
  - `Never`（默认）不抢占
  - `LowerPriority` 仅抢占低优先级
  - `LowerOrNewerEqualPriority` 抢占低优先级或同优先级的


（2）优先抢占还是借用

```yaml
spec:
  flavorFungibility:
    whenCanBorrow: TryNextFlavor
    whenCanPreempt: MayStopSearch
```

当 ClusterQueue 有多个 flavor 时，Kueue 按顺序尝试。当当前 flavor 配额用完时，可以影响 Kueue 的行为：

- `whenCanBorrow` ：能从 Cohort 借的时候
  - `MayStopSearch`（默认）：借了就停，不再试下一个
  - `TryNextFlavor`：不借，先试下一个 flavor

- `whenCanPreempt` ：能抢占低优先级 Job 的时候
  - `TryNextFlavor`（默认）：先试下一个 flavor
  - `MayStopSearch`：不试了，直接抢占


### 运维控制：停止策略

控制队列的运行状态，ClusterQueue 和 LocalQueue 都支持。

- `None`（默认） ：正常运行，新 Job 正常准入，已运行的不受影响。
- `Hold` ：停止新的准入，已准入的不受影响，适合维护、配额调整等临时场景。
- `HoldAndDrain` ：停止新的准入 + 触发已准入工作负载的驱逐，适合紧急情况需要立刻清场。

维护完恢复为 `None` 或直接删掉这个字段即可。这是运维操作，不是常态配置。

```yaml
spec:
  stopPolicy: Hold
```

### 完整示例

```yaml
apiVersion: kueue.x-k8s.io/v1beta2
kind: ClusterQueue
metadata:
  name: ai-team-cq
spec:
  # 1. 加入 Cohort，允许和其他 ClusterQueue 共享资源
  cohortName: research-cohort

  # 2. 排队策略
  queueingStrategy: BestEffortFIFO # 默认。StrictFIFO 会阻塞

  # 3. 命名空间选择器（谁能用这个 ClusterQueue）
  namespaceSelector:
    matchLabels:
      team: ai

  # 4. 抢占策略
  preemption:
    reclaimWithinCohort: Any # 可抢占 Cohort 中超过名义配额的 Workload
    borrowWithinCohort:
      policy: LowerPriority # 借用时只抢占低优先级（不能与 Fair Sharing 一同使用）
      maxPriorityThreshold: 100 # 且仅抢占优先级 ≤ 100 的 Workload
    withinClusterQueue: LowerPriority # 同队列内，低优先级让路给高优先级

  # 5. 配置是优先抢占还是借用
  flavorFungibility:
    whenCanBorrow: TryNextFlavor
    whenCanPreempt: MayStopSearch

  # 6. 停止策略
  # stopPolicy:  Hold

  # 7. 资源组定义
  resourceGroups:
    - coveredResources: ["cpu", "memory"] # 第一组：计算资源
      flavors:
        - name: default- flavor
          resources:
            - name: cpu
              nominalQuota: 16 # 保底配额
              borrowingLimit: 8 # 最多能从 Cohort 借多少
              lendingLimit: 8 # 最多允许别人借多少
            - name: memory
              nominalQuota: 64Gi
              borrowingLimit: 32Gi
              lendingLimit: 32Gi

    - coveredResources: ["nvidia.com/gpu"] # 第二组：GPU 资源
      flavors:
        - name: a100
          resources:
            - name: nvidia.com/gpu
              nominalQuota: 4
              borrowingLimit: 2
        - name: t4
          resources:
            - name: nvidia.com/gpu
              nominalQuota: 8

```

## LocalQueue

ClusterQueue 是集群级别的，但用户不能直接往里塞 Job。中间还需要一层 LocalQueue—— 它是一个命名空间对象，指向一个 ClusterQueue，作为用户提交 Job 的入口。

```yaml
---
apiVersion: kueue.x-k8s.io/v1beta2
kind: LocalQueue
metadata:
  namespace: team-a
  name: team-a-queue
spec:
  clusterQueue: cluster-queue

```

## Cohort

如果每个 ClusterQueue 只能用自己的保底配额，那 team-a 闲着 3 核、team-b 想多跑 1 核也借不到，资源就浪费了。Cohort 就是解决这个的 —— 可以理解成一个 "资源共享联盟"，加进同一个 Cohort 的 ClusterQueue 可以互相借配额。

它本身能定义 resourceGroups（共享配额池），这些资源是管理员额外划拨给整个的公共池，而不是把各个 ClusterQueue 的 nominalQuota 自动汇总得到的。

### 基本用法

```yaml
---
# 创建 Cohort
apiVersion: kueue.x-k8s.io/v1beta2
kind: Cohort
metadata:
name: default-cohort
spec:
  resourceGroups:
    - coveredResources: ["cpu"]
      flavors:
        - name: default-flavor
          resources:
            - name: cpu
              nominalQuota: 12 # Cohort 级别的共享配额（额外资源）

---
# ClusterQueue A 加入 Cohort
apiVersion: kueue.x-k8s.io/v1beta2
kind: ClusterQueue
metadata:
  name: team-a-cq
spec:
  cohortName: default-cohort
  resourceGroups:
    - coveredResources: ["cpu"]
      flavors:
        - name: default-flavor
          resources:
            - name: cpu
              nominalQuota: 4
              borrowingLimit: 4 # 最多借 4 核
              lendingLimit: 2 # 最多出借 2 核

---
# ClusterQueue B 也加入同一个 Cohort
apiVersion: kueue.x-k8s.io/v1beta2
kind: ClusterQueue
metadata:
  name: team-b-cq
spec:
  cohortName: default-cohort
  resourceGroups:
    - coveredResources: ["cpu"]
      flavors:
        - name: default-flavor
          resources:
            - name: cpu
              nominalQuota: 4
              borrowingLimit: 4
              lendingLimit: 2

```

上面的配置：

- 两个队列各有 4 核保底，Cohort 自己配置的一组共享配额 12 核。（总计可用 20 核）
- 空闲时可以互相借用
- 如果 ClusterQueue 想从 Cohort 借用资源，它必须为该资源和 Flavor 定义 `nominalQuota`（即使值为 0）

### 分层 Cohort（Hierarchical Cohorts）

Cohort 可以组织成树形结构（CohortTree），适合大型组织：

```yaml
---
# 根 Cohort
apiVersion: kueue.x-k8s.io/v1beta2
kind: Cohort
metadata:
  name: root-cohort

---
# AI 部门 Cohort
apiVersion: kueue.x-k8s.io/v1beta2
kind: Cohort
metadata:
  name: ai-dept
spec:
  parentName: root-cohort # 父节点
  fairSharing:
    weight: "0.75"

---
# 大数据部门 Cohort
apiVersion: kueue.x-k8s.io/v1beta2
kind: Cohort
metadata:
  name: bigdata-dept
spec:
  parentName: root-cohort # 父节点
  fairSharing:
    weight: "0.25"

```

同一个 CohortTree 中的 ClusterQueue 可以使用其中的资源，遵循为 Cohort 和 ClusterQueue 指定的借用和借出限制。

```bash
root-cohort（总资源池）
├── ai-dept（权重 0.75 → 趋向使用 75% 公共资源）
│   ├── team-a-cq
│   └── team-b-cq
└── bigdata-dept（权重 0.25 → 趋向使用 25% 公共资源）
    ├── spark-cq
    └── flink-cq
```

Cohort 让多个 ClusterQueue 可以互相借资源。

## Workload

前面四个都是 "配置"，那 Kueue 真正调度、准入的对象是什么？是 Workload—— 一个要运行至完成的应用，由一个或多个 Pod 组成。Kueue 的 Admission、Quota Accounting、Preemption 全是围绕它展开的。

通常不需要手动创建 Workload，Kueue 会为每个 Job 自动创建。但理解它的结构有助于排查问题。

### 关键字段

```yaml
apiVersion: kueue.x-k8s.io/v1beta2
kind: Workload
metadata:
  name: sample-job
  namespace: team-a
spec:
  active: true # 设为 false 可停止 Workload（已运行的会被驱逐且不重新排队）
  queueName: team-a-queue # 指向 LocalQueue
  podSets: # Pod 组定义（Kueue 从 Job 自动提取）
    - name: main
      count: 3 # Pod 数量
      template:
        spec:
          containers:
            - name: container
              image: registry.k8s.io/e2e-test-images/agnhost:latest
              resources:
                requests:
                  cpu: "1"
                  memory: 200Mi
  maximumExecutionTimeSeconds: 3600 # Workload 处于 Admitted 状态超过此秒数后自动停用

```

### 优先级

Workload 的优先级影响准入顺序，有两种设置方式：

- Pod 优先级 ：对于 `batch/v1.Job`，Kueue 根据 Job 的 Pod 模板的 Pod 优先级设置 Workload 的优先级
- WorkloadPriorityClass ：独立管理工作负载的排队和抢占优先级，与 Pod 调度优先级分离

```yaml
---
apiVersion: kueue.x-k8s.io/v1beta2
kind: WorkloadPriorityClass
metadata:
  name: high-priority
value: 1000
description: "高优先级训练任务"

```

### 资源请求计算

Kueue 将 Workload 的总资源使用量计算为每个 podSet 资源请求的总和：`podSet 的资源使用量 = Pod 规格的资源请求 × count`

Kueue 会根据 Limit Ranges 和 Runtime Class Overhead 调整资源使用量。

Workload 才是 Kueue 真正调度和准入的对象，前面四个对象都是给它配规则的。