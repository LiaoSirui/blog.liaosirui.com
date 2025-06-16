## Jsonnet 简介

Jsonnet 是 Google 推出的一门 JSON 模板语言. 它的基本思想是在 JSON 的基础上扩展语法, 将 JSON 的部分字段用代码来表达, 并在运行期生成这些字段

语法文档详见：<https://jsonnet.org/learning/tutorial.html>

安装 go-jsonnet <https://github.com/google/go-jsonnet>

```bash
go install github.com/google/go-jsonnet/cmd/jsonnet@latest

go install github.com/google/go-jsonnet/cmd/jsonnet-lint@latest
```

## Jsonnet 包管理器

Jsonnet 包管理器（Jsonnet-bundler，简称 jb）是一个用于 Jsonnet 的包管理工具。Jsonnet 是一种配置语言，旨在简化 JSON 的生成和维护。jb 允许开发者轻松地管理和安装 Jsonnet 包，支持依赖的递归获取和子树的版本控制。

安装 json-bundler <https://github.com/jsonnet-bundler/jsonnet-bundler/>

```bash
go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest

# dnf install golang-github-jsonnet-bundler
```

## Jsonnet 项目

创建一个新的项目目录并初始化：

```bash
cd project_dir
jb init
```

这将生成一个`jsonnetfile.json`文件，表示项目现在是一个 Jsonnet 包

假设想依赖一个名为`kustomize-libsonnet`的包，可以使用以下命令安装：

```bash
jb install https://github.com/anguslees/kustomize-libsonnet
```

安装完成后，依赖包将被放置在`vendor`目录中

在 Jsonnet 配置文件中，可以导入并使用安装的依赖包：

```jsonnet
local kustomize = import 'kustomize-libsonnet/kustomize.libsonnet';

local my_resource = {
  metadata: {
    name: 'my-resource',
  },
};

kustomize.namePrefix('staging-')(my_resource)

```

运行 Jsonnet 时，使用`-J vendor`选项来包含`vendor`目录：

```bash
jsonnet -J vendor myconfig.jsonnet
```

## 其他

虽然 Jsonnet 本身是图灵完备的, 但它本身是专门为了生成 JSON 设计的模板语言, 因此使用场景主要集中在配置管理上。社区的实践主要是用 jsonnet 做 Kubernetes, Prometheus, Grafana 的配置管理

Jsonnet 包管理器与以下项目紧密结合，形成了一个强大的生态系统：

- Kubernetes：Jsonnet 广泛用于 Kubernetes 的配置管理，jb 帮助开发者管理复杂的 Kubernetes 配置依赖
  - kubecfg: 使用 jsonnet 生成 kubernetes API 对象并 apply
  - ksonnet-lib: 一个 jsonnet 的库, 用于生成 kubernetes API 对象
  - Tanka：Tanka 是一个基于 Jsonnet 的 Kubernetes 配置管理工具，jb 是其依赖管理的核心组件
- Prometheus：Prometheus 的配置文件也可以使用 Jsonnet 生成，jb 帮助管理 Prometheus 配置的依赖
  - kube-prometheus: 使用 jsonnet 生成 Prometheus-Operator, Prometheus, Grafana 以及一系列监控组件的配置
- Grafana
  - grafonnet-lib: 一个 jsonnet 的库, 用于生成 json 格式的 Grafana 看板配置
  - Grafonnet