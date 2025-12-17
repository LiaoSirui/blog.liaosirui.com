## 网络策略

### 网络策略的类型

默认情况下，Kubernetes 集群中的所有 pod 都可被其他 pod 和网络端点访问。

网络策略允许用户定义 Kubernetes 集群允许哪些流量，禁止哪些流量。传统的防火墙是根据源或目标 IP 地址和端口来配置允许或拒绝流量的 (五元组)，而 Cilium 则使用 Kubernetes 的身份信息（如标签选择器、命名空间名称，甚至是完全限定的域名）来定义允许和不允许的流量规则。这样，网络策略就能在 Kubernetes 这样的动态环境中运行，因为在这种环境中，IP 地址会随着不同 pod 的创建和销毁而不断被使用和重复使用。

在 Kubernetes 上运行 Cilium 时，可以使用 Kubernetes 资源定义网络策略 (`networking.k8s.io/v1` `NetworkPolicy`)。Cilium Agent 将观察 Kubernetes API 服务器是否有网络策略更新，并加载必要的 eBPF 程序和 map，以确保实施所需的网络策略。启用 Cilium 的 Kubernetes 提供三种网络策略格式：

- 支持第 3 层和第 4 层策略的标准 Kubernetes NetworkPolicy 资源
- 支持第 3、4 和 7 层（应用层）策略的 CiliumNetworkPolicy 资源
- `CiliumClusterwideNetworkPolicy` 资源，用于指定适用于整个集群而非指定命名空间的策略，可以进行 Node  级别的网络策略限制

### NetworkPolicy 资源

NetworkPolicy 资源是 Kubernetes 的标准资源 (`networking.k8s.io/v1` `NetworkPolicy`)，可在 IP 地址或端口级别（OSI 模型第 3 层或第 4 层）控制流量

NetworkPolicy 的功能包括:

- 使用标签 (label) 匹配的 L3/L4 Ingress 和 Egress 策略
- 集群外部端点使用 IP/CIDR 的 L3 IP/CIDR Ingress 和 Egress 策略
-  L4 TCP 和 ICMP 端口 Ingress 和 Egress 策略

NetworkPolicy 不适用于主机网络命名空间。启用主机网络的 Pod 不受网络策略规则的影响。

网络策略无法阻止来自 localhost 或来自其驻留的节点的流量。

### CiliumNetWorkPolicy 资源

CiliumNetworkPolicy 是标准 NetworkPolicy 的扩展。CiliumNetworkPolicy 扩展了标准 Kubernetes NetworkPolicy 资源的 L3/L4 功能，并增加了多项功能：

- L7 HTTP 协议策略规则，将 Ingress 和 Egress 限制为特定的 HTTP 路径
- 支持 DNS、Kafka 和 gRPC 等其他 L7 协议
- 基于服务名称的内部集群通信 Egress 策略
- 针对特殊实体使用实体匹配的 L3/L4 Ingress 和 Egress 策略
- 使用 DNS FQDN 匹配的 L3 Ingress 和 Egress 策略

### 可视化策略编辑器

NetworkPolicy.io 策略编辑器提供了探索和制定 L3 和 L4  网络策略的绝佳方式，它以图形方式描述了一个群集，为所需的网络策略类型选择正确的策略元素。

策略编辑器支持标准的 Kubernetes  NetworkPolicy 和 CiliumNetworkPolicy 资源。

<https://networkpolicy.io/>

## CiliumNetworkPolicy 7 层能力

CiliumNetworkPolicy 与标准 NetworkPolicy 的最大区别之一是支持 L7 协议感知规则。在 Cilium 中，可以为不同的协议（包括 HTTP、Kafka 和 DNS）制定特定于协议的 L7 策略。

第 7 层策略规则扩展了第 4 层策略的 `toPorts` 部分，可用于 Ingress 和 Egress

