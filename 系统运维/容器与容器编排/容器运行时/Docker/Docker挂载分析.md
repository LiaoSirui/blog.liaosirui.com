docker 本身交给 containerd 处理挂载，因此需要追踪 containerd 进程

```bash
# pstree -p |grep containerd |grep -v shim
           |-containerd(1449)-+-{containerd}(1452)
           |                  |-{containerd}(1455)
```

抓取 strace 日志并记录到文件中

```bash
strace -e trace=mount -f -p 1449 > ./strace.log 2>&1
```

运行容器如下：

```bash
docker run -it --rm -v $PWD/anaconda-ks.cfg:/anaconda-ks.cfg nginx
```

查看抓取的日志

```bash
# cat strace.log|grep ana
[pid 11076] mount("/root/anaconda-ks.cfg", "/proc/self/fd/7", 0xc000212490, MS_BIND|MS_REC, NULL) = 0

# 挂载文件 mount 参数为 MS_BIND|MS_REC

# cat strace.log|grep '"/"'
[pid 11076] mount("", "/", 0xc0001d5ecc, MS_REC|MS_SLAVE, NULL) = 0

# 挂载容器根目录为 MS_REC|MS_SLAVE
```

参考文档：

- <https://man7.org/linux/man-pages/man2/mount.2.html>

- <https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt>

- <https://cloud.tencent.com/developer/article/1532014>