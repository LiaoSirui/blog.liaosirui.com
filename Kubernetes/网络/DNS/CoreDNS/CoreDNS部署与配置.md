## 部署 CoreDNS

官方提供的 helm chart：<https://github.com/coredns/helm>

kubernetes 官方部署的默认 coredns 版本：<https://github.com/coredns/deployment/blob/master/kubernetes/CoreDNS-k8s_version.md>

![image-20230508114534203](.assets/CoreDNS%E9%83%A8%E7%BD%B2%E4%B8%8E%E9%85%8D%E7%BD%AE/image-20230508114534203.png)

添加仓库

```bash
helm repo add coredns https://coredns.github.io/helm
```

查看最新的版本

```bash
> helm search repo coredns

NAME            CHART VERSION   APP VERSION     DESCRIPTION                                       
coredns/coredns 1.22.0          1.10.1          CoreDNS is a DNS server that chains plugins and...
```

拉取最新的 chart

```bash
helm pull coredns/coredns --version 1.22.0

helm pull coredns/coredns --version 1.22.0 --untar
```

使用如下的 `values.yaml`

```yaml
replicaCount: 3

prometheus:
  service:
    enabled: false
  monitor:
    enabled: false

service:
  name: ""
  clusterIP: "10.96.0.20"

serviceAccount:
  create: true
  name: ""

deployment:
  enabled: true
  name: ""

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: In
          values:
          - ""
          - master

tolerations:
  - operator: Exists

nodeSelector:
  kubernetes.io/os: linux
  kubernetes.io/arch: amd64

servers:
  - zones:
      - zone: .
    port: 53
    plugins:
      - name: errors
      - name: health
        configBlock: |-
          lameduck 5s
      - name: ready
      - name: kubernetes
        parameters: cluster.local in-addr.arpa ip6.arpa
        configBlock: |-
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
          ttl 30
      - name: prometheus
        parameters: 0.0.0.0:9153
      - name: forward
        parameters: . /etc/resolv.conf
      - name: cache
        parameters: 30
      - name: loop
      - name: reload
      - name: loadbalance

hpa:
  enabled: false

autoscaler:
  enabled: false

```

安装命令如下：

```bash
helm upgrade \
  --install \
  --namespace=aipaas-system \
  coredns coredns/coredns \
  --version 1.22.0 \
  -f ./values.yaml
```

## 自定义 hosts

加入 hosts：

```ini
            hosts {
                10.10.10.10 harbor.example.com
                10.10.10.11 grafana.example.com
                fallthrough
            }

```

## 优化

### 合理控制 CoreDNS 副本数

考虑以下几种方式:

（1）根据集群规模预估 coredns 需要的副本数，直接调整 coredns deployment 的副本数:

```bash
kubectl -n kube-system scale --replicas=10 deployment/coredns
```

（2）为 coredns 定义 HPA 自动扩缩容

（3）安装 [cluster-proportional-autoscaler](https://github.com/kubernetes-sigs/cluster-proportional-autoscaler) 以实现更精确的扩缩容（推荐）

### 禁用 IPV6 的解析

CoreDNS 有一个 [template](https://coredns.io/plugins/template/) 的插件，可以用它来禁用 IPV6 的解析，只需要给 CoreDNS 加上如下的配置:

```txt
template ANY AAAA {
    rcode NXDOMAIN
}
```

这个配置的含义是：给所有 IPV6 的解析请求都响应空记录，即无此域名的 IPV6 记录

### 启用 autopath

启用 CoreDNS 的 autopath 插件可以避免每次域名解析经过多次请求才能解析到，原理是 CoreDNS 智能识别拼接过 search 的 DNS 解析，直接响应 CNAME 并附上相应的 ClusterIP，一步到位，可以极大减少集群内 DNS 请求数量

- 加上 `autopath @kubernetes`
- 默认的 `pods insecure` 改成 `pods verified`

需要注意的是，启用 autopath 后，由于 coredns 需要 watch 所有的 pod，会增加 coredns 的内存消耗，根据情况适当调节 coredns 的 memory request 和 limit
