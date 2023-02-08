## Kube-Capacity 简介

Kube-capacity 是一个简单而强大的 CLI，它提供了 Kubernetes 集群中资源请求、限制和利用率的概览。

它将输出的最佳部分结合 kubectl top 到 kubectl describe 一个易于使用的集中于集群资源的 CLI 中。

官方地址：

- Github 仓库：<https://github.com/robscott/kube-capacity.git>

使用 Kube-capacity CLI 查看 Kubernetes 资源请求、限制和利用率。

## 安装

Go 二进制文件由 GoReleaser 随每个版本自动构建。这些可以在此项目的 GitHub 发布页面上访问。

- <https://github.com/robscott/kube-capacity/releases>

使用 krew 进行安装

```bash
kubectl krew install resource-capacity
```

## 使用示例

比如想看这个 kube-system 下有哪些 pod 有没有设置 request 和 limit 的时候，实际上，需要输入一段很长的命令才能列出，而且需要一些调试，这看起来不是特别方便。

```bash
kubectl get pod \
-n kube-system \
-o=custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,PHASE:.status.phase,Request-cpu:.spec.containers\[0\].resources.requests.cpu,Request-memory:.spec.containers\[0\].resources.requests.memory,Limit-cpu:.spec.containers\[0\].resources.limits.cpu,Limit-memory:.spec.containers\[0\].resources.limits.memory
```

那么这个工具实际上解决的问题就是帮助快速查看概览整个集群和 pod 的资源配置情况。

### 默认输出

默认情况下，kube-capacity 将输出一个节点列表，其中包含 CPU 和内存资源请求的总数以及在它们上运行的所有 pod 的限制。

对于具有多个节点的集群，第一行还将包括集群范围的总数。该输出将如下所示：

```bash
> kubectl resource-capacity

NODE        CPU REQUESTS   CPU LIMITS   MEMORY REQUESTS   MEMORY LIMITS
*           2570m (4%)     300m (0%)    1464Mi (0%)       4802Mi (2%)
devmaster   1350m (4%)     0Mi (0%)     620Mi (0%)        1754Mi (1%)
devnode1    750m (4%)      200m (1%)    506Mi (1%)        2036Mi (6%)
devnode2    470m (2%)      100m (0%)    338Mi (1%)        1012Mi (3%)
```

### 包含 Pod

对于更详细的输出，kube-capacity 可以在输出中包含 pod。

当 `-p` 或 `--pods` 被传递给 kube-capacity 时，它将包含如下所示的特定于 pod 的输出

