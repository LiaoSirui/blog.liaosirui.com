
官方文档：<https://kubernetes.github.io/ingress-nginx/kubectl-plugin>

## 安装

```bash
kubectl krew install ingress-nginx
```

安装完成后，运行：

```bash
kubectl ingress-nginx --help
```

## 使用

### lint

```bash
kubectl ingress-nginx lint --all-namespaces --verbose
```

### 查看日志

和 kubectl logs 类似，可以直接查看 ingress-nginx-controller 的日志：

```bash
kubectl ingress-nginx logs -f -n ingress-nginx
```

### ssh

类似于 `kubectl ingress-nginx exec -it -- /bin/bash`

可以直接执行如下命令，进入一个 ingress-nginx-controller 容器：

```bash
kubectl ingress-nginx ssh -n ingress-nginx
```
