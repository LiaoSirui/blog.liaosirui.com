## IPIP 模式

Calico 是一种开源网络和网络安全解决方案，适用于容器，虚拟机和基于主机的本机工作负载。Calico 后端支持多种网络模式：

- BGP 模式：将节点做为虚拟路由器通过 BGP 路由协议来实现集群内容器之间的网络访问
- IPIP 模式：在原有 IP 报文中封装一个新的 IP 报文，新的 IP 报文中将源地址 IP 和目的地址 IP 都修改为对端宿主机 IP
- VXLAN 模式：VXLAN 与 IPIP 模式类似，只是底层使用 VXLAN 技术来实现转发

其中 VXLAN 和 IPIP 属于 overlay 类型，在嵌套部署模式比较通用，但网络性能相对 BGP 会低一些。这主要是由于 BGP 模式下没有数据报文的封包和解包操作

IPIP 和 VXLAN 模式的性能基本上接近，所以在性能方面要相对于路由方面损失 10-20%

## 更改为 IPIP 模式

在所有节点清理旧有 bird 网络规则

```
ip r |grep bird |awk '{printf(\"ip r d %s\n\", \$0)}' | bash
```

所有节点开启 ipip 模块

```
modprobe -- ipip
```

如果使用的是 Kubernetes 1.16 及以上版本，则需要启用 `ipip` 模式。运行以下命令启用：

```bash
kubectl set env daemonset/calico-node -n kube-system FELIX_IPINIPENABLED=true
kubectl set env daemonset/calico-node -n kube-system CALICO_IPV4POOL_IPIP=Always
```

网卡匹配参数

```bash
- name: CALICO_AUTODETECTION_METHOD
  value: 'interface=ens192|ens4f0|ens29f1'
```