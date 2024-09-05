官方：

- GitHub 仓库：<https://github.com/docker/buildx>
- 文档：<https://docs.docker.com/engine/reference/commandline/buildx/>

二进制安装

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}

mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-amd64 -o $DOCKER_CONFIG/cli-plugins/docker-buildx

chmod +x $DOCKER_CONFIG/cli-plugins/docker-buildx
```

