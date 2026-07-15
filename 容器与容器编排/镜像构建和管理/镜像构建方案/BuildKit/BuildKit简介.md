## BuildKit 简介

BuildKit 是下一代的镜像构建组件，在 <https://github.com/moby/buildkit> 开源

Docker 版本低于 18.09，BuildKit 无法使用，将造成镜像构建失败

官方：

- 官方文档：<https://github.com/moby/buildkit/tree/master/docs>
- GitHub 仓库：<https://github.com/moby/buildkit>

## BuildKit 部署

官方：

- 二进制部署：<https://github.com/moby/buildkit/tree/master/examples/systemd>

- Kubernetes 部署：<https://github.com/moby/buildkit.git>

配置文件参考文档：<https://github.com/moby/buildkit/blob/master/docs/buildkitd.toml.md>

## 构建镜像

### Docker 构建镜像

docker 直接使用 BuildKit 引擎可以设置环境变量：

```bash
DOCKER_BUILDKIT=1
```

### Docker buildx 构建镜像

可以直接使用 `docker buildx build` 命令构建镜像

Buildx 使用 BuildKit 引擎 进行构建，支持许多新的功能

官方文档：

- https://github.com/docker/buildx/releases

- https://docs.docker.com/build/install-buildx/

- https://docs.docker.com/engine/reference/commandline/buildx/

安装 buildx 插件

```bash
mkdir ~/.docker/cli-plugins

export INST_BUILDX_VER=v0.11.0
# export BUILDX_ARCH=arm64
export INST_BUILDX_ARCH=amd64

curl -sL https://github.com/docker/buildx/releases/download/${INST_BUILDX_VER}/buildx-${INST_BUILDX_VER}.linux-${INST_BUILDX_ARCH} -o ~/.docker/cli-plugins/docker-buildx

chmod +x ~/.docker/cli-plugins/docker-buildx
```

在 dockerfile 中安装

```dockerfile
# syntax=docker/dockerfile:1
FROM docker

COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

RUN docker buildx version
```


### Docker Compose 使用 buildkit 构建镜像

docker-compose build 使用 Buildkit

设置

```bash
COMPOSE_DOCKER_CLI_BUILD=1
```

环境变量即可使用

### nerdctl 使用 buildx 构建镜像

