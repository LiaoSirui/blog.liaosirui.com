如果使用的是 Kubernetes 1.16 及以上版本，则需要启用 `ipip` 模式。运行以下命令启用：

```bash
kubectl set env daemonset/calico-node -n kube-system FELIX_IPINIPENABLED=true

kubectl set env daemonset/calico-node -n kube-system FELIX_IPINIPENABLED=true
```