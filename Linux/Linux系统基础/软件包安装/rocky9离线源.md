挂载光盘

```bash
mount -o loop /root/Rocky-9.0-20220808.0-x86_64-dvd.iso /rocky
```

新建 repo 文件

```bash
vim /etc/yum.repos.d/rocky-local.repo
```

内容如下：

```bash
[baseos]
name=Rocky Linux $releasever - BaseOS
baseurl=file:///rocky/BaseOS/
gpgcheck=0
enabled=1

[appstream]
name=Rocky Linux $releasever - AppStream
baseurl=file:///rocky/AppStream/
gpgcheck=0
enabled=1
```

刷新缓存

```bash
dnf makecache --refresh
```

