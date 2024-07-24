注释 `/etc/fstab` 中关于 swap 的部分

```bash
sudo sed -i '/swap/s/^/#/' /etc/fstab
```

取消挂载

```shell
umount /dev/mapper/centos-swap
```

删除逻辑卷

```shell
lvremove /dev/centos/swap
```

安装系统时就选择安装 swap 分区的话， grub 文件中会写死开机校验 swap 分区，由于swap分区已删除，导致系统卡进救援模式中

```shell
# 删除 grub.cfg 中所有关于 swap 的信息
GRUB_CMDLINE_LINUX=".... rd.lvm.lv=centos/swap ...."
```

扩容 lvm

```shell
lvextend -l +100%FREE  /dev/centos/root
xfs_growfs /dev/mapper/centos-root
```

