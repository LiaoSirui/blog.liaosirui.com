需要一个额外的磁盘或者分区（拉起来 iso 安装镜像后，这个分区不能被移除或者安装覆盖）

例如这里有第二块磁盘 

```
# lsblk 

NAME            MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
sda               8:0    0  50G  0 disk
├─sda1            8:1    0   1G  0 part /boot/efi
├─sda2            8:2    0   1G  0 part /boot
└─sda3            8:3    0  48G  0 part
  └─rocky9-root 253:0    0  48G  0 lvm  /
sdb               8:0    0  50G  0 disk
└─sdb1            8:1    0   5G  0 part 
```

这里把 sdb1 直接做个 xfs 或者 ext4 分区（推荐 ext4）

```bash
mkfs.ext4 /dev/sdb1

# 挂载
mkdir /mnt/iso
mount /dev/sdb1 /mnt/iso

# 将 iso 文件拷贝到 /mnt/iso
cp CentOS7.iso /mnt/iso
# 文件为 `/mnt/iso/CentOS7.iso`
```

找到磁盘的 UUID

```
lsblk -o +UUID /dev/sdb1
```

Grub2 的自定义条目放置在 `/etc/grub.d/40_custom`，将下面的内容填入文件末尾

```bash
menuentry "CentOS7.iso" {
    search --no-floppy --fs-uuid --set=root 9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a
    set isofile="/CentOS7.iso"
    loopback loop ($root)$isofile
    linux (loop)/isolinux/vmlinuz noeject inst.stage2=hd:UUID=9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a:$isofile
    # linuxefi (loop)/isolinux/vmlinuz noeject inst.stage2=hd:UUID=9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a:$isofile
    initrd (loop)/isolinux/initrd.img
    # initrdefi (loop)/isolinux/initrd.img
}
```

说明：

- 第二行中的 search 和第 5、6 行中的 UUID 替换为先前拿到的 UUID
- 第三行是 iso 文件名
- 这里 6、8 被注释的原因是：如果是 EFI 启动，命令是 `linuxefi` 和 `initrdefi`
- 第 5 到第 8 行的写法对 CentOS 系列是固定的，其他的系列参考：<https://www.linuxbabe.com/desktop-linux/boot-from-iso-files-using-grub2-boot-loader>

设置 grub 超时

```
[root@dev-router ~]# cat /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console
```

其中 `GRUB_TIMEOUT` 直接改为 1200，确保一定能选择到（不建议直接设置 iso 为启动项，万一有错误，不好救操作系统）

最后生成新的 grub.cfg 配置

```bash
# boot
grub2-mkconfig -o /boot/grub2/grub.cfg

# efi 方式
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

# rocky linux efi
grub2-mkconfig -o /boot/efi/EFI/rocky/grub.cfg
```





<http://c.biancheng.net/view/1032.html>

从 Grub2 启动 ISO：<https://www.linuxbabe.com/desktop-linux/boot-from-iso-files-using-grub2-boot-loader>

```bash
# /etc/grub.d/40_custom
menuentry "Rocky-9.6-x86_64-minimal.iso" {
  insmod ext2
  search --no-floppy --fs-uuid --set=root 9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a
  set isofile="/Rocky-9.6-x86_64-minimal.iso"
  loopback loop ($root)$isofile
  linux (loop)/isolinux/vmlinuz noeject inst.stage2=hd:UUID=9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a:$isofile
  initrd (loop)/isolinux/initrd.img
}

menuentry "CentOS7.iso" {
    search --no-floppy --fs-uuid --set=root 9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a
    set isofile="/CentOS7.iso"
    loopback loop ($root)$isofile
    linux (loop)/isolinux/vmlinuz noeject inst.stage2=hd:UUID=9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a:$isofile
    # linuxefi (loop)/isolinux/vmlinuz noeject inst.stage2=hd:UUID=9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a:$isofile
    initrd (loop)/isolinux/initrd.img
    # initrdefi (loop)/isolinux/initrd.img
}
```

说明：

- menuentry：此条目将显示在 GRUB2 启动菜单上。你可以随意命名。
- insmod 命令：插入一个模块。由于 ISO 文件存储在我的 ext4 主目录下，因此需要使用 ext2 模块。如果它存储在 NTFS 分区上，则需要使用 insmod ntfs。请注意，GRUB 可能无法识别 XFS 和 Btrfs 文件系统，因此不建议将 ISO 文件存储在 XFS 或 Btrfs 分区上。
- set isofile：指定 ISO 映像文件的路径。这里我使用的是存储在 Downloads 文件夹下的 Ubuntu 20.04 Desktop ISO 文件。
- loopback：挂载 ISO 文件。hd0 表示计算机中的第一块硬盘，5 表示 ISO 文件存储在第 5 个磁盘分区上。
- linux 命令：从指定路径加载 Linux 内核。casper/vmlinuz.efi 是 Ubuntu ISO 映像中的 Linux 内核。
- initrd 命令：从指定路径加载初始 RAM 磁盘。它只能在 linux 命令运行之后使用。初始 RAM 磁盘是挂载到 RAM 上的最小根文件系统

请注意，GRUB 不区分 IDE 和 SCSI。在 Linux 内核中：

- /dev/hda 指的是第一块 IDE 硬盘
- /dev/sda 指的是第一块 SCSI 或 SATA 硬盘
- `/dev/nvme0n1` 指的是第一块 NVMe SSD，`/dev/nvme1n1` 指的是第二块 NVMe SSD

但是在 GRUB 中，第一块硬盘始终称为 hd0，无论接口类型如何。此外，GRUB 中的分区号从 1 开始，而不是从 0 开始

如果 ISO 文件存储在 MBR 磁盘的扩展分区中，分区号从 5 开始，而不是从 1 开始。例如，扩展分区内的第一个逻辑分区编号为 5；扩展分区内的第二个逻辑分区编号为 6。要检查你的分区号，可以在终端窗口中运行 lsblk 或 sudo parted -l 命令
