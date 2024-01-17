## 对root分区强制fsck

强制对根分区（如“/dev/sda1”）执行fsck文件系统检查的最简单方法是：
在分区的根目录中创建一个名为“forcefsck”的空文件。

```bash
touch /forcefsck
```

此空文件将临时覆盖任何其他设置，并在下次系统重新启动时强制“fsck”检查文件系统

检查文件系统后，“forcefsck”文件将被删除，因此下次重新启动文件系统时不会再次检查文件系统

## 参考资料

- <https://www.onitroad.com/jc/linux/faq/how-to-force-fsck-to-check-filesystem-after-system-reboot-on-linux.html>