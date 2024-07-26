磁盘序列号冲突

```
esxcfg-info
```

![image-20240726154132599](./.assets/ESXi常见问题处理/image-20240726154132599.png)

```
nvme id-ns /dev/nvme0n1
nvme format /dev/nvme0n1 -n 1
# nvme format /dev/nvme0n1 -n 4358836543481126
# 16 位数字
```

- <https://bugzilla.kernel.org/show_bug.cgi?id=216049>

 Unable to boot system, won't mount because of missing partitions because of "nvme nvme1: globally duplicate IDs for nsid 1"

- <https://blog.csdn.net/Z_Stand/article/details/111415236>

```
excli nvme device namespace list -A vmhba5
```

