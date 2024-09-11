使用 xfs_metadump 命令将已损坏的文件系统元数据导出

```bash
xfs_metadump -o /dev/sdb1 /tmp/sdb1.metadump

file /tmp/sdb1.metadump
```

使用 xfs_mdrestore 命令将元数据转换为映像文件

```bash
xfs_mdrestore /tmp/sdb1.metadump /tmp/sdb1.img

file /tmp/sdb1.img
```

使用 xfs_repair 命令对映像进行修复(注意不是强制修复)

```
xfs_repair /tmp/sdb1.img 
```

在系统上重新挂载刚刚修复的映像文件

```
mount /tmp/sdb1.img /mnt
```

只是一个评估是否能够恢复的过程

## 参考资料

- <https://zhuanlan.zhihu.com/p/643100023>

- <http://shouce.jb51.net/vbird-linux-basic-4/72.html>