## PV 管理

### pvcreate

创建物理卷

用法：`pvcreate [option] DEVICE`

选项：

```none
-f：强制创建逻辑卷，不需用户确认
-u：指定设备的UUID
-y：所有问题都回答yes

例子:
  pvcreate /dev/sda5 /dev/sda6
```

### pvscan

扫描当前系统上的所有物理卷

用法：`pvscan [option]`

选项：

```none
-e：仅显示属于输出卷组的物理卷
-n：仅显示不属于任何卷组的物理卷
-u：显示UUID
```

### pvdisplay

显示物理卷的属性

用法：`pvdisplay [PV_DEVICE]`

### pvremove 

将物理卷信息删除，使其不再被视为一个物理卷

用法：`pvremove [option] PV_DEVICE`

选项：

```none
-f：强制删除
-y：所有问题都回答yes

例子:
  pvremove /dev/sda5
```

## VG 管理

### vgcreate

创建卷组

用法：`vgcreate [option] VG_NAME PV_DEVICE`

选项：

```none
-s：卷组中的物理卷的PE大小，默认为4M
  -l：卷组上允许创建的最大逻辑卷数
  -p：卷级中允许添加的最大物理卷数

例子:
vgcreate -s 8M myvg /dev/sda5 /dev/sda6
```

### vgscan

查找系统中存在的 LVM 卷组，并显示找到的卷组列表

用法：`vgscan [option]`

### vgdisplay

显示卷组属性

用法：`vgdisplay [option] [VG_NAME]`

选项：

```none
-A：仅显示活动卷组的信息
-s：使用短格式输出信息
```

### vgreduce

通过删除 LVM 卷组中的物理卷来减少卷组容量，不能删除 LVM 卷组中剩余的最后一个物理卷

用法：`vgreduce VG_NAME PV_DEVICE`

### vgextend

动态扩展 LVM 卷组，它通过向卷组中添加物理卷来增加卷组的容量

用法：`vgextend VG_NAME PV_DEVICE`

例 `vgextend myvg /dev/sda7`

### vgremove

删除卷组，其上的逻辑卷必须处于离线状态

用法：`vgremove [-f] VG_NAME`

```none
-f：强制删除
```

### vgchange

常用来设置卷组的活动状态

用法：`vgchange -a n/y VG_NAME`

```none
-a n

为休眠状态，休眠之前要先确保其上的逻辑卷都离线

-a y

设置为活动状态
```

## LV 管理

### lvcreate

创建逻辑卷或快照

用法：lvcreate [选项] [参数]

选项：

```none
-L：指定大小
-l：指定大小（LE数）
-n：指定名称
-s：创建快照
-p r：设置为只读（该选项一般用于创建快照中）
```

注：使用该命令创建逻辑卷时当然必须指明卷组，创建快照时必须指明针对哪个逻辑卷

例: `lvcreate -L 500M -n mylv myvg`

`-l 100%VG ` 表示使用全部空间；`-l 100%FREE` 表示使用全部剩余

### lvscan

扫描当前系统中的所有逻辑卷，及其对应的设备文件

### lvdisplay

显示逻辑卷属性

用法：`lvdisplay [/dev/VG_NAME/LV_NAME]`

### lvextend

可在线扩展逻辑卷空间

用法：`lvextend -L/-l 扩展的大小 /dev/VG_NAME/LV_NAME`

选项：

```none
-L：指定扩展（后）的大小。例如，-L +800M 表示扩大 800M，而 -L 800M表示扩大至 800M

-l：指定扩展（后）的大小（LE数）
```

例 `lvextend -L 200M /dev/myvg/mylv`

### lvreduce

缩减逻辑卷空间，一般离线使用

用法：`lvexreduce -L/-l 缩减的大小 /dev/VG_NAME/LV_NAME`

选项：

```none
-L：指定缩减（后）的大小

-l：指定缩减（后）的大小（LE数）
```

例 `lvreduce -L 200M /dev/myvg/mylv`

### lvremove

删除逻辑卷，需要处于离线（卸载）状态

用法：`lvremove [-f] /dev/VG_NAME/LV_NAME`

```none
-f：强制删除
```
