## Route reflector

默认情况下 calico 采用 node-to-node mesh 方式 ，为了防止 BGP 路由环路，BGP 协议规定在一个 AS（自治系统）内部，IBGP 路由器之间只能传一跳路由信息，所以在一个 AS 内部，IBGP 路由器之间为了学习路由信息需要建立全互联的对等体关系，但是当一个 AS 规模很大的时候，这种全互联的对等体关系维护会大量消耗网络和 CPU 资源，所以这种情况下就需要建立路由反射器以减少 IBGP 路由器之间的对等体关系数量

![image-20230704185340865](.assets/RouteReflector/image-20230704185340865.png)

早期 calico 版本提供专门的 route reflector 镜像，在新版本 calico node 内置集成 route reflector 功能。Route reflector 可以是以下角色：

- 集群内部的 node 节点
- 集群外部节点运行 calico node
- 其他支持 route reflector 的软件或者设备

在更大规模的集群中，需要通过 Route Reflector 模式专门创建一个或者几个专门的节点，负责跟所有的BGP客户端建立连接，从而学全全局的路由规则；

## 配置 Route reflector

关闭 node-to-node mesh

```
cat <<EOF | calicoctl apply -f -

apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
 name: default
spec:
  logSeverityScreen: Info
  nodeToNodeMeshEnabled: false
  asNumber: 63400
EOF
```

设置 Route reflector

配置 Route reflector 支持多种配置方式如：1、支持配置全局 BGP peer，。2、支持针对单个节点进行配置 BGP Peer。也可以将 calico 节点充当 Route reflector 这里以配置 calico 节点充当 Router reflector 为例。

配置节点充当 BGP Route Reflector

可将 Calico 节点配置为充当路由反射器。为此，要用作路由反射器的每个节点必须具有群集 ID-通常是未使用的 IPv4 地址。

要将节点配置为集群 ID 为 244.0.0.1 的路由反射器，请运行以下命令。这里将节点名为 rke-node4 的节点配置为 Route Reflector，若一个集群中要配置主备 rr，为了防止 rr 之间的路由环路，需要将集群 ID 配置成一样

```
calicoctl patch node rke-node4 -p '{"spec": {"bgp": {"routeReflectorClusterID": "244.0.0.1"}}}'
```

给节点打上对应的 label 标记该节点以表明它是 Route Reflector，从而允许 BGPPeer 资源选择它。

```
kubectl label node rke-node4 route-reflector=true
```

创建 BGPPeer

```
export CALICO_DATASTORE_TYPE=kubernetes
export CALICO_KUBECONFIG=~/.kube/config
cat <<EOF | calicoctl apply -f -
kind: BGPPeer
apiVersion: projectcalico.org/v3
metadata:
  name: peer-with-route-reflectors
spec:
  nodeSelector: all()
  peerSelector: route-reflector == 'true'
EOF
```

查看 BGP 节点状态

node 上查看，peer type 由 node-to-node mesh 变为 node specific

Route Reflector 上节点查看，节点已正常建立连接