## 查看磁盘设备文件

从 dev 目录查看

```bash
> ls /dev/sd*

/dev/sda  /dev/sdb  /dev/sdb1
```

也可以用 `lsblk` 查看，更加直观

```
NAME                   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                      8:0    0  14.6T  0 disk
sdb                      8:16   0 931.5G  0 disk
`-sdb1                   8:17   0 931.5G  0 part /registry
nvme1n1                259:0    0 238.5G  0 disk
`-nvme1n1p1            259:1    0 238.5G  0 part /mnt/beegfs-data
nvme0n1                259:2    0 476.9G  0 disk
|-nvme0n1p1            259:3    0     1G  0 part /boot/efi
|-nvme0n1p2            259:4    0     1G  0 part /boot
`-nvme0n1p3            259:5    0 474.9G  0 part
  `-rl_devmaster3-root 253:0    0 474.9G  0 lvm  /
```

## 磁盘分区

磁盘分区命令使用 fdisk

使用方式如：

```
fdisk /dev/sda
```

弹出二级命令提示符： `Command (m for help): `  --> 提示我们输入 `m` 来查看帮助信息

### 查看帮助信息

Command (m for help)：m      --> 输入 m 命令来查看帮助信息
弹出如下帮助信息：                --> 这个信息非常有用

```plain
Help:

  GPT
   M   enter protective/hybrid MBR

  Generic
   # d 删除一个分区
   d   delete a partition
   F   list free unpartitioned space
   # l 列出已知分区类型
   l   list known partition types
   # n 新建一个分区
   n   add a new partition
   # p 打印分区表
   p   print the partition table
   t   change a partition type
   # v 验证分区表
   v   verify the partition table
   i   print information about a partition

  Misc
   # m 打印出菜单(帮助信息)
   m   print this menu
   # x 额外功能 -> 专家选项
   x   extra functionality (experts only)

  Script
   I   load disk layout from sfdisk script file
   O   dump disk layout to sfdisk script file

  Save & Exit
   # w 保存分区表到磁盘并且退出
   w   write table to disk and exit
   # q 不保存退出
   q   quit without saving changes

  Create a new label
   # g 创建一个空的 GPT 分区表
   g   create a new empty GPT partition table
   G   create a new empty SGI (IRIX) partition table
   # o 创建一个空的 DOS 分区表
   o   create a new empty DOS partition table
   s   create a new empty Sun partition table

```

