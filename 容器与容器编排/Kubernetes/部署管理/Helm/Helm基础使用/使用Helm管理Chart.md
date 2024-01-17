
当期使用 Helm 版本：v3.9.4，下载地址：<https://get.helm.sh/helm-v3.9.4-linux-amd64.tar.gz>

```bash
> helm version

version.BuildInfo{Version:"v3.9.4", GitCommit:"dbc6d8e20fe1d58d50e6ed30f09a04a77e4c68db", GitTreeState:"clean", GoVersion:"go1.17.13"}
```

helm 工具有几个用于处理 chart 的命令

它可以为你创建一个新的 chart：

```bash
helm crate chart-demo
```

编辑完 chart 后，helm 可以将其打包到 chart 压缩包中：

```bash
helm package chart-demo
```

可以用 helm 来帮助查找 chart 格式或信息的问题：

```bash
helm lint chart-demo
```
