## NodeLocal DNS 简介

集群规模较大并发较高的情况下对 DNS 进行优化

官方文档：

- Using NodeLocal DNSCache in Kubernetes Clusters <https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/>
- NodeLocal AddOn <https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml>

在 Kubernetes 中可以使用 CoreDNS 来进行集群的域名解析，但是如果在集群规模较大并发较高的情况下我们仍然需要对 DNS 进行优化，典型的就是大家比较熟悉的 CoreDNS 会出现超时 5s 的情况

集群在做 DNS 解析时，如果请求量大，那 CoreDNS 将承受压力，会有如下影响：

- 查询变慢，影响业务性能。
- 为保证性能，CoreDNS 需要更高规格的配置

启用 NodeLocal DNS 的优势：

- 在当前的 DNS 架构下，如果没有本地 kube-dns/CoreDNS 实例，具有最高 DNS QPS 的 Pod 可能必须访问不同的节点。拥有本地缓存将有助于改善这种情况下的延迟
- 跳过 iptables DNAT 和连接跟踪将有助于减少 [conntrack 竞争](https://github.com/kubernetes/kubernetes/issues/56903) 并避免 UDP DNS 条目填满 conntrack 表
- 从本地缓存代理到 kube-dns 服务的连接可以升级到 TCP。TCP conntrack 条目将在连接关闭时被删除，而 UDP 条目则必须超时（[默认](https://www.kernel.org/doc/Documentation/networking/nf_conntrack-sysctl.txt) `nf_conntrack_udp_timeout` 为 30 秒）
- 将 DNS 查询从 UDP 升级到 TCP 将减少归因于丢弃的 UDP 数据包和 DNS 超时通常长达 30 秒（3 次重试 + 10 秒超时）的尾部延迟。由于 nodelocal 缓存侦听 UDP DNS 查询，因此无需更改应用程序
- 节点级别 DNS 请求的指标和可见性
- 可以重新启用负缓存，从而减少对 kube-dns 服务的查询次数

启用 NodeLocal DNSCache 后 DNS 查询所遵循的路径：

![https://support.huaweicloud.com/usermanual-cce/zh-cn_image_0000001153514018.png](.assets/NodeLocalDNS%E7%AE%80%E4%BB%8B/zh-cn_image_0000001153514018.png)

## 部署 NodeLocalDNS

NodeLocal DNSCache 定义地址为 https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml

该文件包含如下几个资源：

- 名为 `node-local-dns` 的 ServiceAccount
- 名为 `kube-dns-upstream` 的 Service
- 名为 `node-local-dns` 的 ConfigMap
- 名为 `node-local-dns` 的 DaemonSet

其中几个关键字段的含义：

- `__PILLAR__DNS__SERVER__`：表示 coredns 这个 Service 的 ClusterIP，可以通过命令 `kubectl get svc -n kube-system -l k8s-app=coredns -o jsonpath='{$.items[*].spec.clusterIP}'` 获取，一般是 `10.247.3.10`
- `__PILLAR__LOCAL__DNS__`：表示 DNSCache 本地的 IP，默认为 `169.254.20.10`
- `__PILLAR__DNS__DOMAIN__`：表示集群域，默认就是 cluster.local
- `__PILLAR__CLUSTER__DNS__`：表示集群内查询的上游服务器
- `__PILLAR__UPSTREAM__SERVERS__`：表示为外部查询的上游服务器

使用如下命令替换

```bash
sed 's/__PILLAR__DNS__SERVER__/10.247.3.10/g
  s/__PILLAR__LOCAL__DNS__/169.254.20.10/g
  s/__PILLAR__DNS__DOMAIN__/cluster.local/g' nodelocaldns.yaml
```

daemonset 启动命令替换如下
```yaml
args: [ "-localip", "169.254.20.10", "-conf", "/etc/Corefile", "-upstreamsvc", "coredns" ]
```

创建一个 pod 使用 NodeLocalDNS 进行验证

```yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx:alpine
    name: container-0
  dnsConfig:
    nameservers:
    - 169.254.20.10
    searches:
    - default.svc.cluster.local
    - svc.cluster.local
    - cluster.local
    options:
    - name: ndots
      value: '2'
  imagePullSecrets:
  - name: default-secret
```

进入容器，访问外部域名或内部 Service 域名，如果能正常访问，则说明 NodeLocal DNSCache 连接了 CoreDNS，访问域名正常

```bash
# kubectl exec nginx -it -- /bin/sh
/ # ping www.baidu.com
PING www.baidu.com (110.242.68.3): 56 data bytes
64 bytes from 110.242.68.3: seq=0 ttl=45 time=10.911 ms
64 bytes from 110.242.68.3: seq=1 ttl=45 time=10.908 ms
64 bytes from 110.242.68.3: seq=2 ttl=45 time=10.960 ms
......
/ # curl hello.default.svc.cluster.local:80
hello world
```

## dnsperf 压测对比

未使用 nodelocaldns 时，测试 3 次；结论，连续三次测试，QPS 的值稳定性较差，获取到的值有高有低，通过监控数据发现大量请求都集中在单个 DNS 服务器上

```bash
dnsperf -l 120 -s 10.96.0.10 -d testfile
```

修改为 nodelocaldns 方式测试

```bash
dnsperf -l 120 -s 169.254.20.10 -d testfile
```

