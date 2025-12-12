## 简介

MetalLB 是裸机 Kubernetes 集群的负载均衡器实现，使用标准路由协议。

官方文档：

- 安装文档：<https://metallb.universe.tf/installation/>
- 使用文档：<https://metallb.universe.tf/>
- GitHub 地址：<https://github.com/metallb/metallb>

### 背景

在裸金属上（这里是相对云上环境来说，不是说无操作系统）部署的 Kubernetes 集群，是无法使用 LoadBalancer 类型的 Service 的，因为 Kubernetes 本身没有提供针对裸金属集群的负载均衡器。Kubernetes 仅仅提供了针对部分 IaaS 平台（GCP, AWS, Azure……）的胶水代码，以使用这些平台的负载均衡器。

为了从外部访问集群，对于裸金属集群，只能使用 NodePort 服务或 Ingress。前者的缺点是每个暴露的服务需要占用所有节点的某个端口，后者的缺点是仅仅能支持 HTTP 协议。

MetalLB 是一个负载均衡器，专门解决裸金属 K8S 集群无法使用 LoadBalancer 类型服务的痛点，它使用标准化的路由协议。该项目目前处于 Beta 状态。MetalLB 和 kube-proxy 的 IPVS 模式存在兼容性问题 <https://github.com/google/metallb/issues/153>，在 K8S 1.12.1 上此问题已经解决。

### 功能

- 地址分配

在云环境中，当你请求一个负载均衡器时，云平台会自动分配一个负载均衡器的IP地址给你，应用程序通过此IP来访问经过负载均衡处理的服务。

使用 MetalLB 时，MetalLB 自己负责 IP 地址的分配工作。你需要为 MetalLB 提供一个 IP 地址池供其分配（给 k8s 服务）。

- IP宣告

MetalLB 将 IP 分配给某个服务后，它需要对外“宣告”此 IP 地址，并让外部主机可以路由到此 IP。

## IP 宣告的两种形式

### L2 模式

在任何以太网环境均可使用该模式。

当在第二层工作时，将由一台机器获得 IP 地址（即服务的所有权）。MetalLB 使用标准的第地址发现协议（对于 IPv4 是 ARP，对于 IPv6 是 NDP）宣告 IP 地址，是其在本地网路中可达。从 LAN 的角度来看，仅仅是某台机器多配置了一个 IP 地址。

L2 模式下，服务的入口流量全部经由单个节点，然后该节点的 kube-proxy 会把流量再转发给服务的 Pods。也就是说，该模式下 MetalLB 并没有真正提供负载均衡器。尽管如此，MetalLB 提供了故障转移功能，如果持有 IP 的节点出现故障，则默认 10 秒后即发生故障转移，IP 被分配给其它健康的节点。

L2 模式的缺点：

1. 单点问题，服务的所有入口流量经由单点，其网络带宽可能成为瓶颈
2. 需要 ARP 客户端的配合，当故障转移发生时，MetalLB 会发送 ARP 包来宣告 MAC 地址和 IP 映射关系的变化。客户端必须能正确处理这些包，大部分现代操作系统能正确处理 ARP 包

### BGP 模式

当在第三层工作时，集群中所有机器都和你控制的最接近的路由器建立 BGP 会话，此会话让路由器能学习到如何转发针对 K8S 服务 IP 的数据报。

通过使用 BGP，可以实现真正的跨多节点负载均衡（需要路由器支持 multipath），还可以基于 BGP 的策略机制实现细粒度的流量控制。

具体的负载均衡行为和路由器有关，可保证的共同行为是：每个连接（TCP 或 UDP 会话）的数据报总是路由到同一个节点上，这很重要，因为：

1. 将单个连接的数据报路由给多个不同节点，会导致数据报的 reordering，并大大影响性能
2. K8S 节点会在转发流量给 Pod 时可能导致连接失败，因为多个节点可能将同一连接的数据报发给不同 Pod

BGP 模式的缺点：

1. 不能优雅处理故障转移，当持有服务的节点宕掉后，所有活动连接的客户端将收到 Connection reset by peer
2. BGP 路由器对数据报的源 IP、目的 IP、协议类型进行简单的哈希，并依据哈希值决定发给哪个 K8S 节点。问题是 K8S 节点集是不稳定的，一旦（参与 BGP）的节点宕掉，很大部分的活动连接都会因为 rehash 而坏掉

缓和措施：

1. 将服务绑定到一部分固定的节点上，降低 rehash 的概率
2. 在流量低的时段改变服务的部署
3. 客户端添加透明重试逻辑，当发现连接 TCP 层错误时自动重试

## 安装

### 安装要求

要使用 MetalLB，你的基础设施必须满足以下条件：

1. 版本在 1.9.0+ 的 K8S 集群
2. 可以和 MetalLB 兼容的 CNI 网络
3. 供 MetalLB 分配的 IPv4 地址范围
4. 可能需要一个或多个支持 BGP 的路由器

CNI 要求：

