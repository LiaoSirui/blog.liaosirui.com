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

创建 RAID 10。使用以下命令创建 RAID 10：

```bash
mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

其中

- `/dev/md0` 是要创建的 RAID10 设备名称
- `--level=10` 表示创建 RAID10
- `--raid-devices=4` 表示将 4 个磁盘组成 RAID10

- `/dev/sdb1`、`/dev/sdc1`、`/dev/sdd1` 和 `/dev/sde1` 是要组合的磁盘的分区名称

格式化 RAID10。使用以下命令格式化 RAID10：

```bash
mkfs.xfs /dev/md0
```

挂载 RAID10。使用以下命令创建一个挂载点并将 RAID10 挂载到该点：

```bash
mkdir /mnt/raid10

mount /dev/md0 /mnt/raid10
```

