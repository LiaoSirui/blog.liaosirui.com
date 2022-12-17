
Docker 的镜像（image）、容器（container）、数据卷（volume），都是由 daemon 托管的。

## 清理容器

### 清理所有停止运行的容器

```bash
docker container prune
```

或者

```bash
docker rm $(docker ps -a --filter 'exited=0')
```

### 清理单个容器

```bash
docker rm -lv CONTAINER
```

-l 是清理 link，-v 是清理 volume。

这里的 CONTAINER 是容器的 name 或 ID，可以是一个或多个。

### 按需批量清理容器

清除所有已停止的容器，是比较常用的清理。 但有时会需要做一些特殊过滤。

这时就需要使用 docker ps --filter。

比如，显示所有返回值为 0，即正常退出的容器：

```bash
docker ps -a --filter 'exited=0'
```

在需要清理所有已停止的容器时，通常利用 shell 的特性，组合一下就好。

```bash
docker rm $(docker ps -a --filter 'exited=0')
```

## 清理卷

数据卷不如容器或镜像那样显眼，但占的硬盘却可大可小。

数据卷的相关命令，都在 docker volume 中了。

一般用 `docker volume ls` 来查看，用 `docker volume rm VOLUME` 来删除一个或多个。

不过，绝大多数情况下，不需要执行这两个命令的组合。 直接执行 docker volume prune 就好，即可删除所有无用卷。

```bash
docker volume prune
```

注意：这是一个危险操作！一般真正有价值的运行数据，都在数据卷中。（当然也可能挂载到了容器外的文件系统里，那就没关系。）如果在关键服务停止期间，执行这个操作，很可能会丢失所有数据！

## 清理镜像

### 清理所有悬挂镜像

```bash
docker image prune
```

或者

```bash
docker rmi $(docker images -qf "dangling=true")
```

### 按需批量清理镜像

与 ps 类似，images 也支持 `--filter` 参数。

```bash
docker images --filter "dangling=true"
```

与清理相关，最常用的，当属 `<none>` 了。这条命令，可以列出所有悬挂（dangling）的镜像，也就是显示为 `<none>` 的那些。

```bash
docker rmi $(docker images -qf "dangling=true")
```

### 清理所有无用镜像

```bash
docker image prune -a
```

这招要慎用，否则需要重新下载。
