<https://golinux.gitbooks.io/raid/content/chapter9.html>

https://blog.csdn.net/weixin_30244681/article/details/99510612

<https://blog.csdn.net/GGxiaobai/article/details/59521459>

## 制作 RAID 10

确保已经安装 mdadm 工具。如果没有安装，可以使用以下命令进行安装：

```bash
dnf install -y mdadm
```

查看系统上的可用磁盘：

```bash
fdisk -l
```

检查分区表

```bash
wipefs /dev/sdb
```

清除所有分区表

```bash
wipefs -a -f /dev/sdb
```

创建 RAID 10。使用以下命令创建 RAID 10：

```bash
mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

其中

- `/dev/md0` 是要创建的 RAID10 设备名称
- `--level=10` 表示创建 RAID10
- `--raid-devices=4` 表示将 4 个磁盘组成 RAID10

- `/dev/sdb`、`/dev/sdc`、`/dev/sdd` 和 `/dev/sde` 是要组合的磁盘的分区名称

格式化 RAID10。使用以下命令格式化 RAID10：

```bash
mkfs.xfs /dev/md0
```

挂载 RAID10。使用以下命令创建一个挂载点并将 RAID10 挂载到该点：

```bash
mkdir /mnt/raid10

mount /dev/md0 /mnt/raid10
```

执行扫描

```bash
mdadm --detail --scan | tee -a /etc/mdadm.conf

ARRAY /dev/md/r10a metadata=1.2 name=dev-nas:r10a UUID=15a98904:5e59a203:68845e55:f31ab986
```

## 删除 raid

删除流程

（1）停止运行 RAID

```bash
mdadm --stop /dev/md0
```

（2）删除自动配置文件

将 `/etc/mdadm/mdadm.conf` 文件中关于该 md0 的配置信息删除即可，这个方式有很多种

由于配置信息中只有一个 RAID，将文件清空

```bash
> /etc/mdadm/mdadm.conf
```

（3）删除元数据

将 RAID 分区中的元数据删除

```bash
mdadm --misc --zero-superblock /dev/sda
```



