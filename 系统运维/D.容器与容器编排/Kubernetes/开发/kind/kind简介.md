## kind 简介

Kind（Kubernetes in Docker）是一种使用 Docker 容器作为 Node 节点，运行本地 Kubernetes 集群的工具。我们仅需要安装好 Docker，就可以在几分钟内快速创建一个或多个 Kubernetes 集群。为了方便实验，本文使用 Kind 来搭建 Kubernetes 集群环境

仓库地址：<https://github.com/kubernetes-sigs/kind/>

官方文档：<https://kind.sigs.k8s.io/>

## kind 使用

安装

```bash
go install sigs.k8s.io/kind@latest

# 安装指定版本
# go install sigs.k8s.io/kind@v0.20.0
```

创建集群

```bash
kind create cluster
```

删除集群

```bash
kind delete cluster
```


