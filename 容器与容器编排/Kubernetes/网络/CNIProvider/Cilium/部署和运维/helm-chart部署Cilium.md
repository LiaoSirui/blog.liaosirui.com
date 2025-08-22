## 支持的安装方式

Cilium 支持 2 种安装方式：

- Cilium CLI
- Helm chart

## 安装需求

官方文档：

- 系统安装需求：https://docs.cilium.io/en/v1.14/operations/system_requirements/

要安装 Cilium, 最低系统需求如下：

- 主机是 AMD64 或 AArch64（即 arm64) 架构
- 需要开通某些防火墙规则，详见：https://docs.cilium.io/en/stable/operations/system_requirements/#firewall-rules
- Linux Kernel >= 4.19.57（对于 RHEL8, Linux Kernel >= 4.18)

如果需要用到 Cilium 的高级功能，则需要更高版本的内核，具体如下：

| Cilium Feature                                               | Minimum Kernel Version |
| ------------------------------------------------------------ | ---------------------- |
| [Bandwidth Manager](https://docs.cilium.io/en/v1.14/network/kubernetes/bandwidth-manager/#bandwidth-manager) | >= 5.1                 |
| [Egress Gateway](https://docs.cilium.io/en/v1.14/network/egress-gateway/#egress-gateway) | >= 5.2                 |
| VXLAN Tunnel Endpoint (VTEP) Integration                     | >= 5.2                 |
| [WireGuard Transparent Encryption](https://docs.cilium.io/en/v1.14/security/network/encryption-wireguard/#encryption-wg) | >= 5.6                 |
| Full support for [Session Affinity](https://docs.cilium.io/en/v1.14/network/kubernetes/kubeproxy-free/#session-affinity) | >= 5.7                 |
| BPF-based proxy redirection                                  | >= 5.7                 |
| Socket-level LB bypass in pod netns                          | >= 5.7                 |
| L3 devices                                                   | >= 5.8                 |
| BPF-based host routing                                       | >= 5.10                |
| IPv6 BIG TCP support                                         | >= 5.19                |
| IPv4 BIG TCP support                                         | >= 6.3                 |

## Helm Chart 安装

官方：

- Cilium Charts：<https://github.com/cilium/charts>
- Charts 源码：<https://github.com/cilium/cilium/tree/v1.13.2/install/kubernetes/cilium>

- 使用 helm 安装：<https://docs.cilium.io/en/v1.14/gettingstarted/k8s-install-helm/>

```bash
helm repo add cilium https://helm.cilium.io/
```

当前最新的稳定版本 v1.14.3

Chart 的源码详见：<https://github.com/cilium/cilium/tree/v1.14.3/install/kubernetes/cilium>

使用 value

```yaml
hubble:
  enabled: true
  relay:
    enabled: true
    tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
  ui:
    enabled: true
    tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
ipam:
  operator:
    clusterPoolIPv4PodCIDR: "10.4.0.0/16"
    clusterPoolIPv4MaskSize: 24

ipv4NativeRoutingCIDR: "10.244.244.0/24"

k8s:
  requireIPv4PodCIDR: true

image:
  useDigest: false

operator:
  image:
    useDigest: false

hostPort:
  enabled: true

nodePort:
  enabled: true

loadBalancer:
  algorithm: maglev

```

使用 helm 进行安装

```bash
helm upgrade --install cilium cilium/cilium \
  --version v1.14.3 \
  --namespace kube-system \
  -f ./values.yaml
```

查看 helm

```bash
> helm get values -n kube-system cilium

...
USER-SUPPLIED VALUES:
hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true
...
```

清理没有被管理的 Pod

```bash
kubectl get pods --all-namespaces \
  -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork \
  --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod --force
```

### 安装 CLI

官方给的安装脚本如下

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

更改为：

```bash
export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
export CLI_ARCH=amd64

cd $(mktemp -d)

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz

tar xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin

chmod +x /usr/local/bin/cilium
```

### 安装后检查

查看状态

```bash
> cilium status --wait

    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

Deployment        cilium-operator    Desired: 2, Ready: 2/2, Available: 2/2
DaemonSet         cilium             Desired: 4, Ready: 4/4, Available: 4/4
Containers:       cilium             Running: 4
                  cilium-operator    Running: 2
Cluster Pods:     5/5 managed by Cilium
Image versions    cilium-operator    quay.io/cilium/operator-generic:v1.14.3: 2
                  cilium             quay.io/cilium/cilium:v1.14.3: 4
```

检查安装是否成功

```bash
# cilium connectivity test
cilium connectivity test --request-timeout 30s --connect-timeout 10s
```

在中国安装时，由于网络环境所限，可能部分测试会失败（如访问 1.1.1.1:443). 属于正常情况。 连接性测试需要至少两个 worker node 才能在群集中成功部署。连接性测试 pod 不会在以控制面角色运行的节点上调度

查看 Cilium Install 具体启用了哪些功能：

```bash
kubectl -n kube-system exec ds/cilium -- cilium status
```

例如：
```text
Defaulted container "cilium-agent" out of: cilium-agent, config (init), mount-cgroup (init), apply-sysctl-overwrites (init), mount-bpf-fs (init), clean-cilium-state (init), install-cni-binaries (init)
KVStore:                 Ok   Disabled
Kubernetes:              Ok   1.27 (v1.27.3) [linux/amd64]
Kubernetes APIs:         ["EndpointSliceOrEndpoint", "cilium/v2::CiliumClusterwideNetworkPolicy", "cilium/v2::CiliumEndpoint", "cilium/v2::CiliumNetworkPolicy", "cilium/v2::CiliumNode", "cilium/v2alpha1::CiliumCIDRGroup", "core/v1::Namespace", "core/v1::Pods", "core/v1::Service", "networking.k8s.io/v1::NetworkPolicy"]
KubeProxyReplacement:    False   [net0  (Direct Routing)]
Host firewall:           Disabled
CNI Chaining:            none
Cilium:                  Ok   1.14.3 (v1.14.3-252a99ef)
NodeMonitor:             Listening for events on 12 CPUs with 64x4096 of shared memory
Cilium health daemon:    Ok   
IPAM:                    IPv4: 2/254 allocated from 10.1.3.0/24, 
IPv4 BIG TCP:            Disabled
IPv6 BIG TCP:            Disabled
BandwidthManager:        Disabled
Host Routing:            Legacy
Masquerading:            IPTables [IPv4: Enabled, IPv6: Disabled]
Controller Status:       20/20 healthy
Proxy Status:            OK, ip 10.1.3.111, 0 redirects active on ports 10000-20000, Envoy: embedded
Global Identity Range:   min 256, max 65535
Hubble:                  Ok              Current/Max Flows: 4095/4095 (100.00%), Flows/s: 0.67   Metrics: Disabled
Encryption:              Disabled        
Cluster health:          4/4 reachable   (2023-10-31T06:28:49Z)
```

## 参考资料

- <https://tinychen.com/20220510-k8s-04-deploy-k8s-with-cilium/#5-1-%E5%AE%89%E8%A3%85cilium>