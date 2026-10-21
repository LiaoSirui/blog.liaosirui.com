```bash
go install github.com/google/ko@latest
```

Google Ko（或简称为 ko），它是一款由 Google 开源的、专为 Go 语言（Golang）应用程序设计的快速容器镜像构建与部署工具。

`Ko` 通过 环境变量 `KO_DOCKER_REPO` 配置私有仓库的地址, 这决定了 `Ko` 会将编译好的镜像推到哪个仓库

```bash
export KO_DOCKER_REPO=harbor.alpha-quant.tech/test
```

