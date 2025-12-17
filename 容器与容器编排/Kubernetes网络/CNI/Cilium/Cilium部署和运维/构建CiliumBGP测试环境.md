## 构建 Kubernetes 集群示例

通过 Kind 启动 Cilium BGP 集群

### kind 集群

准备一个 Kind 的配置文件，创建一个 4 节点的 Kubernetes 集群

```yaml
# cluster.yaml
kind: Cluster
name: clab-bgp-cplane-demo
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true # 禁用默认 CNI
  podSubnet: "10.1.0.0/16" # Pod CIDR
nodes:
  - role: control-plane # 节点角色
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-ip: 10.0.1.2 # 节点 IP
            node-labels: "rack=rack0" # 节点标签

  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-ip: 10.0.2.2
            node-labels: "rack=rack0"

  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-ip: 10.0.3.2
            node-labels: "rack=rack1"

  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-ip: 10.0.4.2
            node-labels: "rack=rack1"

```

执行以下命令，通过 Kind 创建 Kubernetes 集群

```bash
kind create cluster --config cluster.yaml
```

### Containerlab 构建网络环境

定义 Containerlab 的配置文件，创建网络基础设施并连接 Kind 创建的 Kubernetes 集群：

- router0, tor0, tor1 作为 Kubernetes 集群外部的网络设备，在 exec 参数中设置网络接口信息以及 BGP 配置。router0 与 tor0, tor1 建立 BGP 邻居，tor0 与 server0, server1, router0 建立 BGP 邻居，tor1 与 server2, server3, router0 建立 BGP 邻居
- 设置 `network-mode: container:<容器名>` 可以让 Containerlab 共享 Containerlab 之外启动的容器的网络命名空间，设置 server0, server1, server2, server3 容器分别连接到通过 Kind 创建的 Kubernetes 集群的 4 个 Node 上

```yaml
# topo.yaml
name: bgp-cplane-demo
topology:
  kinds:
    linux:
      cmd: bash
  nodes:
    router0:
      kind: linux
      image: frrouting/frr:v8.2.2
      labels:
        app: frr
      exec:
        - iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        - ip addr add 10.0.0.0/32 dev lo
        - ip route add blackhole 10.0.0.0/8
        - touch /etc/frr/vtysh.conf
        - sed -i -e 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
        - usr/lib/frr/frrinit.sh start
        - >-
          vtysh -c 'conf t'
          -c 'router bgp 65000'
          -c ' bgp router-id 10.0.0.0'
          -c ' no bgp ebgp-requires-policy'
          -c ' neighbor ROUTERS peer-group'
          -c ' neighbor ROUTERS remote-as external'
          -c ' neighbor ROUTERS default-originate'
          -c ' neighbor net0 interface peer-group ROUTERS'
          -c ' neighbor net1 interface peer-group ROUTERS'
          -c ' address-family ipv4 unicast'
          -c '   redistribute connected'
          -c ' exit-address-family'
          -c '!'

    tor0:
      kind: linux
      image: frrouting/frr:v8.2.2
      labels:
        app: frr
      exec:
        - ip link del eth0
        - ip addr add 10.0.0.1/32 dev lo
        - ip addr add 10.0.1.1/24 dev net1
        - ip addr add 10.0.2.1/24 dev net2
        - touch /etc/frr/vtysh.conf
        - sed -i -e 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
        - /usr/lib/frr/frrinit.sh start
        - >-
          vtysh -c 'conf t'
          -c 'frr defaults datacenter'
          -c 'router bgp 65010'
          -c ' bgp router-id 10.0.0.1'
          -c ' no bgp ebgp-requires-policy'
          -c ' neighbor ROUTERS peer-group'
          -c ' neighbor ROUTERS remote-as external'
          -c ' neighbor SERVERS peer-group'
          -c ' neighbor SERVERS remote-as internal'
          -c ' neighbor net0 interface peer-group ROUTERS'
          -c ' neighbor 10.0.1.2 peer-group SERVERS'
          -c ' neighbor 10.0.2.2 peer-group SERVERS'
          -c ' address-family ipv4 unicast'
          -c '   redistribute connected'
          -c '  exit-address-family'
          -c '!'

    tor1:
      kind: linux
      image: frrouting/frr:v8.2.2
      labels:
        app: frr
      exec:
        - ip link del eth0
        - ip addr add 10.0.0.2/32 dev lo
        - ip addr add 10.0.3.1/24 dev net1
        - ip addr add 10.0.4.1/24 dev net2
        - touch /etc/frr/vtysh.conf
        - sed -i -e 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
        - /usr/lib/frr/frrinit.sh start
        - >-
          vtysh -c 'conf t'
          -c 'frr defaults datacenter'
          -c 'router bgp 65011'
          -c ' bgp router-id 10.0.0.2'
          -c ' no bgp ebgp-requires-policy'
          -c ' neighbor ROUTERS peer-group'
          -c ' neighbor ROUTERS remote-as external'
          -c ' neighbor SERVERS peer-group'
          -c ' neighbor SERVERS remote-as internal'
          -c ' neighbor net0 interface peer-group ROUTERS'
          -c ' neighbor 10.0.3.2 peer-group SERVERS'
          -c ' neighbor 10.0.4.2 peer-group SERVERS'
          -c ' address-family ipv4 unicast'
          -c '   redistribute connected'
          -c '  exit-address-family'
          -c '!'

    server0:
      kind: linux
      image: nicolaka/netshoot:latest
      network-mode: container:control-plane
      exec:
        - ip addr add 10.0.1.2/24 dev net0
        - ip route replace default via 10.0.1.1

    server1:
      kind: linux
      image: nicolaka/netshoot:latest
      network-mode: container:worker
      exec:
        - ip addr add 10.0.2.2/24 dev net0
        - ip route replace default via 10.0.2.1

    server2:
      kind: linux
      image: nicolaka/netshoot:latest
      network-mode: container:worker2
      exec:
        - ip addr add 10.0.3.2/24 dev net0
        - ip route replace default via 10.0.3.1

    server3:
      kind: linux
      image: nicolaka/netshoot:latest
      network-mode: container:worker3
      exec:
        - ip addr add 10.0.4.2/24 dev net0
        - ip route replace default via 10.0.4.1

  links:
    - endpoints: ["router0:net0", "tor0:net0"]
    - endpoints: ["router0:net1", "tor1:net0"]
    - endpoints: ["tor0:net1", "server0:net0"]
    - endpoints: ["tor0:net2", "server1:net0"]
    - endpoints: ["tor1:net1", "server2:net0"]
    - endpoints: ["tor1:net2", "server3:net0"]

```

