- 更改电源策略

选择【管理】-【硬件】-【电源管理】-【更改策略】- 高性能

## 常见问题处理

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

