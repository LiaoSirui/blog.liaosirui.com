## 简介

`bcache` 是一个 Linux 内核块层超速缓存。它允许使用一个或多个高速磁盘驱动器（例如 SSD）作为一个或多个速度低得多的硬盘的超速缓存。`bcache` 支持直写和写回，不受所用文件系统的约束。默认情况下，它只超速缓存随机读取和写入，这也是 SSD 的强项。它还适合用于台式机、服务器和高端储存阵列。

Bcache 是 Linux 内核块设备层 cache，支持多块 HDD 使用同一块 SSD 作为缓存盘。它让 SSD 作为 HDD 的缓存成为了可能。由于 SSD 价格昂贵，存储空间小，而 HDD 价格低廉，存储空间大，因此采用 SSD 作为缓存，HDD 作为数据存储盘，既解决了 SSD 容量太小，又解决了 HDD 运行速度太慢的问题。

- 文档：<https://docs.kernel.org/admin-guide/bcache.html>

主要功能

- 可以使用单个超速缓存设备来超速缓存任意数量的后备设备。在运行时可以挂接和分离已装入及使用中的后备设备
- 在非正常关机后恢复 - 只有在超速缓存与后备设备一致后才完成写入
- SSD 拥塞时限制传至 SSD 的流量
- 高效的写回实施方案。脏数据始终按排序顺序写出
- 稳定可靠，可在生产环境中使用

## Bcache 缓存策略

Bcache 支持三种缓存策略，分别是：writeback、writethrough、writearoud，默认使用 writethrough，缓存策略可动态修改。

- writeback 回写策略：回写策略默认是关闭的，如果开启此策略，则所有的数据将先写入缓存盘，然后等待系统将数据回写入后端数据盘中。
- writethrough 写通策略：默认的就是写通策略，此模式下，数据将会同时写入缓存盘和后端数据盘。
- writearoud ：选择此策略，数据将直接写入后端磁盘。

## 编译安装

查看内核中有没有编入 Bcache 模块，默认内核并没有将 Bcache 编译进内。检查内核中有没有 Bcache 模块的的方式有两种：

- 检查 `/sys/fs/bcache/` 目录是否存在，没有则说明内核中没有 bcache
- 检查 `/lib/modules/<$version>/kernel/drivers/md/bcache/` 目录是否存在，如果存在则可以运行 `modprobe bcache` 命令来加载 bcache 模块，不存在则说明内核中没有 bcache。

进入内核源码位置，依次：选择 Device Drivers -> 选择 Multiple devices driver support（RAID and LVM）-> 移动到 Block device as cache 选项，按 Y 键将该功能编译进内核

安装依赖 libblkid-devel 包

```bash
dnf install -y libblkid-devel
```

进入模块目录

```bash
ls -alh /lib/modules/$(uname -r)/build/drivers/md/bcache
make -C /lib/modules/$(uname -r)/build M=$(pwd)

# /lib/modules/$(uname -r)/kernel/drivers/md/bcache
```

下载链接：<https://git.kernel.org/pub/scm/linux/kernel/git/colyli/bcache-tools.git/snapshot/bcache-tools-1.1.tar.gz>

## 设置 `bcache` 设备

使用磁盘作为 Bcache 磁盘前，请先确保磁盘是空的，或者磁盘中的数据无关紧要。如果磁盘中有文件系统，将会出现如下错误：

```bash
# make-bcache -C /dev/sdc
Device /dev/sdc already has a non-bcache superblock, remove it using wipefs and wipefs -a
```

需要使用 wipefs 命令，擦除磁盘中的超级块中的数据，这将使得原磁盘中的数据无法继续使用，也无法进行还原，因此，使用此命令前，请确保磁盘中的数据已经备份。

## 格式化 Bcache 磁盘并挂载

```bash
mkfs.xfs /dev/bcache0
```

## 添加缓存盘

要为 bcache 后端磁盘添加缓存盘，在创建缓存盘成功之后，首先需要获取该缓存盘的 cset.uuid，通过 bcache-super-show 命令查看：

```bash
bcache-super-show /dev/sdc
```

最后一行即为该缓存盘的 `cset.uuid`，只要将此缓存盘的 `cset.uuid` attach 到 bcache 磁盘即可实现添加缓存操作，命令如下：

```bash
echo "d0079bae-b749-468b-ad0c-6fedbbc742f4" >/sys/block/bcache0/bcache/attach
```

## 参考资料

- <https://cloud.tencent.com/developer/article/1987561>

- <https://blog.csdn.net/gengduc/article/details/133908570>

- <https://blog.csdn.net/gengduc/article/details/133915134>
- <https://git.kernel.org/pub/scm/linux/kernel/git/colyli/bcache-tools.git/refs/>