```bash
> kubectl resource-capacity --pods

NODE        NAMESPACE           POD                                                CPU REQUESTS   CPU LIMITS   MEMORY REQUESTS   MEMORY LIMITS
*           *                   *                                                  2570m (4%)     300m (0%)    1464Mi (0%)       4802Mi (2%)

devmaster   *                   *                                                  1350m (4%)     0Mi (0%)     620Mi (0%)        1754Mi (1%)
devmaster   kube-system         cilium-8nhjq                                       100m (0%)      0Mi (0%)     100Mi (0%)        0Mi (0%)
devmaster   openshift-console   console-deployment-5c744f5489-m8gzr                0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   kube-system         coredns-59c4585f6d-9cvxp                           100m (0%)      0Mi (0%)     70Mi (0%)         170Mi (0%)
devmaster   beegfs-csi          csi-beegfs-node-5jzj6                              240m (0%)      0Mi (0%)     50Mi (0%)         384Mi (0%)
devmaster   kube-system         csi-nfs-controller-7dd749b445-99nrs                30m (0%)       0Mi (0%)     60Mi (0%)         700Mi (0%)
devmaster   kube-system         csi-nfs-node-8xpzf                                 30m (0%)       0Mi (0%)     60Mi (0%)         500Mi (0%)
devmaster   kube-system         etcd-devmaster                                     100m (0%)      0Mi (0%)     100Mi (0%)        0Mi (0%)
devmaster   ingress-nginx       ingress-nginx-controller-554fc6d9b4-cn42z          100m (0%)      0Mi (0%)     90Mi (0%)         0Mi (0%)
devmaster   ingress-nginx       ingress-nginx-outer-controller-5f7cdbc7d5-vb95k    100m (0%)      0Mi (0%)     90Mi (0%)         0Mi (0%)
devmaster   kube-system         kube-apiserver-devmaster                           250m (0%)      0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   kube-system         kube-controller-manager-devmaster                  200m (0%)      0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   kube-system         kube-scheduler-devmaster                           100m (0%)      0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   kube-system         kube-state-metrics-878cdb96d-dmgdg                 0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   metallb-system      metallb-controller-55588949b6-9jb82                0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   metallb-system      metallb-speaker-4k5gt                              0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   kube-system         metrics-server-79b6bfdff-z28tg                     0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devmaster   tdengine-system     tdengine-0                                         0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)

devnode1    *                   *                                                  750m (4%)      200m (1%)    506Mi (1%)        2036Mi (6%)
devnode1    aipaas-system       aipaas-reloader-6c54885989-v8vnp                   100m (0%)      100m (0%)    128Mi (0%)        512Mi (1%)
devnode1    kube-system         cilium-operator-88cff96c5-gbgc2                    0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devnode1    kube-system         cilium-vd27h                                       100m (0%)      0Mi (0%)     100Mi (0%)        0Mi (0%)
devnode1    beegfs-csi          csi-beegfs-controller-0                            180m (1%)      0Mi (0%)     40Mi (0%)         512Mi (1%)
devnode1    beegfs-csi          csi-beegfs-node-lmdm9                              240m (1%)      0Mi (0%)     50Mi (0%)         384Mi (1%)
devnode1    kube-system         csi-nfs-node-9xqh2                                 30m (0%)       0Mi (0%)     60Mi (0%)         500Mi (1%)
devnode1    aipaas-system       local-path-provisioner-data-path-9f887cb8d-vfkl8   100m (0%)      100m (0%)    128Mi (0%)        128Mi (0%)
devnode1    metallb-system      metallb-speaker-2f8xz                              0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devnode1    tdengine-system     tdengine-2                                         0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)

devnode2    *                   *                                                  470m (2%)      100m (0%)    338Mi (1%)        1012Mi (3%)
devnode2    kube-system         cilium-lw2x8                                       100m (0%)      0Mi (0%)     100Mi (0%)        0Mi (0%)
devnode2    kube-system         cilium-operator-88cff96c5-lg9mb                    0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devnode2    beegfs-csi          csi-beegfs-node-njgdb                              240m (1%)      0Mi (0%)     50Mi (0%)         384Mi (1%)
devnode2    kube-system         csi-nfs-node-5mldq                                 30m (0%)       0Mi (0%)     60Mi (0%)         500Mi (1%)
devnode2    kube-system         hubble-relay-7f8bf4b688-nfb9d                      0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devnode2    kube-system         hubble-ui-55b967c7d6-hr7jm                         0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devnode2    local-apps          local-apps-frpc-0                                  0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devnode2    aipaas-system       local-path-provisioner-bfs-path-9985b599d-c2r6z    100m (0%)      100m (0%)    128Mi (0%)        128Mi (0%)
devnode2    metallb-system      metallb-speaker-7bzs4                              0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
devnode2    tdengine-system     tdengine-1                                         0Mi (0%)       0Mi (0%)     0Mi (0%)          0Mi (0%)
```

### 包含利用率

为了帮助了解资源利用率与配置的请求和限制的比较，kube-capacity 可以在输出中包含利用率指标。

请务必注意，此输出依赖于集群中的 metrics-server 正常运行。

当 `-u` 或 `--util` 被传递给 kube-capacity 时，它将包含如下所示的资源利用率信息：

```bash
> kubectl resource-capacity --util

NODE        CPU REQUESTS   CPU LIMITS   CPU UTIL    MEMORY REQUESTS   MEMORY LIMITS   MEMORY UTIL
*           2570m (4%)     300m (0%)    183m (0%)   1464Mi (0%)       4802Mi (2%)     34562Mi (18%)
devmaster   1350m (4%)     0Mi (0%)     142m (0%)   620Mi (0%)        1754Mi (1%)     27904Mi (21%)
devnode1    750m (4%)      200m (1%)    20m (0%)    506Mi (1%)        2036Mi (6%)     3314Mi (10%)
devnode2    470m (2%)      100m (0%)    21m (0%)    338Mi (1%)        1012Mi (3%)     3345Mi (10%)
```

### 包括 Pod 和利用率

对于更详细的输出，kube-capacity 可以在输出中包含 pod 和资源利用率。当 `--util` 和 `--pods` 传递给 kube-capacity 时，它将产生如下所示的宽输出：

