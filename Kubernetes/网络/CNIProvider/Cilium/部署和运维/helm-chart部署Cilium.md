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

![image-20231030141041449](.assets/helm-chart部署Cilium/image-20231030141041449.png)

检查安装是否成功

```bash
cilium connectivity test
```

参考：<https://tinychen.com/20220510-k8s-04-deploy-k8s-with-cilium/#5-1-%E5%AE%89%E8%A3%85cilium>