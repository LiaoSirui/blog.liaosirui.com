## Calico 简介

Calico 是一种开源网络和网络安全解决方案，适用于容器，虚拟机和基于主机的本机工作负载。Calico 支持广泛的平台，包括 Kubernetes，docker，OpenStack 和裸机服务。Calico 后端支持多种网络模式

- BGP 模式：将节点做为虚拟路由器通过 BGP 路由协议来实现集群内容器之间的网络访问
- IPIP 模式：在原有 IP 报文中封装一个新的 IP 报文，新的 IP 报文中将源地址 IP 和目的地址 IP 都修改为对端宿主机 IP
- cross-subnet：Calico-ipip 模式和 calico-bgp 模式都有对应的局限性，对于一些主机跨子网而又无法使网络设备使用 BGP 的场景可以使用 cross-subnet 模式，实现同子网机器使用 calico-BGP 模式，跨子网机器使用 calico-ipip 模式

## 安装

安装 Calico 网络插件

```bash
curl https://docs.projectcalico.org/manifests/calico.yaml -O calico.yaml
```

查看已部署 k8s 集群的子网段

```bash
> kubeadm config print init-defaults | grep Subnet
  serviceSubnet: 10.96.0.0/12

# 旧版本使用：kubeadm config view | grep Subnet
```

修改网段

```bash
# 1、修改calico.yaml配置文件
vim calico.yaml

# 由于calico.yaml配置文件中使用的pod cidr地址段默认为192.168.0.0/16，
# 与在kubeadm init初始化master节点时，指定的–pod-network-cidr地址段10.4.0.0/16不同
# 所以需要修改calico配置文件，取消CALICO_IPV4POOL_CIDR变量和value前的注释，并将value值设置为与--pod-network-cidr指定地址段相同的值，即：10.4.0.0/16
# 2、取消前面的注释，将value值改为 10.4.0.0/16
- name: CALICO_IPV4POOL_CIDR
  value: "10.4.0.0/16"
```

应用calico网络

```bash
kubectl apply -f calico.yaml
```

## IPIP 模式

<https://system51.github.io/2020/05/27/using-calico/>

![img](.assets/Calico简介/436EF78A6A0877DE5732F186CE1406A9-20221219201641196.jpg)

## BGP 模式

![img](.assets/Calico简介/F94A48ADC2A1721363C79FB990B94A85.jpg)

