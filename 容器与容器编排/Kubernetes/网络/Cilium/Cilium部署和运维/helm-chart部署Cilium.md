## 支持的安装方式

Cilium 支持 2 种安装方式：

- Cilium CLI
- Helm chart

## 安装需求

官方文档：

- 系统安装需求：<https://docs.cilium.io/en/v1.18/operations/system_requirements/>

要安装 Cilium, 最低系统需求如下：

- 主机是 AMD64 或 AArch64（即 arm64) 架构
- 需要开通某些防火墙规则，详见：<https://docs.cilium.io/en/stable/operations/system_requirements/#firewall-rules>
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
- Charts 源码：<https://github.com/cilium/cilium/tree/v1.18.4/install/kubernetes/cilium>

- 使用 helm 安装：<https://docs.cilium.io/en/v1.18/gettingstarted/k8s-install-helm/>

```bash
helm repo add cilium https://helm.cilium.io/
```

当前最新的稳定版本 v1.18.4

Chart 的源码详见：<https://github.com/cilium/cilium/tree/v1.18.4/install/kubernetes/cilium>

使用 value

```yaml
imagePullSecrets:
  - name: "image-pull-secrets"

ipv4:
  enabled: true
ipv6:
  enabled: true

k8s:
  apiServerURLs: "https://apiserver.cluster.local:6443"
kubeProxyReplacement: "true"
kubeProxyReplacementHealthzBindAddr: "0.0.0.0:1025"
k8sServiceHost: "apiserver.cluster.local"
k8sServicePort: "6443"

ipam:
  operator:
    clusterPoolIPv4PodCIDRList: ["10.3.0.0/16"]
    clusterPoolIPv4MaskSize: 24
    clusterPoolIPv6PodCIDRList: ["fd85:ee78:d8a6:8607::3:0000/112"]
    clusterPoolIPv6MaskSize: 120

image:
  repository: "harbor.alpha-quant.tech/3rd_party/quay.io/cilium/cilium"
  tag: "v1.18.4"
  useDigest: false

envoy:
  image:
    repository: "harbor.alpha-quant.tech/3rd_party/quay.io/cilium/cilium-envoy"
    tag: "v1.34.10-1762597008-ff7ae7d623be00078865cff1b0672cc5d9bfc6d5"
    useDigest: false

operator:
  replicas: 1
  image:
    repository: "harbor.alpha-quant.tech/3rd_party/quay.io/cilium/operator"
    # quay.io/cilium/operator-generic
    tag: "v1.18.4"
    useDigest: false

hubble:
  enabled: true
  relay:
    enabled: true
    image:
      repository: "quay.io/cilium/hubble-relay"
      tag: "v1.18.4"
      useDigest: false
  ui:
    enabled: true
    backend:
      image:
        repository: "quay.io/cilium/hubble-ui-backend"
        tag: "v0.13.3"
        useDigest: false
    frontend:
      image:
        repository: "quay.io/cilium/hubble-ui"
        tag: "v0.13.3"
        useDigest: false

nodePort:
  enabled: true
  range: "30000,60000"

bpf:
  masquerade: true

enableIPv4Masquerade: true
enableIPv6Masquerade: true

policyAuditMode: false

```

使用 helm 进行安装

