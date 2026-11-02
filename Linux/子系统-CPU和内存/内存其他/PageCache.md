## 清除缓存（Cache）

每个 Linux 系统有三种选项来清除缓存而不需要中断任何进程或服务。

- Cache，译作“缓存”，指 CPU 和内存之间高速缓存
- Buffer，译作“缓冲区”，指在写入磁盘前的存储再内存中的内容

仅清除页面缓存（PageCache）

```bash
sync; echo 1 > /proc/sys/vm/drop_caches
```

清除目录项和 inode

```bash
sync; echo 2 > /proc/sys/vm/drop_caches
```

清除页面缓存，目录项和 inode

```bash
sync; echo 3 > /proc/sys/vm/drop_caches
```

`sync`将刷新文件系统缓冲区（buffer），命令通过 “;” 分隔，顺序执行，shell 在执行序列中的下一个命令之前会等待命令的终止。正如内核文档中提到的，写入到 drop_cache 将清空缓存而不会杀死任何应用程序/服务，echo 命令做写入文件的工作。

如果你必须清除磁盘高速缓存，第一个命令在企业和生产环境中是最安全，`"...echo 1> ..."` 只会清除页面缓存。 在生产环境中不建议使用上面的第三个选项 `"...echo 3 > ..." `，除非你明确自己在做什么，因为它会清除缓存页，目录项和 inodes。

## 清除Linux的交换空间

如果想清除掉 Swap 空间，可以运行下面的命令：

```bash
swapoff -a && swapon -a
```

将上面两种命令结合成一个命令，写成正确的脚本来同时清除RAM缓存和交换空间

```bash
echo 3 > /proc/sys/vm/drop_caches && swapoff -a && swapon -a && printf '\n%s\n' 'Ram-cache and Swap Cleared'
```