当节点上运行的任何端点的任何 L7 HTTP 策略处于活动状态时，该节点上的 Cilium Agent 将启动一个嵌入式本地 HTTP Agent 服务 (基于 Envoy, 二进制包为 `cilium-envoy`)，并指示 eBPF 程序将数据包转发到该本地 HTTP 代理。HTTP 代理负责解释 L7 网络策略规则，并酌情进一步转发数据包。此外，一旦 HTTP 代理就位，你就可以在 Hubble 流量中获得 L7 可观察性，我们将在后续介绍。

在编写 L7 HTTP 策略时，HTTP 代理可以使用几个字段来匹配网络流量：

- PATH: 与 URL 请求的常规路径相匹配的扩展 POSIX regex。如果省略或为空，则允许所有路径。
- Method: 请求的方法，如 GET、POST、PUT、PATCH、DELETE。如果省略或为空，则允许使用所有方法。
- Host: 与请求的主机标头匹配的扩展 POSIX regex。如果省略或为空，则允许使用所有主机。
- Headers: 请求中必须包含的 HTTP 头信息列表。如果省略或为空，则无论是否存在标头，都允许请求。

下面的示例使用了几个具有 regex 路径定义的 L7 HTTP 协议规则，以扩展 L4 策略，限制所有带有 `app=myService` 标签的端点只能使用 TCP 在 80 端口接收数据包。在此端口上通信时，只允许使用以下 HTTP API 端点：

- `GET /v1/path1`: 精确匹配 “/v1/path1”
- `PUT /v2/path2.*`: 匹配所有以 “/v2/path2” 开头的 paths
- `POST .*/path3`: 这将匹配所有以 “/path3” 结尾的路径，并附加 HTTP 标头 `X-My-Header` 必须设为 `true` 的限制条件：

具体策略如下:

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "http-rule"
spec:
  endpointSelector:
    matchLabels:
      app: myService
  ingress:
    - toPorts:
        - ports:
            - port: "80"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/v1/path1"
              - method: PUT
                path: "/v2/path2.*"
              - method: POST
                path: ".*/path3"
                headers:
                  - "X-My-Header: true"

```

该规则块包含扩展 L4 Ingress 策略的 L7 策略逻辑。您只需在 `toPorts` 列表中添加相应的规则块作为属性，就可以从 L4 策略开始，提供细粒度的 HTTP API 支持。

Kafka

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "kafka-rule"
spec:
  description: "enable empire-hq to produce to empire-announce and deathstar-plans"
  endpointSelector:
    matchLabels:
      app: kafka
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: empire-hq
      toPorts:
        - ports:
            - port: "9092"
              protocol: TCP
          rules:
            kafka:
              - role: "produce"
                topic: "deathstar-plans"
              - role: "produce"
                topic: "empire-announce"

```

DNS L7 策略

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: "tofqdn-dns-visibility-rule"
spec:
  endpointSelector:
    matchLabels:
      any:org: alliance
  egress:
    - toEndpoints:
        - matchLabels:
            "io.kubernetes.pod.namespace": kube-system
            "k8s-app": kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: ANY
          rules:
            dns:
              - matchName: "cilium.io"
              - matchPattern: "*.cilium.io"
              - matchPattern: "*.api.cilium.io"
    - toFQDNs:
        - matchName: "cilium.io"
        - matchName: "sub.cilium.io"
        - matchName: "service1.api.cilium.io"
        - matchPattern: "special*service.api.cilium.io"
      toPorts:
        - ports:
            - port: "80"
              protocol: TCP

```

在此示例中，L7 DNS 策略允许查询 `cilium.io`、`cilium.io` 的任何子域以及 `api.cilium.io` 的任何子域。不允许其他 DNS 查询。

单独的 L3 toFQDNs Egress 规则允许连接到 DNS 查询中返回的 `cilium.io`、`sub.cilium.io`、`service1.api.cilium.io` 和 `special*service.api.cilium.io` 的任何匹配 IP，如 `special-region1-service.api.cilium.io`，但不包括 `region1-service.api.cilium.io`。允许对 `anothersub.cilium.io` 进行 DNS 查询，但不允许连接到返回的 IP，因为没有 L3 toFQDNs 规则选择它们