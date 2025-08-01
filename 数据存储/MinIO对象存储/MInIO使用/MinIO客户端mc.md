## mc 简介

- MinIO Client mc 命令行工具为 UNIX 命令（如 ls、cat、cp、mirror 和）提供了一种现代替代方案，并 diff 支持文件系统和兼容 Amazon S3 的云存储服务。
- mc 命令行工具是为与 AWS S3 API 兼容而构建的，并针对预期的功能和行为测试了 MinIO 和 AWS S3。
- MinIO 不为其他与 S3 兼容的服务提供任何保证，因为它们的 S3 API 实现是未知的，因此不受支持。虽然 mc 命令可以按文档说明工作，但任何此类使用都需要您自担风险

## 下载

```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc \
	&& chmod +x /usr/local/bin/mc

mc --help
```

## 使用

官方文档：

- 英文
  - MinIO Client <https://min.io/docs/minio/linux/reference/minio-mc.html?ref=docs>
  - MinIO Admin Client <https://min.io/docs/minio/linux/reference/minio-mc-admin.html?ref=docs>

- 中文
  - MinIO 客户端快速入门指南 <http://docs.minio.org.cn/docs/master/minio-client-quickstart-guide>
  - MinIO Client 完全指南 <http://docs.minio.org.cn/docs/master/minio-admin-complete-guide>
  - MinIO 管理员完整指南 <http://docs.minio.org.cn/docs/master/minio-client-complete-guide>

### 添加 MinIO 存储服务

MinIO 服务器显示 URL，访问权和秘密密钥

用法：

```bash
mc config host add <ALIAS> <YOUR-MINIO-ENDPOINT> [YOUR-ACCESS-KEY] [YOUR-SECRET-KEY]
```

示例：

```bash
# 明文输入
mc config host add minio http://local-168-182-110:19000 admin admin123456

# 密文输入（推荐）
mc config host add minio http://local-168-182-110:19000
Enter Access Key: admin
Enter Secret Key: admin123456
```

### 获取服务端信息

```bash
# 获取已配置别名 "minio" 的 MinIO 服务器信息
mc admin info minio

# 添加 Shell 别名以获取信息，以便恢复
alias minfo='/usr/local/bin/mc admin info'
alias mheal='/usr/local/bin/mc admin heal'
```

### shell 别名和补全

官方：<https://github.com/minio/mc#shell-aliases>

```bash
alias ls='mc ls'
alias cp='mc cp'
alias cat='mc cat'
alias mkdir='mc mb'
alias pipe='mc pipe'
alias find='mc find'
```

增加自动补全，<https://github.com/minio/mc#shell-autocompletion>

```bash
mc --autocompletion
```

## 桶的基本命令

创建 buk2 的桶

```bash
mc mb minio/buk2
```

上传当前目录所有文件到 buk2 桶上

```bash
mc cp -r * minio/buk2
```

查找 buk2 存储桶中 html 结尾文件

```bash
mc find minio/buk2 --name "*.html"
```

设置 buk2 只读权限 download

共可以设置四种权限：

- none
- download 只读
- upload 只写
- public

```bash
mc anonymous set download minio/buk2
```

查看 buk2 存储桶权限

```bash
mc anonymous list minio/buk2
```

共享 buk2 下 baidu.html 文件下载路径

```bash
mc share download minio/buk2/baidu.html
```

查看存储桶

```bash
mc ls minio
```

查看 buk2 存储桶文件

```bash
mc ls minio/buk2
```

设置桶策略为 public 模式，这样 MinIO 可以提供永久文件服务

```bash
mc anonymous set public minio/buk2
```



