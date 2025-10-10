## 磁盘 LVM 扩容

`pvcreate` 创建 PV

```bash
pvcreate /dev/sdb
```

`vgextend` 扩容 VG

```bash
vgextend <VG_NAME> /dev/sdb
```

`lvextend` 扩容

```bash
# 按照磁盘添加
lvextend /dev/rocky/root /dev/sdb

# 按照容量添加
lvextend -L +100G /dev/rocky/root

# 按照 100%FREE 添加
lvextend -l +100%FREE /dev/rocky/root
```

扩容成功后调整文件系统分区大小

- ext4 格式

```bash
resize2fs /dev/rocky/root
```

- xfs 模式

```bash
xfs_growfs /dev/rocky/root
```

## 故障处理

PE 不够