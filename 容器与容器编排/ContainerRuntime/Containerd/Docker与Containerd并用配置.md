
## 配置

事实上，Docker 和 Containerd 是可以同时使用的，只不过 Docker 默认使用的 Containerd 的命名空间不是 default，而是 moby

将 Docker 与 Containerd 联合使用。

在完成 containerd 的安装配置并启动后，可以在宿主机中安装 docker 客户端及服务。

编辑 `/usr/lib/systemd/system/docker.service` 文件并为其新增 `--containerd` 如下启动项：`--containerd /run/containerd/containerd.sock`

```plain
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
```

## 对比运行容器

打开两个 Shell 终端，一个采用 docker 运行一个 busybox 容器，另外一个查看对比

```bash
docker run --rm -it busybox sh
```

采用 ctr 在 moby 名称空间下查看 docker 创建的容器以及 Task PID

```bash
ctr -n moby c ls
```

结果：

```plain
[root@devmaster ~]# ctr -n moby c ls
CONTAINER                                                           IMAGE    RUNTIME
dcbc8b927eebcfcfbcf52c7b4ca662b4c294d9c84853a1e3de0bc6cfe6180e47    -        io.containerd.runc.v2
```

查看容器：

```bash
ctr -n moby t ls
```

结果：

```plain
[root@devmaster ~]# ctr -n moby t ls
TASK                                                                PID      STATUS
dcbc8b927eebcfcfbcf52c7b4ca662b4c294d9c84853a1e3de0bc6cfe6180e47    14384    RUNNING
```

验证获取到的 Task PID 下其 net 相关信息

```bash
grep "172.17.0.2" /proc/14384/net/fib_trie
```

得到输出

```plain
[root@devmaster ~]# grep "172.17.0.2" /proc/14384/net/fib_trie
           |-- 172.17.0.2
           |-- 172.17.0.2
```

采用 ctr 进入 Docker 创建的容器

```plain
ctr -n moby t exec -t --exec-id $RANDOM dcbc8b927eebcfcfbcf52c7b4ca662b4c294d9c84853a1e3de0bc6cfe6180e47 sh
```

查看网卡：

```plain
/ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
9: eth0@if10: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```
