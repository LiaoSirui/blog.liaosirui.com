## iptables 链

### iptables 链功能

当在 Kubernetes 中创建 Service 时，将会创建以下几个 iptables 链

这些链都是用于实现 Service 的核心功能

- `PREROUTING` 链

此链是由 kube-proxy 组件创建的，用于将 Service IP 地址映射到对应的 Pod IP 地址上<br />当请求进入节点时，该链将被触发，它根据请求的 Service IP 地址来查找对应的 Pod IP 地址，并将请求转发到该 Pod |

- `KUBE-SERVICES` 链

此链包含了一系列规则，用于将 Service IP 地址映射到对应的 Pod IP 地址上

当请求进入节点时，该链将被触发，并根据请求的 Service IP 地址来查找对应的 Pod IP 地址

如果找到了对应的 Pod IP 地址，请求将被转发到该 Pod 

- `KUBE-SVC-XXX` 链

此链包含了一系列规则，其中 XXX 代表 Service 的名称

每个 Service 都有一个对应的 KUBE-SVC-XXX 链

当请求进入节点时，该链将被触发，并根据 Service IP 地址查找对应的 KUBE-SVC-XXX 链

该链中的规则将请求转发到对应的 Pod

- `KUBE-SEP-XXX` 链

此链包含了一系列规则，其中 XXX 代表 Service 的名称

每个 Service 都有一个对应的 KUBE-SEP-XXX 链

当请求进入节点时，该链将被触发，并根据 Service IP 地址查找对应的 KUBE-SEP-XXX 链

该链中的规则将请求转发到对应的 Pod

- `KUBE-FIREWALL` 链

此链用于处理来自 Kubernetes 的内部流量。该链包含了一些规则，用于控制访问 Kubernetes 的 API、DNS 和其他一些服务

- `KUBE-NODEPORT` 链

当 Service 类型为 NodePort 时，此链将被创建。该链包含了一些规则，用于将节点的端口映射到 Service 的端口上

- `KUBE-MARK-DROP` 链

当请求被拒绝时，会触发此链。该链包含了一些规则，用于标记被拒绝的数据包

### 分析实例

