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

