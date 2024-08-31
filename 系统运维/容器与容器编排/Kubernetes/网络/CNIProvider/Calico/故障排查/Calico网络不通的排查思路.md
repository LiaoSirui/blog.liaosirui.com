网络不通通俗一点就是报文不可达

容器 A 访问不了容器 B，也就是容器 A ping 不通容器 B

排查思路：

- 正向

```
容器 A 的内容是否发送到容器 A 所在的 node 上
容器 A 所在的节点 node 是否发送出去
容器 B 所在的节点 node 是否接收到容器 A 所在的节点 node 发送的报文
容器 B 所在的节点 node 是否把报文发送到容器 B 中
```

- 反向

```
容器 B 的内容是否发送到容器 B 所在的 node 上
容器 B 所在的节点 node 是否发送出去
容器 A 所在的节点 node 是否接收到容器 B 所在的节点 node 发送的报文
容器 A 所在的节点 node 是否把报文发送到容器 A 中
```

先找不能访问的 pod

```bash
# kubectl get pods -n aipaas-system -o wide
Alias tip: kgpn aipaas-system -o wide
NAME                                                READY   STATUS    RESTARTS        AGE    IP               NODE         NOMINATED NODE   READINESS GATES
...
console-deployment-6c6cf7bd4-k2ql6                  1/1     Running   0               68m    10.4.198.232     devmaster2   <none>           <none>
...
```

先用 calicoctl 查看容器 A 的 workloadEndpoint：

```bash
# calicoctl get workloadEndpoint -n aipaas-system
NAMESPACE       WORKLOAD                                            NODE         NETWORKS          INTERFACE
...
aipaas-system   console-deployment-6c6cf7bd4-k2ql6                  devmaster2   10.4.198.232/32   cali9755bafadb4
...

# calicoctl get workloadEndpoint -n aipaas-system devmaster2-k8s-console--deployment--6c6cf7bd4--k2ql6-eth0
NAMESPACE       WORKLOAD                             NODE         NETWORKS          INTERFACE
aipaas-system   console-deployment-6c6cf7bd4-k2ql6   devmaster2   10.4.198.232/32   cali9755bafadb4

# calicoctl get workloadEndpoint -n aipaas-system devmaster2-k8s-console--deployment--6c6cf7bd4--k2ql6-eth0 -o yaml
apiVersion: projectcalico.org/v3
kind: WorkloadEndpoint
metadata:
  creationTimestamp: "2022-12-19T11:56:43Z"
  generateName: console-deployment-6c6cf7bd4-
  labels:
    app: console
    pod-template-hash: 6c6cf7bd4
    projectcalico.org/namespace: aipaas-system
    projectcalico.org/orchestrator: k8s
    projectcalico.org/serviceaccount: console
  name: devmaster2-k8s-console--deployment--6c6cf7bd4--k2ql6-eth0
  namespace: aipaas-system
  resourceVersion: "100147827"
  uid: f9158dc3-ba93-4c13-98d4-75332abf2201
spec:
  containerID: 39036012c3a2604bd850cff7dd2e6f2c5fe3bdeaba58db32da1a3104b50f5fe2
  endpoint: eth0
  interfaceName: cali9755bafadb4
  ipNetworks:
  - 10.4.198.232/32
  node: devmaster2
  orchestrator: k8s
  pod: console-deployment-6c6cf7bd4-k2ql6
  ports:
  - hostIP: ""
    hostPort: 0
    name: http
    port: 9000
    protocol: TCP
  profiles:
  - kns.aipaas-system
  - ksa.aipaas-system.console
  serviceAccountName: console
```

可以看到容器 A 的相关网路的信息

```
容器 A 的绑定的网卡 cali9755bafadb4
容器 A 的 mac 地址 -
容器的 IP 地址 10.4.198.232/32
所在的节点 devmaster2
```

查看容器 A 内的网卡是否正确，ip 和 mac 是否与从 calico 中查询到的一致:

```bash
# crictl ps  |grep console
701b7aa1d3612       e1badc3876d6c       About an hour ago   Running             console-app                       0                   39036012c3a26       console-deployment-6c6cf7bd4-k2ql6

# crictl inspect 701b7aa1d3612 | grep -i pid
    "pid": 183424,
            "pid": 1
            "type": "pid"

# nsenter -n -t 183424

# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/ipip 0.0.0.0 brd 0.0.0.0
4: eth0@if78: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 36:e9:be:68:bd:af brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.4.198.232/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::34e9:beff:fe68:bdaf/64 scope link
       valid_lft forever preferred_lft forever
```

查看容器 A 的默认路由是否是 `169.254.1.1`，且没有额外的路由:

```bash
# ip r
default via 169.254.1.1 dev eth0
169.254.1.1 dev eth0 scope link

```

查看容器 A 内记录的 169.254.1.1 的 mac 地址是否是 node 上的 calico 网卡的 mac

```bash
# ip neigh
169.254.1.1 dev eth0 lladdr ee:ee:ee:ee:ee:ee STALE

```

在 node 上执行，查看 cali9755bafadb4 的网卡的 mac 地址是否跟之前通过 calicoctl 查询得到的结果一致

```bash
# ifconfig cali9755bafadb4
cali9755bafadb4: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        ether ee:ee:ee:ee:ee:ee  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

```

https://blog.csdn.net/u010039418/article/details/120589775

https://blog.csdn.net/qq_21816375/article/details/79475163

https://zhuanlan.zhihu.com/p/504047671