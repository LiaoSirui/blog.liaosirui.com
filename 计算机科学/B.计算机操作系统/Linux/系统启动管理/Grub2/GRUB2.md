<http://c.biancheng.net/view/1032.html>

从 Grub2 启动 ISO：<https://www.linuxbabe.com/desktop-linux/boot-from-iso-files-using-grub2-boot-loader>

```bash
# /etc/grub.d/40_custom
menuentry "rhel-8.3-x86_64-boot.iso" {
  insmod ext2
  search --no-floppy --fs-uuid --set=root 9e88c94e-4d17-49e2-bd2e-340bdcfd2c2a
  set isofile="/home/linuxbabe/Downloads/rhel-8.3-x86_64-boot.iso"
  loopback loop ($root)$isofile
  linux (loop)/isolinux/vmlinuz noeject inst.stage2=hd:/dev/sda5:$isofile
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