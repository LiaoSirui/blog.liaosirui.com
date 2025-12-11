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

