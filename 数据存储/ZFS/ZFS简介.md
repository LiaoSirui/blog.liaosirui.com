## OpenZFS 安装

安装 openzfs

```bash
# https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL-based%20distro/index.html
dnf install -y https://zfsonlinux.org/epel/zfs-release-3-0$(rpm --eval "%{dist}").noarch.rpm
dnf list available --showduplicates zfs
dnf install -y zfs-2.2.10-1.el10
dnf versionlock zfs

modprobe -- zfs
echo zfs | sudo tee /etc/modules-load.d/zfs.conf

systemctl enable --now zfs-import-cache zfs-import.target zfs-mount zfs.target zfs-zed
```

## ZFS

zpool 负责"存储从哪来"(物理磁盘管理),dataset 负责"存储怎么用"(逻辑划分与策略管理)。建议按用途划分 dataset(如 home、数据库、媒体、备份各一个),而不是把所有东西塞进池的根目录。