- CNI 支持，文档地址：<https://metallb.universe.tf/installation/network-addons/>

| Network addon | Compatible                          |
| :------------ | :---------------------------------- |
| Antrea        | Yes (Tested on version 1.4 and 1.5) |
| Calico        | Mostly (see known issues)           |
| Canal         | Yes                                 |
| Cilium        | Yes                                 |
| Flannel       | Yes                                 |
| Kube-ovn      | Yes                                 |
| Kube-router   | Mostly (see known issues)           |
| Weave Net     | Mostly (see known issues)           |

如果使用 Calico 的外部 BGP Peering 特性来同步路由，同时也想在 MetalLB 中使用 BGP，则需要一些变通手段。这个问题是由 BGP 协议本身导致的 —— BGP 协议只每对节点之间有一个会话，这意味着当 Calico 和 BGP 路由器建立会话后，MetalLB 就无法创建会话了。

由于目前 Calico 没有暴露扩展点，MetalLB 没有办法与之集成。

一个变通手段是，让 Calico、MetalLB 和不同的 BGP 路由进行配对，如下图： 

![bgp-calico-metallb](.assets/bgp-calico-metallb.png)

### 安装 lb

直接安装

执行下面的命令安装：

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
```

添加 Helm 仓库

```bash
helm repo add metallb https://metallb.github.io/metallb
```

使用如下的 values

```yaml
speaker:
  tolerations:
    - operator: "Exists"

controller:
  tolerations:
    - operator: "Exists"

```

安装命令

```bash
helm upgrade --install \
  -f ./values.yaml \
  --namespace metallb-system --create-namespace \
  --version 0.15.3 \
  metallb metallb/metallb
```

通过 Helm 安装时，MetalLB 读取的 ConfigMap 为 `metallb-config`。

### Layer2 配置

参考[Layer 2 Configurationopen in new window](https://metallb.universe.tf/configuration/#layer-2-configuration)，我们新建一个 ConfigMap，内容如下然后提供配置：

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: metallb-config
data:
  config: |
EOF
```

创建 IP 地址池，为 `LoadBalancer` 类型服务定义可分配的 IP 地址

> 可以同时定义多个 `IPAddressPools` 资源。
>
> 可以使用 CIDR 定义地址, 也可以使用范围区间定义, 也可以定义 IPv4 和 IPv6 地址用于分配、

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.244.244.100-10.244.244.200
```

下面的例子配置它使用 2 层模式:

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```

### 测试

等待 Pod 就绪

```bash
> kubectl get pods -n metallb-system

NAME                                  READY   STATUS    RESTARTS   AGE
metallb-controller-55588949b6-hs82d   1/1     Running   0          50s
metallb-speaker-c4h82                 1/1     Running   0          50s
metallb-speaker-jl78k                 1/1     Running   0          50s
metallb-speaker-ntrnb                 1/1     Running   0          50s
```

使用如下 yaml 清单

```yaml
# mentallb/whoami.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  labels:
    app: containous
    name: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: containous
      task: whoami
  template:
    metadata:
      labels:
        app: containous
        task: whoami
    spec:
      containers:
        - name: containouswhoami
          image: containous/whoami
          resources:
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  ports:
    - name: http
      port: 80
  selector:
    app: containous
    task: whoami
  type: LoadBalancer
```

查看测试 Pod

```bash
> kubectl get all -n default 

NAME                         READY   STATUS    RESTARTS   AGE
pod/whoami-bc9597656-85rj6   1/1     Running   0          7m40s
pod/whoami-bc9597656-qh6jf   1/1     Running   0          7m40s

NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
service/kubernetes   ClusterIP      10.3.0.1      <none>           443/TCP        13d
service/whoami       LoadBalancer   10.3.216.58   10.244.244.100   80:31796/TCP   7m40s

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/whoami   2/2     2            2           7m40s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/whoami-bc9597656   2         2         2       7m40s
```

可见分配的 EXTERNAL-IP 为 `10.244.244.100`

访问此 IP

```bash
> curl 10.244.244.100

Hostname: whoami-bc9597656-qh6jf
IP: 127.0.0.1
IP: ::1
IP: 10.4.2.146
IP: fe80::386c:eeff:fe7a:e1c8
RemoteAddr: 10.4.0.246:44078
GET / HTTP/1.1
Host: 10.244.244.100
User-Agent: curl/7.76.1
Accept: */*
Accept-Encoding: gzip

> curl 10.244.244.100

Hostname: whoami-bc9597656-qh6jf
IP: 127.0.0.1
IP: ::1
IP: 10.4.2.146
IP: fe80::386c:eeff:fe7a:e1c8
RemoteAddr: 10.4.0.246:44074
GET / HTTP/1.1
Host: 10.244.244.100
User-Agent: curl/7.76.1
Accept: */*
Accept-Encoding: gzip
```

创建测试 Pod

```bash
kubectl apply -f whoami.yaml
```

清理

```bash
kubectl delete -f whoami.yaml
```
