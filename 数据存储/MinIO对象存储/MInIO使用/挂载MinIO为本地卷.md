## s3fs 方式步骤

安装 s3fs 客户端

```bash
dnf install -y s3fs-fuse
```

设置认证

```bash
echo 'admin:password' > $HOME/.passwd-s3fs && chmod 600 $HOME/.passwd-s3fs
# echo [IAM用户访问密钥ID]:[ IAM用户访问密钥] >[密钥文件名]
```

注：特殊字符需要进行 URL 转义

挂载

```bash
s3fs \
-o passwd_file=$HOME/.passwd-s3fs \
-o url=http://192.168.0.20:9000 \
-o allow_other \
-o nonempty \
-o no_check_certificate \
-o use_path_request_style \
-o umask=000 bucket1 /mnt/minio
```

**OPTIONS:**

- `passwd_file`: 指定要使用的 s3fs 密码文件
- `url`: 设置用于访问对象存储的 url
- `endpoint`: 存储端点，默认值为`us-east-1`
- `umask`: 为装载目录设置umask
- `no_check_certificate`: 不检查认证
- `use_path_request_style`: 使用路径请求样式(使用传统API调用)，兼容支持与不支持S3的类似api的虚拟主机请求
- `nonempty`: 允许挂载点为非空目录
- `default_acl`: 默认 private，取值有 private，public-read
- `ensure_diskfree`: 设置磁盘可用空间。如果磁盘空闲空间小于此值，s3fs不适用磁盘空间
- `allow_other`: 允许所有用户访问挂载点目录，可将该挂载点用于创建NFS共享
- `use_cache`: 指定本地文件夹用作本地文件缓存。默认为空
- `del_cache`: 在S3FS启动和退出时删除本地缓存
- `enable_noobj_cache`: 减少 s3fs 发送的列举桶的请求，从而提升性能
- `dbglevel`: 设置消息级别，默认`关键（critical）`, 可以使用 `info` 进行调试输出
- `multireq_max`: 列出对象的并行请求的最大数据
- `parallel_count`: 上传大对象的并行请求数
- `retries`: 默认值为5，传输失败重试次数
- `storage_class`: 存储类（默认为`标准`) ，值有 `standard`，`standard_ia` , `onezone_ia` , `reduced_redundancy`
- `connect_timeout`: 连接超时时间，默认为 300 秒
- `readwrite_timeout`: 读写超时，默认值为 60 秒
- `max_stat_cache_size`: 最大静态缓存大小，默认值为 100000 个条目(约40MB)
- `stat_cache_expire`: 为 stat 缓存中条目指定过期时间(秒)。此过期时间表示自 stat 缓存后时间
- `-f` : 前台输出执行信息
- `-d`: 将 dubug 消息输出到 syslog 中

查看挂载情况：

```bash
df -h
```

取消挂载

```bash
fusermount -u /mnt/minio
```

## goofys 方式

- <https://github.com/kahing/goofys>

创建用户凭证

```bash
mkdir -p $HOME/.aws
cat >> $HOME/.aws/credentials << EOF
[default]
aws_access_key_id = zhangsan
aws_secret_access_key = zhangsan
EOF
```

挂载

```bash
endpoint是minio服务端地址
# bk1是bucket名
# /home/minio是本地目录
# 将goofys放到/usr/local/bin目录下之后就可以直接调用了，不需要再写路径
./goofys --endpoint=http://192.168.137.8:9090 bk1 /home/minio/
```

