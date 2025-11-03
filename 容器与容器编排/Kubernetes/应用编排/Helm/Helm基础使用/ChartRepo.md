chart repo 库是容纳一个或多个封装的 chart 的 HTTP 服务器。虽然 helm 可用于管理本地 chart 目录，但在共享 chart 时，首选机制是 chart repo 库

任何可以提供 YAML 文件和 tar 文件并可以回答 GET 请求的 HTTP 服务器都可以用作 repo 库服务器

Helm 附带用于开发人员测试的内置服务器（`helm serve`）。Helm 团队测试了其他服务器，包括启用了网站模式的 Google Cloud Storage 以及启用了网站模式的 S3

repo 库的主要特征是存在一个名为的特殊文件 index.yaml，它具有 repo 库提供的所有软件包的列表以及允许检索和验证这些软件包的元数据

在客户端，repo 库使用 helm repo 命令进行管理。但是，Helm 不提供将 chart 上传到远程存储服务器的工具。这是因为这样做会增加部署服务器的需求，从而增加配置 repo 库的难度

## OCI 存储支持

Helm 3 支持 OCI 用于包分发。 Chart包可以通过基于OCI的注册中心存储和分发。

```bash
# helm version <= v3.8.0
export HELM_EXPERIMENTAL_OCI=1
```

运行一个 registry 来测试

```bash
docker run -dp 5000:5000 --restart=always --name registry registry
```

### 用于处理 registry 的命令

- registry 子命令

login 登录到注册中心 (手动输入密码)

```bash
helm registry login --insecure -u admin localhost:5000
# 因为没有设置密码，随意输入即可
# --insecure 是因为使用 http
```

logout 从注册中心注销

```bash
helm registry logout localhost:5000
```

- push 子命令

```bash
helm push chart-demo-0.1.0.tgz oci://localhost:5000/helm-charts

helm push chart-common-1.0.0.tgz oci://localhost:5000/helm-charts
```

push 子命令只能用于 `helm package` 提前创建的 `.tgz` 文件

使用 `helm push` 上传 chart 到 OCI 注册表时，引用必须以 `oci://` 开头，且不能包含基础名称或 tag

- 其他命令

对 `oci://` 协议的支持同样适用于很多其他子命令。以下是完整列表：

- helm pull
- helm show
- helm template
- helm install
- helm upgrade
