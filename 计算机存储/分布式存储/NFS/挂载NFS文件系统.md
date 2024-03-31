挂载文件系统时，可选择多种挂载选项，挂载选项使用半角逗号（,）分隔，说明如下：

- rsize：定义数据块的大小，用于客户端与文件系统之间读取数据。建议值：1048576。
- wsize：定义数据块的大小，用于客户端与文件系统之间写入数据。建议值：1048576。
- hard：在文件存储 NAS 暂时不可用的情况下，使用文件系统上某个文件的本地应用程序时会停止并等待至该文件系统恢复在线状态。建议启用该参数。
- timeo：指定时长，单位为 0.1 秒，即NFS客户端在重试向文件系统发送请求之前等待响应的时间。建议值：600（60秒）。
- retrans：NFS 客户端重试请求的次数。建议值：2。
- noresvport：在网络重连时使用新的 TCP 端口，保障在网络发生故障恢复时不会中断连接。建议启用该参数。

推荐通过 NFS v3 协议挂载文件系统，以获得最佳访问性能

```bash
mount -t nfs \
 -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  10.244.244.201:/ /mnt
```

使用 NFS v4 协议挂载文件系统：

```bash
mount -t nfs \
 -o vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  10.244.244.201:/ /mnt
```

```bash
mount -t nfs \
 -o vers=3,nolock,noacl,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  10.244.244.201:/ /mnt
```

参考文档

- <https://help.aliyun.com/zh/nas/user-guide/mount-an-nfs-file-system-on-a-linux-ecs-instance>
