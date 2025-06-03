## BorgBackup 简介

BorgBackup（或简称为 Borg）是一个开源的、去重的、压缩的、加密的备份程序。它提供了高效、安全的方式来备份数据

BorgBackup 的主要优势（总结自官方文档）：

- 高效存储
- 加密
- 支持多种压缩算法
  - LZ4 快，低压缩
  - ZSTD 高速低压缩、低速高压缩
  - ZLIB 中等速度，中等压缩
  - LZMA 低速 高压缩
- 远程备份，数据可以通过 SSH 备份到远程机器
- FUSE
- 跨平台
- 开源

官方：

- 官方文档：<https://borgbackup.readthedocs.io/en/1.2.7/>

- 安装指南：<https://borgbackup.readthedocs.io/en/stable/installation.html>

## 使用指南

### 命令概述

```bash
borg init -- 初始化一个仓库
borg create -- 创建一个archive到仓库中
borg list -- 列出所有的仓库或者某个仓库中某个archive的内容
borg extract -- 还原某个archive
borg delete -- 手动删除某个archive
borg config -- 获取或者设置某个配置
```

### 创建 Repo

开始创建备份前，需要创建一个 repo，通常来说，一个 repo 应该备份一些固定的一些目录，borg 的去重功能是在同一个 repo 中进行的

```bash
borg init --encryption=none --make-parent-dirs /mnt/backup/borg-repo-01
```

一个 repo 的结构示例如下，它是二进制形式保存的：

```bash
# tree .
.
├── config
├── data
│   └── 0
│       ├── 0
│       └── 1
├── hints.1
├── index.1
├── integrity.1
└── README
```

在 create 的时候可以选择使用压缩算法：

```
borg create --compress zstd,1 --encryption=none --make-parent-dirs /mnt/backup/borg-repo-01
```

如果不指定压缩算法，默认会使用 LZ4，速度快，压缩比率低

### 创建备份

接下来在 borg-repo-01 中创建备份

```bash
export INST_BORG_REPO=/mnt/backup/borg-repo-01

# 多个需要备份的文件夹可或者文件只需要添加为参数即可
borg create --stats --progress ${INST_BORG_REPO}::$(date "+%Y-%m-%d-%H%M%S") \
  /etc \
  /root
```

`borg create` 是创建备份的命令，其中 `--stats --progress` 代表在备份进行和完成后显示信息

borg 会根据 repo 中已有数据对本次备份进行去重，因此某个 repo 只有首次往其中备份时，备份的用时会较长和占用较大空间

### 历史备份管理

查看备份列表

```bash
export INST_BORG_REPO=/mnt/backup/borg-repo-01

borg list ${INST_BORG_REPO}
```

每条显示有备份的名称，时间，哈希值

使用 `info` 获取存档信息：

```bash
borg info ${INST_BORG_REPO}::2025-06-03-150129
```

### 恢复备份的文件

打开一个目录（注意不要是被 borg 备份的目录）

```bash
export INST_BORG_REPO=/mnt/backup/borg-repo-01
export INST_BORG_RESTORE=/mnt/backup/borg-restore-01

mkdir -p ${INST_BORG_RESTORE}
cd ${INST_BORG_RESTORE}
borg extract --progress ${INST_BORG_REPO}::2025-06-03-150129
```

### 删除备份

删除整个 repo

```bash
export INST_BORG_REPO=/mnt/backup/borg-repo-01

borg delete ${INST_BORG_REPO}
```

删除某次备份

```bash
borg delete ${INST_BORG_REPO}::2025-06-03-150129
```

因为有去重机制，删除某次备份并不能很好的腾出空间占用

### 快捷操作

```bash
export INST_BORG_REPO=/mnt/backup/borg-repo-01

alias borggo='/opt/borgdobackup.sh'
alias borglist='borg list $INST_BORG_REPO'
```

## 备份加密

初始化 repository 的时候，可以指定加密类型：

- none 不加密
- repokey 或 keyfile 的时候，使用 AES-CTR-256 加密

BorgBackup 的加密两种模式

- repokey：把 key 存储在 repo 目录里，用 passphrase 加密起来，而 passphrase 由人记忆
- keyfile：把 key 存储在 repo 外面

如果对备份宿主的掌控力不足，可以考虑使用后者，当然，后者的风险就是这个 keyfile 本身也需要备份

## 压缩存储

BorgBackup 也支持对 repo 进行压缩后存储。如果数据大部分都是可压缩的类型，开启一个快速的 LZ4 压缩能节省不少空间；如果数据都是照片、视频等不可压缩类型，压缩就没什么必要。1.1.x 分支的 BorgBackup 提供了 `-C auto,lz4` 这样的选项，可以自动判断数据是否属于可压缩类型

## 通过 ssh 备份到远程设备

BorgBackup 原生支持基于 SSH 的远端 repo，其格式和 Git / rsync 有几分相似：`username@hostname:/path/to/repo::archive-1`。以上命令中的所有本地 repo 都可以直接换成远端 repo 写法。这样的远端 repo 是通过 SSH 访问的，所以安全性和 SSH 是一样的。使用远端 repo 需要远端机器上已经装有 BorgBackup，正如使用 rsync 需要远端机器上已经装有 rsync 一样

如果不方便在远端机器上安装 BorgBackup，可以使用 NFS / SSHFS / Samba 等各种网络文件系统把远端机器的磁盘映射到本地，然后用本地 repo 的方式访问，达到异地备份的效果

```bash
#!/bin/bash
# 启动 ssh-agent
eval "$(ssh-agent -s)"

# 添加你的私钥到 ssh-agent
ssh-add /root/.ssh/id_rsa

# 定义备份源和目标
SOURCE="/A/path/to/repo"
TARGET="backupuser@domain.com:/path/to/repo"

# 设置 BORG_PASSPHRASE 环境变量，Borg 将使用这个变量作为密码
export BORG_PASSPHRASE='xxxxxxxxxxx'

# 使用 Borg 创建新的备份，exclude 排除文件夹
borg create --exclude '/A/excludePath' "${TARGET}::{now:%Y%m%d%H%M%S}" "${SOURCE}"

# 删除 30 天前的备份，防止空间不足
borg prune -v --list --keep-within 30d "${TARGET}"
```

## 备份设置排除某个备份目录

## 自动留存

BorgBackup 提供了自动留存算法。通过 `borg prune` 命令，BorgBackup 可以按照特定的规则自动移除旧的 archive。比如对于一个每天备份的 repo 可以设置这样的 prune 规则：

- 近一周内，留存每天的备份；
- 近一个月内，每周至少留一份备份；
- 近半年内，每月至少留一份备份；
- 近十年内，每年至少留一份备份。

这样既可以达到最大留存时间，又相对节省备份空间

## 提取备份文档并打包

```bash
borg extract --strip-components 3 /path/to/repo::my-backup
```

在 borg extract 命令中，`--strip-components` 选项用于移除从备份中提取的文件路径的前缀部分。这个选项的参数是你想要移除的路径组件的数量

然后可以通过指令压缩成文件

```bash
zip -r backup.zip .
```

## borgmatic

BorgBackup 是没有配置文件的，所有配置项都是在运行的时候通过命令行参数或是环境变量来改变

第三方项目 Borgmatic。它通过 YAML 配置文件声明 BorgBackup 备份设置，然后拼装好 BorgBackup 命令来运行，并且它有完善的错误处理和钩子机制，方便发送备份成功的通知或备份失败的报警

- <https://github.com/borgmatic-collective/borgmatic>
