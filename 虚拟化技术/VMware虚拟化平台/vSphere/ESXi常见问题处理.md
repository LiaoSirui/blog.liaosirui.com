## EUI64 冲突

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

## 磁盘分区

磁盘

```bash
ls -lha /vmfs/devices/disks/
```

查看分区表

```
partedUtil getptbl /vmfs/devices/disks/xxxx
```

重建分区表

```
partedUtil setptbl /vmfs/devices/disks/xxx msdos
```

查看磁盘

```
esxcli storage vmfs extent list
```



```
# List all Logical Devices known on this system with device information
esxcfg-scsidevs -l

# Filter Logical Devices by display name and vendor
esxcfg-scsidevs -l | egrep -i 'display name|vendor'

# (compact)
# List all Logical Devices each on a single line with limited information
esxcfg-scsidevs -c
```

## 
