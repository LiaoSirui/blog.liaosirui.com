有时候经常会有个别容器占用磁盘空间特别大, 这个时候就需要通过docker overlay2目录名查找对应容器名

先进入overlay2的目录，这个目录可以通过docker的配置文件（/etc/docker/daemon.json）内找到。然后看看谁占用空间比较多。

首先进入到 `/var/lib/docker/overlay2` 目录下,查看谁占用的较多

```bash
cd /var/lib/docker/overlay2
du -sc * | sort -rn  | more
```

找到占用磁盘最大的目录然后查找容器

```bash
docker ps -q | xargs docker inspect --format '{{.State.Pid}}, {{.Id}}, {{.Name}}, {{.GraphDriver.Data.WorkDir}}' | grep "199039c8dea34de4b826ef74043fc85703db7d3139dd2fc63f2af6b539b370f6"
```

可以看到容器 id 和镜像名称