执行以下命令，创建网络环境

```bash
clab deploy -t topo.yaml
```

创建成功后输出

![image-20231031095310855](./.assets/构建CiliumBGP测试环境/image-20231031095310855.png)

创建完的拓扑如下所示，当前只有 tor0, tor1 和 router0 设备之间建立了 BGP 连接，由于尚未通过 CiliumBGPPeeringPolicy 设置 Kubernetes 集群的 BGP 配置，因此 tor0, tor1 与 Kubernetes Node 的 BGP 连接还没有建立

![image-20231030145008728](./.assets/构建CiliumBGP测试环境/image-20231030145008728.png)

分别执行以下命令，可以查看 tor0, tor1, router0 这 3 个网络设备当前的 BGP 邻居建立情况

```bash
docker exec -it clab-bgp-cplane-demo-tor0 vtysh -c "show bgp ipv4 summary wide"

docker exec -it clab-bgp-cplane-demo-tor1 vtysh -c "show bgp ipv4 summary wide"

docker exec -it clab-bgp-cplane-demo-router0 vtysh -c "show bgp ipv4 summary wide"
```

执行以下命令，查看 router0 设备现在学到的 BGP 路由条目

```bash
docker exec -it clab-bgp-cplane-demo-router0 vtysh -c "show bgp ipv4 wide"
```

Containerlab 提供 `graph` 命令生成网络拓扑，在浏览器输入 `http://<宿主机 IP>:50080` 可以查看 Containerlab 生成的拓扑图

```bash
clab graph -t topo.yaml
```

![img](./.assets/构建CiliumBGP测试环境/vvsibFWkwqHrG3ffYxKKwgwq4w6c4E2W4VjTuExvIBuaz6bk5JGrLv8ZSx90HBPPKgjpNYurXVlRJtP7ebzfddA.png)

### 安装 Cilium

在 values.yaml 配置文件中设置我们需要调整的 Cilium 配置参数

