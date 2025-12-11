官方文档

- Install Calicoctl： <https://projectcalico.docs.tigera.io/archive/v3.24/maintenance/clis/calicoctl/install>
- Calicoctl：<https://projectcalico.docs.tigera.io/archive/v3.24/reference/calicoctl/>
- Calico API server：<https://projectcalico.docs.tigera.io/archive/v3.24/maintenance/install-apiserver>

## 安装

先确定 calico 的版本

```bash
# kubectl get daemonsets.apps -n kube-system calico-node -o json | jq '.spec.template.spec.containers[0].image'
Alias tip: k get daemonsets.apps -n kube-system calico-node -o json | jq '.spec.template.spec.containers[0].image'
"docker.io/calico/node:v3.24.1"
```

二进制文件下载：

```bash
curl -sL  https://github.com/projectcalico/calicoctl/releases/download/v3.20.6/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl

chmod +x /usr/local/bin/calicoctl
```

一定要确定版本一致

```bash
# calicoctl version
Client Version:    v3.24.1
Git commit:        83493da01
Cluster Version:   v3.24.1
Cluster Type:      k8s,bgp,kubeadm,kdd
```

配置 calicoctl 连接 Kubernetes 集群

```bash
export CALICO_DATASTORE_TYPE=kubernetes
export CALICO_KUBECONFIG=~/.kube/config

calicoctl node status
```

## 设置 veth 网卡 mtu

通常，通过使用高 MTU 值（不会在路径上引起碎片或丢包）来实现高性能。对于给定的流量速率，大带宽增加，CPU 消耗可能下降。对于一些支持 jumbo frames 的网络设备，可以配置 calico 支持使用。

IPIP 和 VXLAN 协议中的 IP 中使用的额外报文头，通过头的大小减小了小 MTU。（IP 中的 IP 使用 20 字节的标头，而 VXLAN 使用 50 字节的标头）。

如果在 Pod 网络中的任何地方使用 VXLAN，请将 MTU 大小配置为“物理网络 MTU 大小减去 50”。如果仅在 IP 中使用 IP，则将 MTU 大小配置为“物理网络 MTU 大小减去 20” 。

## 设置全局 AS 号

默认情况下，除非已为节点指定每个节点的 AS，否则所有 Calico 节点都使用 64512 自治系统。可以通过修改默认的 BGPConfiguration 资源来更改所有节点的全局默认值。以下示例命令将全局默认 AS 编号设置为 64513。

```
cat <<EOF | calicoctl apply -f -
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  nodeToNodeMeshEnabled: false
  asNumber: 64513
EOF
```

## 配置单个主机和 AS 号

例如，以下命令将名为 node-1 的节点更改为属于 AS 64514。

```bash
calicoctl patch node node-1 -p '{"spec": {"bgp": {“asNumber”: “64514”}}}'
```

## 修改节点地址范围

此操作建议在部署完集群后立刻进行。

默认情况下 calico 在集群层面分配一个 10.42.0.0/16 的 CIDR 网段，在这基础上在单独为每个主机划分一个单独子网采用 26 位子网掩码对应的集群支持的节点数为 2^10=1024 节点，单个子网大支持 64 个 POD，当单个子网对应 IP 消耗后，calico 会重新在本机上划分一个新的子网如下，在集群对端主机可以看见对应的多个 CIDR 路由信息。

> 注意：块大小将影响节点 POD 的 IP 地址分配和路由条目数量，如果主机在一个 CIDR 中分配所有地址，则将为其分配一个附加 CIDR。如果没有更多可用的块，则主机可以从分配给其他主机的 CIDR 中获取地址。为借用的地址添加了特定的路由，这会影响路由表的大小。

将块大小从默认值增加（例如，使用/24 则为每个块提供 256 个地址）意味着每个主机更少的块，会减少路由。但是对应的集群可容纳主机数也对应减少为 2^8。

从默认值减小 CIDR 大小（例如，使用/28 为每个块提供 16 个地址）意味着每个主机有更多 CIDR，因此会有更多路由。

calico 允许用户修改对应的 IP 池和集群 CIDR

创建和替换步骤

> 注意：删除 Pod 时，应用程序会出现暂时不可用

- 添加一个新的 IP 池。
- 注意：新 IP 池必须在同一群集 CIDR 中。
- 禁用旧的 IP 池（注意：禁用 IP 池只会阻止分配新的 IP 地址。它不会影响现有 POD 的联网）
- 从旧的 IP 池中删除 Pod。
- 验证新的 Pod 是否从新的 IP 池中获取地址。
- 删除旧的 IP 池。

定义 ippool 资源

```
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: my-ippool
spec:
  blockSize: 24
  cidr: 192.0.0.0/16
  ipipMode: Always
  natOutgoing: true
```

修改对应的 blockSize 号

创建新的

```
calicoctl apply -f pool.yaml
```

将旧的 ippool 禁用

```
calicoctl patch ippool default-ipv4-ippool -p '{"spec": {"disabled": “true”}}'
```

创建 workload 测试
