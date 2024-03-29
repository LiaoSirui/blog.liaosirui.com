## 磁盘 lvm 扩容 (例子)

1、 pvcreate 创建pv

```bash
pvcreate /dev/sdb
```

2、 vgextend 扩容 vg

```bash
vgextend <VG_NAME> /dev/sdb
```

3、lvextend 扩容

```bash
# 全部添加
lvextend /dev/centos/root /dev/sdb

# 按照100%FREE 添加
lvextend -l +100%FREE /dev/centos/root

# 按照容量添加
lvextend -L +100G /dev/centos/root
```

4、扩容成功后调整文件系统分区大小

- ext4 格式

```bash
resize2fs /dev/centos/root
```

- xfs 模式

```bash
xfs_growfs /dev/centos/root
```

