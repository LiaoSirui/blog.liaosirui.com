## Kube-Bench 简介

Kube-Bench 是一款针对 Kubernete 的安全检测工具，从本质上来说，Kube-Bench 是一个基于 Go 开发的应用程序，它可以帮助研究人员对部署的 Kubernete 进行安全检测，安全检测原则遵循 CIS Kubernetes Benchmark

相关链接：

- CIS Kubernetes Benchmark：<https://www.cisecurity.org/benchmark/kubernetes>

- GitHub 仓库：<https://github.com/aquasecurity/kube-bench.git>

安装：

```bash
go install github.com/aquasecurity/kube-bench@latest

go install github.com/aquasecurity/kube-bench@v0.6.19
```

## Kube-Bench 使用

如果想要指定 CIS Benchmark 的 target，比如说 master、node、etcd 等，你可以运行 “run --targets” 子命令：

```bash
kube-bench --benchmark cis-1.8 run --targets master,node

kube-bench --benchmark cis-1.8 run --targets master,node,etcd,policies
```

不同 CIS Benchmark 版本对应的有效目标见官网
