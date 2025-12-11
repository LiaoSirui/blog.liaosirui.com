由于启用 kubeProxyReplacement 功能，请依照 Cilium 官方文件提供的 `node-local-dns.yaml` 安装

<https://docs.cilium.io/en/stable/network/kubernetes/local-redirect-policy/#node-local-dns-cache>

```bash
wget https://raw.githubusercontent.com/cilium/cilium/1.18.4/examples/kubernetes-local-redirect/node-local-dns-lrp.yaml

wget https://raw.githubusercontent.com/cilium/cilium/1.18.4/examples/kubernetes-local-redirect/node-local-dns.yaml

```

替换 `__PILLAR__DNS__SERVER__`

```bash
kubectl get svc coredns -n kube-system -o jsonpath={.spec.clusterIP}
```

替换后启动 `node-local-dns.yaml`，启动后查看状态

```bash
kubectl get ds -n kube-system node-local-dns
```

运行一个测试容器

```bash
kubectl run netshoot \
  --image=harbor.alpha-quant.tech/3rd_party/docker.io/nicolaka/netshoot:v0.9 \
  -n default -- sleep infinity
```

先查看 netshoot Pod 里面的 `/etc/resolv.conf` 内容

```bash
kubectl exec -n default netshoot -- cat /etc/resolv.conf
```

可以看到仍指向集群地址

```bash
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.4.0.10
options ndots:
```

先简单验证一下 netshoot 现在 DNS 解析是正常的：

```bash
kubectl exec -n default netshoot -- dig google.com
```

接着来使用 `hubble observe` 来观察封包：

```bash
kubectl exec -n kube-system cilium-75f8p -- hubble observe --protocol udp --port 53 -f
```

执行 `hubble observe` 后，使用 netshoot Pod 发出 DNS 查询封包

![image-20251211184210392](./.assets/NodeLocalDNSCache/image-20251211184210392.png)

注意 cilium 还需要开启 `localRedirectPolicies.enabled=true`，设置后重启

```bash
kubectl rollout restart deploy cilium-operator -n kube-system
kubectl rollout restart ds cilium -n kube-system
```

部署 `node-local-dns-lrp.yaml`

查看一下 Service BPF Map：

```bash
kubectl exec -n kube-system cilium-hlmbw -- cilium-dbg service list
```

