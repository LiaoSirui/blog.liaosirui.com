安装

```bash
dnf install -y cachefilesd
```

默认配置文件在`/etc/cachefilesd.conf`，其中第一行是 SSD 缓存的位置

```bash
dir /var/cache/fscache
tag mycache
brun 10%
bcull 7%
bstop 3%
frun 10%
fcull 7%
fstop 3%
```

分两组： 

- `b*`：按  磁盘块 / block 空间
- `f*`：按  inode / 文件节点数量

含义大致是： 

- `brun` /  `frun`：高于这个剩余值时，正常运行 
- `bcull` /  `fcull`：低于这个值时，开始回收旧缓存 
- `bstop` /  `fstop`：低于这个值时，停止分配新缓存

实例配置

```
dir /mnt/fscache
tag fscache
brun 20%
bcull 18%
bstop 15%
frun 20%
fcull 18%
fstop 15%
```

NFS 添加 fsc 参数

```bash
nfs _netdev,fsc 0 0
```

查看 FScache 状态，查看是否 FSC 参数为 yes，是的话就说明开启成功

```bash
cat /proc/fs/nfsfs/volumes
```