```bash
# values.yaml
tunnel: disabled

ipam:
  mode: kubernetes

ipv4NativeRoutingCIDR: 10.0.0.0/8

# 开启 BGP 功能支持，等同于命令行执行 --enable-bgp-control-plane=true
bgpControlPlane:
  enabled: true

k8s:
  requireIPv4PodCIDR: true

image:
  useDigest: false

operator:
  image:
    useDigest: false

```

执行以下命令，安装 Cilium 1.12 版本，开启 BGP 功能支持

```bash
# helm repo add cilium https://helm.cilium.io/
helm pull \
    --repo https://helm.cilium.io \
    cilium \
    --version 1.14.3

helm upgrade \
    --install \
    -n kube-system --create-namespace \
    -f ./values.yaml \
    cilium \
    "./cilium-1.14.3.tgz"

```

> 如遇无法拉取镜像，可手动执行
>
> ```bash
> ctr -n moby image export --platform amd64 cilium-image.tar quay.io/cilium/cilium:v1.14.3  
> ctr -n moby image export --platform amd64 cilium-operator-image.tar quay.io/cilium/operator-generic:v1.14.3
> 
> docker cp cilium-image.tar clab-bgp-cplane-demo-control-plane:/root/cilium-image.tar
> docker cp cilium-image.tar clab-bgp-cplane-demo-worker:/root/cilium-image.tar
> docker cp cilium-image.tar clab-bgp-cplane-demo-worker2:/root/cilium-image.tar
> docker cp cilium-image.tar clab-bgp-cplane-demo-worker3:/root/cilium-image.tar
> 
> docker cp cilium-operator-image.tar clab-bgp-cplane-demo-control-plane:/root/cilium-operator-image.tar
> docker cp cilium-operator-image.tar clab-bgp-cplane-demo-worker:/root/cilium-operator-image.tar
> docker cp cilium-operator-image.tar clab-bgp-cplane-demo-worker2:/root/cilium-operator-image.tar
> docker cp cilium-operator-image.tar clab-bgp-cplane-demo-worker3:/root/cilium-operator-image.tar
> 
> docker exec -it clab-bgp-cplane-demo-control-plane ctr -n k8s.io image import /root/cilium-operator-image.tar
> docker exec -it clab-bgp-cplane-demo-control-plane ctr -n k8s.io image import /root/cilium-image.tar
> docker exec -it clab-bgp-cplane-demo-worker ctr -n k8s.io image import /root/cilium-operator-image.tar
> docker exec -it clab-bgp-cplane-demo-worker ctr -n k8s.io image import /root/cilium-image.tar
> docker exec -it clab-bgp-cplane-demo-worker2 ctr -n k8s.io image import /root/cilium-operator-image.tar
> docker exec -it clab-bgp-cplane-demo-worker2 ctr -n k8s.io image import /root/cilium-image.tar
> docker exec -it clab-bgp-cplane-demo-worker3 ctr -n k8s.io image import /root/cilium-operator-image.tar
> docker exec -it clab-bgp-cplane-demo-worker3 ctr -n k8s.io image import /root/cilium-image.tar
> ```

等待所有 Cilium Pod 启动完毕后，再次查看 Kubernetes Node 状态，可以看到所有 Node 都已经处于 Ready 状态

```bash
NAME                                 STATUS   ROLES           AGE   VERSION
clab-bgp-cplane-demo-control-plane   Ready    control-plane   18h   v1.27.3
clab-bgp-cplane-demo-worker          Ready    <none>          18h   v1.27.3
clab-bgp-cplane-demo-worker2         Ready    <none>          18h   v1.27.3
clab-bgp-cplane-demo-worker3         Ready    <none>          18h   v1.27.3
```

### 配置 BGP

接下来分别为 rack0 和 rack1 两个机架上 Kubernetes Node 配置 CiliumBGPPeeringPolicy。rack0 和 rack1 分别对应 Node 的 label

rack0 的 Node 与 tor0 建立 BGP 邻居，rack1 的 Node 与 tor1 建立 BGP 邻居，并自动宣告 Pod CIDR 给 BGP 邻居

