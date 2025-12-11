## cross-subnet 模式

### calico 切换 cross-subnet 模式

Calico-ipip 模式和 calico-bgp 模式都有对应的局限性，对于一些主机跨子网而又无法使网络设备使用 BGP 的场景可以使用 cross-subnet 模式，实现同子网机器使用 calico-BGP 模式，跨子网机器使用 calico-ipip 模式。

ipip虽然实现了 calico 跨网段通信，但对于相同网段间的主机通信来说，IP-in-IP 就有点多余了，因为二者宿主机处于同一广播域，2层互通，直接走主机路由即可。此时需要借助calico cross-subnet

```
$ calicoctl apply -f - << EOF
apiVersion: v1
kind: ipPool
metadata:
  cidr: 192.168.0.0/16
spec:
  ipip:
    enabled: true
    mode: cross-subnet
  nat-outgoing: true
EOF
```

