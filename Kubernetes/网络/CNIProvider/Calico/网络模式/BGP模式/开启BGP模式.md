### calico 切换 BGP 模式

部署完成后默认使用 calico-ipip 的模式，通过在节点的路由即可得知，通往其他节点路由通过 tunl0 网卡出去

```bash
# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.244.244.1    0.0.0.0         UG    100    0        0 eth0
10.4.17.128     10.244.244.103  255.255.255.192 UG    0      0        0 tunl0
10.4.198.192    10.244.244.102  255.255.255.192 UG    0      0        0 tunl0
10.4.250.64     0.0.0.0         255.255.255.192 U     0      0        0 *
10.4.250.66     0.0.0.0         255.255.255.255 UH    0      0        0 cali912d1f2a902
10.4.250.67     0.0.0.0         255.255.255.255 UH    0      0        0 cali55ef474e4e9
10.4.250.68     0.0.0.0         255.255.255.255 UH    0      0        0 calie77e0b179be
10.244.244.0    0.0.0.0         255.255.255.0   U     100    0        0 eth0
10.245.245.0    0.0.0.0         255.255.255.0   U     150    0        0 ib0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.18.0.0      0.0.0.0         255.255.0.0     U     0      0        0 br-73377e18bc69
```

修改`CALICO_IPV4POOL_IPIP`改为 off，添加新环境变量`FELIX_IPINIPENABLED`为 false

```bash
kubectl set env daemonset/calico-node -n kube-system CALICO_IPV4POOL_IPIP=off

kubectl set env daemonset/calico-node -n kube-system FELIX_IPINIPENABLED=false
```

修改完成后对节点进行重启，等待恢复后查看主机路由，与 ipip 大区别在于去往其他节点的路由，由 Tunnel0 走向网络网卡

```bash

```

## 参考资料

- <https://kubesphere.io/zh/blogs/calico-guide/>