```bash
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumBGPPeeringPolicy
metadata:
  name: rack0
spec:
  nodeSelector:
    matchLabels:
      rack: rack0
  virtualRouters:
    - localASN: 65010
      exportPodCIDR: true # 自动宣告 Pod CIDR
      neighbors:
        - peerAddress: "10.0.0.1/32" # tor0 的 IP 地址
          peerASN: 65010
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumBGPPeeringPolicy
metadata:
  name: rack1
spec:
  nodeSelector:
    matchLabels:
      rack: rack1
  virtualRouters:
    - localASN: 65011
      exportPodCIDR: true
      neighbors:
        - peerAddress: "10.0.0.2/32" # tor1 的 IP 地址
          peerASN: 65011

```

创建完的拓扑如下所示，现在 tor0 和 tor1 也已经和 Kubernetes Node 建立了 BGP 邻居

![img](./.assets/构建CiliumBGP测试环境/vvsibFWkwqHrG3ffYxKKwgwq4w6c4E2W4aDH74k6VYVDH0apPfvNVwaXjkwXB9UuguiaJnO4d2c1YPHKPGwAUFtw.png)

分别执行以下命令，可以查看 tor0, tor1, router0 3 个网络设备当前的 BGP 邻居建立情况

```bash
docker exec -it clab-bgp-cplane-demo-tor0 vtysh -c "show bgp ipv4 summary wide"
docker exec -it clab-bgp-cplane-demo-tor1 vtysh -c "show bgp ipv4 summary wide"
docker exec -it clab-bgp-cplane-demo-router0 vtysh -c "show bgp ipv4 summary wide"
```

执行以下命令，查看 router0 设备现在学到的 BGP 路由条目。

```
docker exec -it clab-bgp-cplane-demo-router0 vtysh -c "show bgp ipv4 wide"
```

当前总共有 12 条路由条目，其中多出来的 4 条路由是从 Kubernetes 4 个 Node 学到的 10.1.x.0/24 网段的路由

### 验证测试

分别在 rack0 和 rack1 所在的节点上创建 1 个 Pod 用于测试网络的连通性

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nettool-1
  name: nettool-1
spec:
  containers:
    - image: docker.io/nicolaka/netshoot:v0.9
      name: nettool-1
      command:
        - /bin/bash
      args:
        - -c
        - sleep 100d
  nodeSelector:
    rack: rack0
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nettool-2
  name: nettool-2
spec:
  containers:
    - image: docker.io/nicolaka/netshoot:v0.9
      name: nettool-2
      command:
        - /bin/bash
      args:
        - -c
        - sleep 100d
  nodeSelector:
    rack: rack1

```

查看 Pod 的 IP 地址

```
kubectl get pod -o wide
```

nettool-1 Pod 位于 clab-bgp-cplane-demo-worker（server1, rack0）上，IP 地址是 10.1.2.185；nettool-2 Pod 位于 clab-bgp-cplane-demo-worker3（server3, rack1） 上，IP 地址是 10.1.3.56

执行以下命令，在 nettool-1 Pod 中尝试 ping nettool-2 Pod

```bash
kubectl exec -it nettool-1 -- ping 10.1.3.56 
```

可以看到 nettool-1 Pod 能够正常访问 nettool-2 Pod

接下来使用 traceroute 命令观察网络数据包的走向。

```
kubectl exec -it nettool-1 -- traceroute -n 10.1.3.56
```

数据包从 nettool-1 Pod 发出，依次经过了：

- （1）server1 的 cilium_host 接口：Cilium 网络中 Pod 的默认路由指向了本机的 cilium_host。cilium_host 和cilium_net 是一对 veth pair 设备。Cilium 通过 hardcode ARP 表，强制将 Pod 流量的下一跳劫持到 veth pair 的主机端
- （2）tor0 的 net2 接口
- （3）router0 的 lo0 接口：tor0, tor1 和 router0 3 个网络设备间通过本地环回口 lo0 建立 BGP 邻居，这样做可以在有多条物理链路备份的情况下提升 BGP 邻居的稳健性，不会因为某个物理接口故障时而影响到邻居关系
- （4）tor1 的 lo0 接口
- （5）server3 的 net0 接口

![img](./.assets/构建CiliumBGP测试环境/vvsibFWkwqHrG3ffYxKKwgwq4w6c4E2W43sydSsYuP1dUDTUnmv0PsRtA5gzBCp0km94iaoPjrgKXUn6xUXzcKWQ.png)

### 清理环境

执行以下命令，清理 Containerlab 和 Kind 创建的环境

```
clab destroy -t topo.yaml

kind delete clusters clab-bgp-cplane-demo
```
