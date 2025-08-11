## 自定义网段

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  serviceSubnet: "100.55.0.0/16"
  podSubnet: "10.160.0.0/12"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
clusterCIDR: "100.64.0.0/10"

```

## 构建双栈集群

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
Networking:
  DNSDomain: ""
  PodSubnet: 100.64.0.0/10,fd85:ee78:d8a6:8607::1:0000/112  # 增加 pod IPv6 地址段
  ServiceSubnet: 10.96.0.0/22,fd85:ee78:d8a6:8607::1000/116 # 增加 svc IPv6 地址段
APIServer:
  CertSANs:
    - 127.0.0.1
    - apiserver.cluster.local
    - 10.103.97.2
    - 192.168.0.10
    - 2001:db8::f816:3eff:fe8c:910a # 增加控制节点的 IPv6 地址，如果你需要使用此IP访问 APIServer
  ExtraArgs:
    service-cluster-ip-range: 10.96.0.0/22,fd85:ee78:d8a6:8607::1000/116 # 增加 svc IPv6 地址段
ControllerManager:
  ExtraArgs:
    node-cidr-mask-size-ipv6: 120 # 默认为 64
    node-cidr-mask-size-ipv4: 24  # 默认为 24
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
clusterCIDR: "100.64.0.0/10,fd85:ee78:d8a6:8607::1:0000/112" #增加 pod IPv6 地址段

```

