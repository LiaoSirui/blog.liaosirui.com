## Conan 简介

Conan 是一个可以对 C/C++ 进行依赖管理的包管理器

官方：

- GitHub 仓库：<https://github.com/conan-io/conan>

Conan 会在第一次启动时自动配置好默认的 Profile 和 Remote 设置。它的配置以及本地的二进制仓库均存储在用户目录下`~/.conan/`中

另外，当使用 Artifactory 来搭建私有仓库时，需要启用 `general.revisions_enabled = 1`这个开关

## 基本概念

### 软件包

Conan 使用这样的格式来描述一个软件包：`名称/版本@用户/渠道`。其中渠道（Channel）用来描述是稳定版（Stable）还是测试版（Testing）等信息，以 boost 为例，可以看到这样的包名：

```
boost/1.64.0@conan/stable
boost/1.65.1@conan/stable
boost/1.66.0@conan/stable
boost/1.67.0@conan/stable
boost/1.68.0@conan/stable
boost/1.69.0@conan/stable
boost/1.70.0@conan/stable
```

## Conan 使用

在 Conan 中，远程仓库（Remote Repository）是用来存储和共享 C++ 库的服务器。远程仓库可以是公共仓库（如 conan-center）或者是公司内部的私有仓库。通过远程仓库，开发者可以方便地下载预构建的库或上传自己编译的库供他人使用。

Conan 中的远程仓库使用 REST API 进行通信，因此你可以使用 Conan 客户端与任何符合 API 规范的远程仓库进行交互。

### 绑定远程仓库

使用`conan remote`命令来管理远程仓库。首先，可以查看当前有哪些远程仓库已经绑定

```bash
conan remote list
```

这个命令将会列出所有当前已绑定的远程仓库，以及它们的 URL

```bash
conancenter: https://center2.conan.io [Verify SSL: True, Enabled: True]
```

有时某些远程仓库可能不再需要，或者其 URL 已失效，此时我们需要将其从 Conan 的远程仓库列表中删除

```bash
conan remote remove <remote_name>

# 移除旧的 conancenter
# conan remote remove conancenter
```

假设我们想要绑定一个新的远程仓库，使用`conan remote add`命令。语法如下：

```bash
conan remote add conancenter --insecure http://nexus.alpha-quant.tech/repository/conan
```

执行完毕后，可以再次运行`conan remote list`查看新仓库是否成功绑定

在 Conan中，远程仓库是按照顺序进行查询的。当我们执行`conan install`命令时，Conan会依次从已绑定的远程仓库中查找所需的依赖库。因此，仓库的顺序非常重要

如果希望将`conancenter`设置为优先仓库，可以使用：

```bash
conan remote update conancenter 0
```

`0`表示该仓库将成为首要查询的仓库

### 查看远程仓库中的包

在使用 Conan 进行开发时，我们时常需要查看远程仓库中有哪些包可用，特别是当我们需要某个特定版本的库或不同平台支持的包时。

Conan 提供了几个实用的命令来帮助我们查询远程仓库中的包信息，主要包括：

- 查询包的可用版本
- 查看包的详细信息
- 查询某个包在远程仓库中的状态

当我们想要查找某个库的可用版本时，`conan search`命令是非常有用的工具。这个命令不仅可以在本地查询包信息，还可以在远程仓库中进行搜索

```bash
conan search <package_name> -r <remote_name>
```

假设我们想要查看远程仓库`conan-center`中的`fmt`库的所有可用版本，命令如下：

```bash
conan search fmt -r conancenter
```

在确定要使用的库版本后，我们可能需要进一步查看该包的详细信息。Conan 允许我们查询库的配置信息，包括编译选项、平台支持等

为了查看某个包的详细信息，仍然使用`conan search`命令，但要加上包的完整配方信息（包括版本和可选的选项）

```bash
conan search <package_name>/<version>@<user>/<channel> -r <remote_name>
```

假设我们想要查看`fmt/8.0.1`版本包在远程仓库`conan-center`中的详细信息：

```bash
conan search fmt/8.0.1 -r conancenter
```

这个命令输出的信息包括包的选项（如是否为共享库）、支持的架构、编译器版本等。通过这些信息，我们可以确定该包是否满足项目的需求

除了查看远程仓库中的包，我们还可以查询包的状态。通过Conan，能够查看本地和远程仓库中包的同步状态，确保包的版本和配置是否匹配。

使用`conan info`命令可以深入了解包的依赖关系和构建细节

```bash
conan info <package_name>/<version>@<user>/<channel> -r <remote_name>
```

假设我们想要查询`fmt/8.0.1`包在`conan-center`中的状态，命令如下：

```bash
conan info fmt/8.0.1@ -r conan-center
```

通过这种方式，我们可以清楚地了解到包的来源、许可证信息、依赖关系等

除了命令行工具，Conan 还提供了一些可视化的图形工具，帮助开发者更直观地管理包和依赖。`conan info --graph`命令允许我们生成包的依赖关系图，进一步帮助理解项目中的依赖结构

```bash
conan info <package_name>/<version> --graph=file.html
```

这个命令会将依赖关系图导出为HTML文件，方便在浏览器中查看

### 指定远程仓库及管理项目依赖的下载

只想下载某个依赖包而不需要立即安装它。这在需要提前缓存某些包或构建流程中需要避免延迟下载时非常有用。Conan提供了`conan download`命令来执行这个操作。

```bash
conan download <package_reference> -r <remote_name>
```

Conan 会将下载的包缓存到本地，以便在后续构建中加速使用。这种缓存机制可以提高项目的构建速度，但随着时间推移，缓存可能会占用大量磁盘空间。因此，定期管理和清理本地缓存是必要的

可以使用以下命令查看本地缓存中的包信息：

```bash
conan search
```

这将列出所有已经缓存到本地的包，包括它们的版本和构建配置

如果我们需要清理某些包的缓存，可以使用`conan remove`命令来删除它们：

```bash
conan remove <package_reference>
```

在某些情况下，我们可能希望 Conan 在特定情况下跳过或强制重新下载某些包。Conan 提供了不同的下载策略来控制依赖包的下载行为：

- `--update`：如果远程仓库中存在更新版本，强制下载最新版本。
- `--no-download`：跳过依赖包的下载，仅使用本地已有的缓存。

可以通过以下命令强制更新项目的所有依赖：

```bash
conan install . --update
```

如果我们希望只使用本地缓存中的包而不进行远程下载，可以使用以下命令：

```bash
conan install . --no-download
```

这对于离线构建或网络环境不佳的情况下非常有用

## 参考资料

- <http://chu-studio.com/posts/2019/%E4%BB%8E%E9%9B%B6%E5%BC%80%E5%A7%8B%E7%9A%84C++%E5%8C%85%E7%AE%A1%E7%90%86%E5%99%A8CONAN%E4%B8%8A%E6%89%8B%E6%8C%87%E5%8D%97>

- <https://openatomworkshop.csdn.net/6745992f3a01316874d8dc6c.html>
