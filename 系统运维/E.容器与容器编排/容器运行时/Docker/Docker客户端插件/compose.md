官方：

- GitHub 仓库：<https://github.com/docker/compose>
- 文档：<https://docs.docker.com/compose/>

安装 compose

```bash
dnf install docker-compose-plugin
```

二进制安装

```bash
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}

mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
```