```bash
> kubectl resource-capacity --util --pods

NODE        NAMESPACE           POD                                                CPU REQUESTS   CPU LIMITS   CPU UTIL    MEMORY REQUESTS   MEMORY LIMITS   MEMORY UTIL
*           *                   *                                                  2570m (4%)     300m (0%)    183m (0%)   1464Mi (0%)       4802Mi (2%)     34596Mi (18%)

devmaster   *                   *                                                  1350m (4%)     0Mi (0%)     140m (0%)   620Mi (0%)        1754Mi (1%)     27954Mi (21%)
devmaster   kube-system         cilium-8nhjq                                       100m (0%)      0Mi (0%)     3m (0%)     100Mi (0%)        0Mi (0%)        861Mi (0%)
devmaster   openshift-console   console-deployment-5c744f5489-m8gzr                0Mi (0%)       0Mi (0%)     1m (0%)     0Mi (0%)          0Mi (0%)        66Mi (0%)
devmaster   kube-system         coredns-59c4585f6d-9cvxp                           100m (0%)      0Mi (0%)     1m (0%)     70Mi (0%)         170Mi (0%)      40Mi (0%)
devmaster   beegfs-csi          csi-beegfs-node-5jzj6                              240m (0%)      0Mi (0%)     2m (0%)     50Mi (0%)         384Mi (0%)      71Mi (0%)
devmaster   kube-system         csi-nfs-controller-7dd749b445-99nrs                30m (0%)       0Mi (0%)     1m (0%)     60Mi (0%)         700Mi (0%)      74Mi (0%)
devmaster   kube-system         csi-nfs-node-8xpzf                                 30m (0%)       0Mi (0%)     1m (0%)     60Mi (0%)         500Mi (0%)      54Mi (0%)
devmaster   kube-system         etcd-devmaster                                     100m (0%)      0Mi (0%)     9m (0%)     100Mi (0%)        0Mi (0%)        90Mi (0%)
devmaster   ingress-nginx       ingress-nginx-controller-554fc6d9b4-cn42z          100m (0%)      0Mi (0%)     2m (0%)     90Mi (0%)         0Mi (0%)        323Mi (0%)
devmaster   ingress-nginx       ingress-nginx-outer-controller-5f7cdbc7d5-vb95k    100m (0%)      0Mi (0%)     3m (0%)     90Mi (0%)         0Mi (0%)        326Mi (0%)
devmaster   kube-system         kube-apiserver-devmaster                           250m (0%)      0Mi (0%)     16m (0%)    0Mi (0%)          0Mi (0%)        568Mi (0%)
devmaster   kube-system         kube-controller-manager-devmaster                  200m (0%)      0Mi (0%)     5m (0%)     0Mi (0%)          0Mi (0%)        89Mi (0%)
devmaster   kube-system         kube-scheduler-devmaster                           100m (0%)      0Mi (0%)     2m (0%)     0Mi (0%)          0Mi (0%)        45Mi (0%)
devmaster   kube-system         kube-state-metrics-878cdb96d-dmgdg                 0Mi (0%)       0Mi (0%)     1m (0%)     0Mi (0%)          0Mi (0%)        29Mi (0%)
devmaster   metallb-system      metallb-controller-55588949b6-9jb82                0Mi (0%)       0Mi (0%)     1m (0%)     0Mi (0%)          0Mi (0%)        46Mi (0%)
devmaster   metallb-system      metallb-speaker-4k5gt                              0Mi (0%)       0Mi (0%)     2m (0%)     0Mi (0%)          0Mi (0%)        40Mi (0%)
devmaster   kube-system         metrics-server-79b6bfdff-z28tg                     0Mi (0%)       0Mi (0%)     2m (0%)     0Mi (0%)          0Mi (0%)        48Mi (0%)
devmaster   tdengine-system     tdengine-0                                         0Mi (0%)       0Mi (0%)     3m (0%)     0Mi (0%)          0Mi (0%)        69Mi (0%)

devnode1    *                   *                                                  750m (4%)      200m (1%)    22m (0%)    506Mi (1%)        2036Mi (6%)     3309Mi (10%)
devnode1    aipaas-system       aipaas-reloader-6c54885989-v8vnp                   100m (0%)      100m (0%)    1m (0%)     128Mi (0%)        512Mi (1%)      30Mi (0%)
devnode1    kube-system         cilium-operator-88cff96c5-gbgc2                    0Mi (0%)       0Mi (0%)     1m (0%)     0Mi (0%)          0Mi (0%)        36Mi (0%)
devnode1    kube-system         cilium-vd27h                                       100m (0%)      0Mi (0%)     3m (0%)     100Mi (0%)        0Mi (0%)        412Mi (1%)
devnode1    beegfs-csi          csi-beegfs-controller-0                            180m (1%)      0Mi (0%)     1m (0%)     40Mi (0%)         512Mi (1%)      42Mi (0%)
devnode1    beegfs-csi          csi-beegfs-node-lmdm9                              240m (1%)      0Mi (0%)     2m (0%)     50Mi (0%)         384Mi (1%)      60Mi (0%)
devnode1    kube-system         csi-nfs-node-9xqh2                                 30m (0%)       0Mi (0%)     1m (0%)     60Mi (0%)         500Mi (1%)      56Mi (0%)
devnode1    aipaas-system       local-path-provisioner-data-path-9f887cb8d-vfkl8   100m (0%)      100m (0%)    1m (0%)     128Mi (0%)        128Mi (0%)      21Mi (0%)
devnode1    metallb-system      metallb-speaker-2f8xz                              0Mi (0%)       0Mi (0%)     2m (0%)     0Mi (0%)          0Mi (0%)        38Mi (0%)
devnode1    tdengine-system     tdengine-2                                         0Mi (0%)       0Mi (0%)     3m (0%)     0Mi (0%)          0Mi (0%)        55Mi (0%)

devnode2    *                   *                                                  470m (2%)      100m (0%)    22m (0%)    338Mi (1%)        1012Mi (3%)     3335Mi (10%)
devnode2    kube-system         cilium-lw2x8                                       100m (0%)      0Mi (0%)     3m (0%)     100Mi (0%)        0Mi (0%)        413Mi (1%)
devnode2    kube-system         cilium-operator-88cff96c5-lg9mb                    0Mi (0%)       0Mi (0%)     1m (0%)     0Mi (0%)          0Mi (0%)        32Mi (0%)
devnode2    beegfs-csi          csi-beegfs-node-njgdb                              240m (1%)      0Mi (0%)     2m (0%)     50Mi (0%)         384Mi (1%)      59Mi (0%)
devnode2    kube-system         csi-nfs-node-5mldq                                 30m (0%)       0Mi (0%)     1m (0%)     60Mi (0%)         500Mi (1%)      50Mi (0%)
devnode2    kube-system         hubble-relay-7f8bf4b688-nfb9d                      0Mi (0%)       0Mi (0%)     1m (0%)     0Mi (0%)          0Mi (0%)        25Mi (0%)
devnode2    kube-system         hubble-ui-55b967c7d6-hr7jm                         0Mi (0%)       0Mi (0%)     0m (0%)     0Mi (0%)          0Mi (0%)        28Mi (0%)
devnode2    local-apps          local-apps-frpc-0                                  0Mi (0%)       0Mi (0%)     1m (0%)     0Mi (0%)          0Mi (0%)        25Mi (0%)
devnode2    aipaas-system       local-path-provisioner-bfs-path-9985b599d-c2r6z    100m (0%)      100m (0%)    1m (0%)     128Mi (0%)        128Mi (0%)      21Mi (0%)
devnode2    metallb-system      metallb-speaker-7bzs4                              0Mi (0%)       0Mi (0%)     3m (0%)     0Mi (0%)          0Mi (0%)        35Mi (0%)
devnode2    tdengine-system     tdengine-1                                         0Mi (0%)       0Mi (0%)     3m (0%)     0Mi (0%)          0Mi (0%)        63Mi (0%)
```

