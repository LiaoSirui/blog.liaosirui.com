## grubby

grubby 是一个命令行工具，用于更新和显示有关 grub2 和 zipl 引导加载程序的配置文件的信息

它主要设计用于安装新内核并需要查找有关当前引导环境的信息的脚本

同时也可以对启动内核的各项信息参数进行修改

## grubby 常用命令

### 查看默认内核版本

```bash
grubby --default-kernel
```

### 查看内核信息

查看系统安装的全部内核：

```bash
grubby --info=ALL

index=0
kernel="/boot/vmlinuz-5.14.0-162.6.1.el9_1.x86_64"
args="ro crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M rd.lvm.lv=rl_devmaster1/root net.ifnames=0"
root="/dev/mapper/rl_devmaster1-root"
initrd="/boot/initramfs-5.14.0-162.6.1.el9_1.x86_64.img"
title="Rocky Linux (5.14.0-162.6.1.el9_1.x86_64) 9.1 (Blue Onyx)"
id="a98618aa1631441dbb52c75a50834a0a-5.14.0-162.6.1.el9_1.x86_64"
index=1
kernel="/boot/vmlinuz-5.14.0-70.30.1.el9_0.x86_64"
args="ro crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M rd.lvm.lv=rl_devmaster1/root net.ifnames=0"
root="/dev/mapper/rl_devmaster1-root"
initrd="/boot/initramfs-5.14.0-70.30.1.el9_0.x86_64.img"
title="Rocky Linux (5.14.0-70.30.1.el9_0.x86_64) 9.0 (Blue Onyx)"
id="a98618aa1631441dbb52c75a50834a0a-5.14.0-70.30.1.el9_0.x86_64"
index=2
kernel="/boot/vmlinuz-5.14.0-70.22.1.el9_0.x86_64"
args="ro crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M rd.lvm.lv=rl_devmaster1/root net.ifnames=0"
root="/dev/mapper/rl_devmaster1-root"
initrd="/boot/initramfs-5.14.0-70.22.1.el9_0.x86_64.img"
title="Rocky Linux (5.14.0-70.22.1.el9_0.x86_64) 9.0 (Blue Onyx)"
id="a98618aa1631441dbb52c75a50834a0a-5.14.0-70.22.1.el9_0.x86_64"
index=3
kernel="/boot/vmlinuz-0-rescue-a98618aa1631441dbb52c75a50834a0a"
args="ro crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M rd.lvm.lv=rl_devmaster1/root net.ifnames=0"
root="/dev/mapper/rl_devmaster1-root"
initrd="/boot/initramfs-0-rescue-a98618aa1631441dbb52c75a50834a0a.img"
title="Rocky Linux (0-rescue-a98618aa1631441dbb52c75a50834a0a) 9.0 (Blue Onyx)"
id="a98618aa1631441dbb52c75a50834a0a-0-rescue"

```

查看特定内核的具体信息：

```bash
 grubby --info=/boot/vmlinuz-5.14.0-70.30.1.el9_0.x86_64
```

### 设置默认启动内核

设置新的默认启动内核：

- 使用路径来指定内核，可以使用 --set-default=kernel-path

```bash
grubby --set-default=/boot/vmlinuz-5.14.0-70.30.1.el9_0.x86_64

grubby --default-kernel
```

- 使用 index 来指定内核，则使用 --set-default-index=entry-index

```bash
grubby --set-default-index=1

grubby --default-kernel
```

### 删除内核

从启动项中删除旧内核（可选）

```bash
grubby --remove-kernel=/boot/vmlinuz-4.18.0-348.el8.x86_64
```

删除未使用的内核

```bash
dnf remove --oldinstallonly --setopt installonly_limit=2 kernel
```

### 管理内核参数

添加/删除内核启动参数：

```bash
# 对所有的内核都删除某个参数  
grubby --update-kernel=ALL --remove-args=intel_iommu=on

# 对所有的内核都添加某个参数  
grubby --update-kernel=ALL --args=intel_iommu=on

# 对某个的内核添加启动参数  
grubby --update-kernel=/boot/vmlinuz-5.14.0-162.12.1.el9_1.0.2.x86_64 --args=intel_iommu=on

```

## 常用的内核参数

```bash
grubby --update-kernel=ALL --args=net.ifnames=0
grubby --update-kernel=ALL --args=biosdevname=0
grubby --update-kernel=ALL --args=selinux=0

grubby --update-kernel=ALL --args="console=ttyS0,115200n8"
grubby --update-kernel=ALL --args=serial

grubby --update-kernel=ALL --args=ipv6.disable=1
```

