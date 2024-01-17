Git 仓库：<https://github.com/komodorio/helm-dashboard>

![img](.assets/2022-12-03-17-46-37-image.png)

Helm Dashboard 插件提供了一种 UI 驱动的方式来查看已安装的 Helm Chart、查看其修订历史记录和相应的 K8s 资源。此外，你还可以执行简单的操作，例如回滚到修订版或升级到新版本。

该工具的一些核心功能如下所示：

- 查看所有已安装的 Chart 及其修订历史

- 查看过去修订的清单差异

- 浏览 Chart 产生的 K8s 资源

- 易于回滚或升级版本，具有清晰和简单的清单差异

- 与流行的工具集成

- 在多个集群之间轻松切换

`Helm-Dashboard` 使用本地 Helm 和 Kubectl 配置运行，无需额外设置。要安装 `Helm-Dashboard`，只需运行以下 Helm 命令即可：

```bash
helm plugin install https://github.com/komodorio/helm-dashboard.git
```

安装后，运行以下命令启动 UI：

```bash
helm dashboard
```

上面的命令将启动本地 Web 服务并在新的浏览器选项卡中打开 UI。

要卸载的话也只需要执行下面的命令即可：

```bash
helm plugin uninstall dashboard
```