```bash
helm upgrade --install cilium cilium/cilium \
  --version v1.18.4 \
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

文档：<https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli>

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
# cilium status --wait
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       OK
    \__/       ClusterMesh:        disabled

DaemonSet              cilium                   Desired: 1, Ready: 1/1, Available: 1/1
DaemonSet              cilium-envoy             Desired: 1, Ready: 1/1, Available: 1/1
Deployment             cilium-operator          Desired: 1, Ready: 1/1, Available: 1/1
Deployment             hubble-relay             Desired: 1, Ready: 1/1, Available: 1/1
Deployment             hubble-ui                Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium                   Running: 1
                       cilium-envoy             Running: 1
                       cilium-operator          Running: 1
                       clustermesh-apiserver    
                       hubble-relay             Running: 1
                       hubble-ui                Running: 1
Cluster Pods:          8/8 managed by Cilium
Helm chart version:    1.18.4
Image versions         cilium             harbor.alpha-quant.tech/3rd_party/quay.io/cilium/cilium:v1.18.4: 1
                       cilium-envoy       harbor.alpha-quant.tech/3rd_party/quay.io/cilium/cilium-envoy:v1.34.10-1762597008-ff7ae7d623be00078865cff1b0672cc5d9bfc6d5: 1
                       cilium-operator    harbor.alpha-quant.tech/3rd_party/quay.io/cilium/operator-generic:v1.18.4: 1
                       hubble-relay       harbor.alpha-quant.tech/3rd_party/quay.io/cilium/hubble-relay:v1.18.4: 1
                       hubble-ui          harbor.alpha-quant.tech/3rd_party/quay.io/cilium/hubble-ui-backend:v0.13.3: 1
                       hubble-ui          harbor.alpha-quant.tech/3rd_party/quay.io/cilium/hubble-ui:v0.13.3: 1
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
KVStore:                      Disabled   
Kubernetes:                   Ok         1.33 (v1.33.6) [linux/amd64]
Kubernetes APIs:              ["EndpointSliceOrEndpoint", "cilium/v2::CiliumCIDRGroup", "cilium/v2::CiliumClusterwideNetworkPolicy", "cilium/v2::CiliumEndpoint", "cilium/v2::CiliumNetworkPolicy", "cilium/v2::CiliumNode", "core/v1::Pods", "networking.k8s.io/v1::NetworkPolicy"]
KubeProxyReplacement:         True   [nm-bond   172.31.24.199 fe80::184:8e89:83fd:7ccc (Direct Routing)]
Host firewall:                Disabled
SRv6:                         Disabled
CNI Chaining:                 none
CNI Config file:              successfully wrote CNI configuration file to /host/etc/cni/net.d/05-cilium.conflist
Cilium:                       Ok   1.18.4 (v1.18.4-afda2aa9)
NodeMonitor:                  Listening for events on 28 CPUs with 64x4096 of shared memory
Cilium health daemon:         Ok   
IPAM:                         IPv4: 10/254 allocated from 10.3.0.0/24, IPv6: 10/254 allocated from fd85:ee78:d8a6:8607::3:0/120
IPv4 BIG TCP:                 Disabled
IPv6 BIG TCP:                 Disabled
BandwidthManager:             Disabled
Routing:                      Network: Tunnel [vxlan]   Host: Legacy
Attach Mode:                  TCX
Device Mode:                  veth
Masquerading:                 IPTables [IPv4: Enabled, IPv6: Enabled]
Controller Status:            56/56 healthy
Proxy Status:                 OK, ip 10.3.0.179, 0 redirects active on ports 10000-20000, Envoy: external
Global Identity Range:        min 256, max 65535
Hubble:                       Ok                           Current/Max Flows: 4095/4095 (100.00%), Flows/s: 7.10   Metrics: Disabled
Encryption:                   Disabled                     
Cluster health:               0/1 reachable                (2025-12-11T02:50:41Z)   (Probe interval: 1m36.566274746s)
Name                          IP                           Node                     Endpoints
  aq-dev-server (localhost)   172.31.24.199,fc00::10ca:1   0/2                      2/2
Modules Health:               Stopped(12) Degraded(0) OK(89)
```

## 测试 Pod-To-Pod 流量

新建两个 Pod

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: default
spec:
  nodeName: aq-dev-server # 指定 Schedule 到 aq-dev-server
  containers:
    - name: client
      image: harbor.alpha-quant.tech/3rd_party/docker.io/nicolaka/netshoot:v0.9
      command: ["sleep", "infinity"]
---
apiVersion: v1
kind: Pod
metadata:
  name: server
  namespace: default
spec:
  nodeName: aq-dev-server # 指定 Schedule 到 aq-dev-server
  containers:
    - name: server
      image: harbor.alpha-quant.tech/3rd_party/docker.io/openresty/openresty:1.27.1.2-3-bullseye-fat

```

从 `client` Pod 向 `server` Pod 发出 HTTP 请求是否能成功得到响应：

```bash
SERVER_IP=$(kubectl get po server -o jsonpath='{.status.podIP}')
kubectl exec client -- curl -s $SERVER_IP
```

同样的方式，将上述 Pod  改为不同节点，测试跨节点的 Pod-to-Pod 流量

## Hubble UI

临时访问

```bash
kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 12000:80
```

安装 Hubble

```bash
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
```

