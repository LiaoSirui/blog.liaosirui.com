官方提供的 helm chart：<https://github.com/coredns/helm>

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
