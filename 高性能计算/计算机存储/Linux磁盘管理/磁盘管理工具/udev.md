## udev

### 配置文件

配置文件位于：

```
/etc/udev/udev.conf
```

常用的配置项：

- udev_root where in the filesystem to place the device nodes

```bash
udev_root="/dev/"
```

- udev_rules The name and location of the udev rules file

```bash
udev_rules="/etc/udev/rules.d/"
```

- udev_log set to "yes" if you want logging, else "no"

```bash
udev_log="no"
```

### 硬件文件数据库

硬件数据库文件（hwdb）位于操作系统发行商维护的 `/usr/lib/udev/hwdb.bin` 目录中， 以及二进制文件的 `/etc/udev/hwdb.d` 目录中

更新文件数据库：

```bash
udevadm hwdb --update
```

查看盘符信息：

```bash
nvme list
```

查看需要操作的盘的相关信息，主要是 `kernel、SUBSYSTEM、ATTR{address}`

```bash
udevadm info -a -p $(udevadm info -q path -n /dev/nvme1)
```

### 规则管理

#### 优先级

`/etc/udev/rules.d` 比 `/lib/udev/rules.d` 优先。

#### 常用 udev 键

- ACTION： 一个时间活动的名字，比如 add，当设备增加的时候
- KERNEL： 在内核里看到的设备名字，比如 `sd*` 表示任意SCSI磁盘设备
- DEVPATH ： 内核设备录进，比如 `/devices/*`
- SUBSYSTEM： 子系统名字，比如 sound,net
- BUS： 总线的名字，比如 IDE,USB
- DRIVER： 设备驱动的名字，比如 ide-cdrom
- ID： 独立于内核名字的设备名字
- SYSFS{value}： sysfs 属性值，他可以表示任意
- ENV{key}： 环境变量，可以表示任意
- PROGRAM： 可执行的外部程序，如果程序返回0值，该键则认为为真 (true)
- RESULT： 上一个 PROGRAM 调用返回的标准输出。
- NAME： 根据这个规则创建的设备文件的文件名。注意：仅仅第一行的 NAME 描述是有效的，后面的均忽略。 如果你想使用使用两个以上的名字来访问一个设备的话，可以考虑 SYMLINK 键。
- SYMLINK： 根据规则创建的字符连接名
- OWNER： 设备文件的属组
- GROUP： 设备文件所在的组。
- MODE： 设备文件的权限，采用8进制
- RUN： 为设备而执行的程序列表
- LABEL： 在配置文件里为内部控制而采用的名字标签(下下面的 GOTO 服务)
- GOTO： 跳到匹配的规则（通过LABEL来标识），有点类似程序语言中的 GOTO
- IMPORT{ type}： 导入一个文件或者一个程序执行后而生成的规则集到当前文件
- WAIT_FOR_SYSFS： 等待一个特定的设备文件的创建。主要是用作时序和依赖问题。
- PTIONS： 特定的选项： last_rule 对这类设备终端规则执行； ignore_device 忽略当前规则； ignore_remove 忽略接下来的并移走请求。all_partitions 为所有的磁盘分区创建设备文件。

#### 守护进程

重新加载规则

```bash
/usr/sbin/udevadm control --reload-rules
```

查看 udevd 状态

```bash
systemctl status systemd-udevd.service
```

开机自动启动 udev 服务

```bash
systemctl enable systemd-udevd.service
```

## 绑定盘符和槽位

### 用途

服务器下的硬盘主有机械硬盘、固态硬盘以及 raid 阵列，通常内核分配盘符的顺序是 `/dev/sda`、`/dev/sdb`… …。在系统启动过程中，内核会按照扫描到硬盘的顺序分配盘符（先分配直通的，再分配阵列）。在同一个硬盘槽位，热插拔硬盘，系统会顺着已存在的盘符分配下去，如之前分配的是 `/dev/sdb`，系统最后一块硬盘是 `/dev/sdf,`那么 `/dev/sdb/` 热拔插后，系统会重新分配这块硬盘的盘符为 `/dev/sdg`，出现盘符错乱的情况。

在此种情况下，可以用以下方法解决盘符错位的问题：