值得注意的是，来自 pod 的利用率数字可能不会与总节点利用率相加。与节点和集群级别数字代表 pod 值总和的请求和限制数字不同，节点指标直接来自指标服务器，并且可能包括其他形式的资源利用率。

### 排序

要突出显示具有最高指标的节点、pod 和容器，您可以按各种列进行排序：

```bash
kubectl resource-capacity --util --sort cpu.util
```

### 显示 Pod 计数

要显示每个节点和整个集群的 pod 数量，可以通过 `--pod-count` 参数：

```bash
kubectl resource-capacity --pod-count
```

### 按标签过滤

对于更高级的使用，kube-capacity 还支持按 pod、命名空间和/或节点标签进行过滤。以下示例展示了如何使用这些过滤器：

```
# 按标签筛选 Pod
kube-capacity --pod-labels app=nginx  

# 指定命名空间
kube-capacity --namespace 默认

# 按标签筛选命名空间
kube-capacity --namespace-labels team=api  

# 按标签筛选节点
kube-capacity --node-labels kubernetes.io/role=node
```

### JSON 和 YAML 输出

默认情况下，kube-capacity 将以表格格式提供输出。要以 JSON 或 YAML 格式查看此数据，可以使用输出标志。以下是一些示例命令：

```bash
kube-capacity --pods --output json

kube-capacity --pods --containers --util --output yaml
```

