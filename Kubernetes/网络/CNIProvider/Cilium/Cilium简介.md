## Cilium 简介

Cilium 是一个基于 eBPF 和 XDP 的高性能容器网络方案的开源项目，目标是为微服务环境提供网络、负载均衡、安全功能，主要定位是容器平台

官方：

- Github 仓库：<https://github.com/cilium/cilium>

![Cilium feature overview](.assets/Cilium%E7%AE%80%E4%BB%8B/cilium_overview.png)

<img src=".assets/Cilium%E7%AE%80%E4%BB%8B/9885453-6b09787b4b207027.png" alt="img" style="zoom: 50%;" />

### Why Cilium

现在应用程序服务的发展已从单体结构转变为微服务架构，微服务间的的通信通常使用轻量级的 http 协议。微服务应用往往是经常性更新变化的，在持续交付体系中为了应对负载的变化通常会横向扩缩容，应用容器实例也会随着应用的更新而被创建或销毁

这种高频率的更新对微服务间的网络可靠连接带来了挑战：

- 传统的 Linux 网络安全连接方式是通过过滤器（例如 iptables ）在 IP 地址及端口上进行的，但是在微服务高频更新的环境下，应用容器实例的 IP 端口是会经常变动。在微服务应用较多的场景下，由于这种频繁的变动，成千上万的 iptables 规则将会被频繁的更新
- 出于安全目的，协议端口（例如 HTTP 流量的 TCP 端口 80）不再用于区分应用流量，因为该端口用于跨服务的各种消息。
- 传统系统主要使用 IP 地址作为标识手段，在微服务频繁更新的架构中，某个 IP 地址可能只会存在短短的几秒钟，这将难以提供准确的可视化追踪痕迹

Cilium 通过利用 BPF 具有能够透明的注入网络安全策略并实施的功能，区别于传统的 IP 地址标识的方式，Cilium 是基于 service / pod /container 标识来实现的，并且可以在应用层实现 L7 Policy 网络过滤。总之，Cilium 通过解藕 IP 地址，不仅可以在高频变化的微服务环境中应用简单的网络安全策略，还能在支持 L3/L4 基础上通过对 http 层进行操作来提供更强大的网络安全隔离。BPF 的使用使 Cilium 甚至可以在大规模环境中以高度可扩展的方式解决这些挑战问题

### Cilium 的主要功能特性

- 支持 L3/L4/L7 安全策略，这些策略按照使用方法又可以分为

  - 基于身份的安全策略（Security identity）
  - 基于 CIDR 的安全策略
  - 基于标签的安全策略

- 支持三层扁平网络

  Cilium 的一个简单的扁平 3 层网络具有跨多个群集的能力，可以连接所有应用程序容器。通过使用主机作用域分配器，可以简化 IP 分配，这意味着每台主机不需要相互协调就可以分配到 IP subnet

  Cilium 支持以下多节点的网络模型：

  - Overlay 网络，当前支持 Vxlan 和 Geneve ，但是也可以启用 Linux 支持的所有封装格式
  - Native Routing, 使用 Linux 主机的常规路由表或云服务商的高级网络路由等。此网络要求能够路由应用容器的 IP 地址

- 提供基于 BPF 的负载均衡。Cilium 能对应用容器间的流量及外部服务支持分布式负载均衡

- 提供便利的监控手段和排错能力

  可见性和快速的问题定位能力是一个分布式系统最基础的部分。除了传统的 tcpdump 和 ping 命令工具，Cilium 提供了：

  1. 具有元数据的事件监控：当一个 Packet 包被丢弃，这个工具不会只报告这个包的源 IP 和目的 IP，此工具还会提供关于发送方和接送方所有相关的标签信息
  2. 决策追踪：为何一个 packet 包被丢弃，为何一个请求被拒绝？策略追踪框架允许追踪正在运行的工作负载和基于任意标签定义的策略决策过程
  3. 通过 Prometheus 暴露 Metrics 指标：关键的 Metrics 指标可以通过 Prometheus 暴露出来到监控看板上进行集成展示
  4. Hubble：一个专门为 Cilium 开发的可视化平台。它可以通过 flow log 来提供微服务间的依赖关系，监控告警操作及应用服务安全策略可视化

## 安装 Cilium

### 安装需求

官方文档：

- 系统安装需求：https://docs.cilium.io/en/v1.13/operations/system_requirements/

安装需求：

- 内核版本 >=4.9.17

### Helm Chart 安装

官方：

- Cilium Charts：<https://github.com/cilium/charts>
- Charts 源码：<https://github.com/cilium/cilium/tree/v1.13.2/install/kubernetes/cilium>

- 使用 helm 安装：<https://docs.cilium.io/en/v1.13/gettingstarted/k8s-install-helm/>

```bash
helm repo add cilium https://helm.cilium.io/
```

当前最新的稳定版本 v1.13.2

Chart 的源码详见：<https://github.com/cilium/cilium/tree/v1.13.2/install/kubernetes/cilium>

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
k8s:
  requireIPv4PodCIDR: true
hostPort:
  enabled: true
nodePort:
  enabled: true
kubeProxyReplacement: strict
k8sServiceHost: apiserver.local.liaosirui.com
k8sServicePort: 6443
loadBalancer:
  algorithm: maglev

```

使用 helm 进行安装

```bash
helm upgrade --install cilium cilium/cilium \
  --version 1.13.2 \
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

### 通过命令行安装

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
cilium status --wait
```

![image-20221220145837458](.assets/Cilium%E7%AE%80%E4%BB%8B/image-20221220145837458.png)

检查安装是否成功

```bash
cilium connectivity test
```

参考：<https://tinychen.com/20220510-k8s-04-deploy-k8s-with-cilium/#5-1-%E5%AE%89%E8%A3%85cilium>

## 参考资料

https://zhuanlan.zhihu.com/p/468686172

<https://www.jianshu.com/p/090c3d32c2be>