```bash
# 获取盘符信息
> udevadm info -q path -n /dev/sda

/devices/pci0000:00/0000:00:17.0/ata2/host1/target1:0:0/1:0:0:0/block/sda

# 将盘符信息写入 /etc/udev/rules.d/
> echo 'DEVPATH=="/devices/pci0000:00/0000:00:17.0/ata2/host1/target1:0:0/1:0:0:0/block/sda", NAME="sda", MODE="0660"' >> /etc/udev/rules.d/80-mydisk.rules
```

### 绑定普通盘

用个小脚本实现绑定所有的盘符和槽位

```bash
#!/bin/bash
disk="a b"
for i in ${disk};
   do
      a=`/usr/sbin/udevadm info -q path -n /dev/sd${i}`;
      if [ ! -n "$a" ]; then
          break 1 ;
      else
      echo DEVPATH=="\"${a}"\", NAME="\"sd${i}"\", MODE="\"0660"\">>/etc/udev/rules.d/80-mydisk.rules;
      fi
done
```


生成的  `/etc/udev/rules.d/80-mydisk.rules`

```plain
DEVPATH=="/devices/pci0000:00/0000:00:17.0/ata2/host1/target1:0:0/1:0:0:0/block/sda", NAME="sda", MODE="0660"
DEVPATH=="/devices/pci0000:00/0000:00:17.0/ata6/host5/target5:0:0/5:0:0:0/block/sdb", NAME="sdb", MODE="0660"
```

### 绑定 NVME 磁盘

首先，找到每个 NVMe 设备的唯一属性，如序列号或 WWN（世界范围名称）。使用以下命令列出 NVMe 设备的详细信息：

```bash
sudo nvme id-ctrl /dev/nvme0
sudo nvme id-ctrl /dev/nvme1
sudo nvme id-ctrl /dev/nvme2
sudo nvme id-ctrl /dev/nvme3
```

输出示例（只列出关键部分）：

```
NVME Identify Controller:
vid       : 0x8086
ssvid     : 0x8086
sn        : PHBT750300P32P0DGN  
mn        : INTEL SSDPEKKW512G7                         
fr        : PSF121C
```

在这里，`sn`（序列号）是唯一的标识符

创建一个新的 `udev` 规则文件，例如 `/etc/udev/rules.d/99-nvme.rules`：

```bash
# /etc/udev/rules.d/99-nvme.rules

# NVMe device 1
SUBSYSTEM=="block", KERNEL=="nvme0n1", ATTRS{serial}=="PHBT750300P32P0DGN", SYMLINK+="nvme_disk1"

# NVMe device 2
SUBSYSTEM=="block", KERNEL=="nvme1n1", ATTRS{serial}=="PHBT750300P32P1DGN", SYMLINK+="nvme_disk2"

# NVMe device 3
SUBSYSTEM=="block", KERNEL=="nvme2n1", ATTRS{serial}=="PHBT750300P32P2DGN", SYMLINK+="nvme_disk3"

# NVMe device 4
SUBSYSTEM=="block", KERNEL=="nvme3n1", ATTRS{serial}=="PHBT750300P32P3DGN", SYMLINK+="nvme_disk4"

```

重新加载 `udev` 规则并触发：

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

暂存

```bash
#!/bin/bash
disk="0 1"
for i in ${disk};
   do
      a=`/usr/sbin/udevadm info -q path -n /dev/nvme${i}n1`;
      if [ ! -n "$a" ]; then
          break 1 ;
      else
      echo DEVPATH=="\"${a}"\", NAME="\"nvme${i}n1"\", MODE="\"0660"\">>/etc/udev/rules.d/80-mydisk.rules;
      fi
done
```

### 测试

用 udevadm 进行测试，注意 udevadm 命令不接受 `/dev/sdc` 这样的挂载设备名，必须是使用 `/sys/block/sdb` 这样的原始设备名

```bash
udevadm test /sys/block/sdb

udevadm info --query=all --path=/sys/block/sdb

udevadm info --query=all --name=nvme1n1

udevadm control --reload-rules
```

## 问题记录

- 处理 `systemd-udevd[1011]: event3: Failed to call EVIOCSKEYCODE with scan code 0x7c, and key code 190: Invalid argument`

```bash
echo "blacklist eeepc_wmi" > /etc/modprobe.d/EVIOCSKEYCODE.conf
```

