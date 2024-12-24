## Mkfs

使用 `mkfs.xfs` 可以将存储设备格式化为 XFS 格式

```bash
dd if=/dev/zero of=~/xfs.img bs=1M count=4096

mkfs.xfs ~/xfs.img
```

但若原存储已经被格式化过，则 `mkfs.xfs` 会拒绝再次格式化

```bash
mkfs.xfs ~/xfs.img 2>&1 ||exit 0
```

这个时候需要用 `-f` 选项表示强行格式化

```bash
mkfs.xfs -f ~/xfs.img
```

相关参数

- -b：后面接的是区块容量，范围是512B-64K。不过Linux最大为4K
- -d：后面接的是data section(数据区)的相关参数值

完整

```bash
mkfs.xfs  -b  block_size(块大小) options
          -d data_section_options（数据属性）(sunit/swidth(单位为512byte)=su/sw 条带大小/宽度)
                    mkfs.xfs -d su=4k(条块chunk大小),sw=16(数据盘个数) /dev/sdb
                    mkfs.xfs -d sunit=128,swidth= sunit*数据盘个数  /dev/sdd
               数据属性有：
                         agvount= value  指定分配组(并发小文件系统(16M~1T))
                         agsize = value   与上类似，指定分配组大小
                         name= 指定文件系统内指定文件的名称。此时，日志段必需指定在内部(指定大小)。
                         file [=value] 指定上面要命名的是常规文件(默认1，可以为0)。
                         size=value 指定数据段大小，需要 -d file =1
                         sunit=value 指定条带单元大小(chunk,单位为512)
                         su=value 指定条带单元(chunk,单位为byte. 如：64k，必需为文件系统块大小的倍数)
                         swidth=value 指定条带宽度(单位为512, 为sunit的数据盘个数倍数)
                         sw=value 条带宽度(通常为数据盘个数)
                         noalign  忽略自动对齐(磁盘几何形状探测，文件不用几何对齐)。
          -i inode_options 节点选项.(xfs inode 包含二部分：固定部份，可变部份)。
                         这些选项影响可变部份，包括：目录数据，属性数据，符号连接数据，文件extent列表，文件extent描述性根树。
                    选项有:
                          size = value | log=value | perblock =value  指定inode大小(256~2048)
                          maxpct=value  指定inode所有空间的百分比。(默认为:<1T=25%,<50T=5% >50T=1%)
                          align [=value] 指定分配inode时是否对齐。默认为1,对齐。    
                          attr = value  指定属性版本号，默认为2
                          projid32bit [=value]  是否使能32位配额项目标识符。默为1.      
          -f  强制(force)
          -l log_section_options （日志属性）(internal/logdev)
                选项有：
                        internal [=value]  指定日志段是否作为数据段的一部分。默认为1.
                        logdev = device  指定日志位于一个独立的设备上。(最小为10M,2560个4K块)
                                      创建：  mkfs.xfs -l logdev=/dev/ramhdb -f /dev/mapper/vggxxxxx
                                      挂载:    mount -o logdev=/dev/ramhdb /dev/mapper/vggxxxxx
                        size = value 指定日志段的大小。
                        version = value 指定日志的版本。默认为2
                        sunit = value 指定日志对齐写。单位为512
                        su= value  指定日志条带单元. 单位为byte
                        lazy-count = value  是否廷迟计数。默认为1.更改超级块中各种连续计数器的计录方法。
                             在为1时，不会在计数器每一次变化时更新超级块。         
          -n naming_options 命名空间(目录参数)
                选项有：
                        size= value | log = value 块大小。不能小于文件系统block，且是2的幂。
                              版本2默认为4096，(如果文件系统block>4096，则为block)     
                         version= value  命名空间的版本。默认为2 或'ci' ,
                         ftype = value 允许inode类型存储在目录结构中，以便readdir,getdents不需要查找inode就可知道inode类型。默认为0，不存在目录结构中。(使能crc: -m crc=1 时，此选项会使能)
          -p protofile
          -r realtime_section_options (实时数据属性)(rtdev/size)
               实时段选项：
                         rtdev =device 指定外部实时设备名
                         extsize=value指定实时段中块大小，必需为文件系统块大小的倍数。  最小为(max(文件系统块大小, 4K))。
                                   默认大小为条带宽度(条带卷)，或64K(非条带卷) ，最大为1G 
                         size = value  指定实时段的大小
                         noalign 此选项禁止 条带大小探测，强制实时设备没有几何条带。
          -s sector size（扇区大小），最小为512，最大为32768 (32k). 不能大于文件系统块大小。
          -L label   指定文件系统标签。最多12个字符
          -q(quiet 不打印) -f(Force 强制)
          -N  只打印信息，不执行实际的创建
```



## mkfs 参数调整

### 设置 block 大小

block 是文件系统存储的最小单位，较大的 block 可以增加文件系统和单个文件的大小上限并加快大文件的读写速度，但是会浪费较多空间。而太小的 block 则相反。

可以在格式化时指定 block 的大小，XFS 的大小最小为 512 字节，最大为 64KB，默认为 4K

在格式化时使用 `-b size=block 大小` 来指定区块大小

```bash
mkfs.xfs -f -b size=1k ~/xfs.img
```

这里大小单位可以是"k"表示kb，或者"s"表示扇区数，一个扇区默认为 512 字节，但可以通过 `-s` 选项改变

XFS 允许目录使用比文件系统 block 更大的 block，方法是使用 `-n size=block大小`

```bash
mkfs.xfs -f -b size=1k -n size=4k ~/xfs.img
```

### 日志大小

格式化 XFS 时，mkfs.xfs 会根据文件系统的大小自动分配日志的大小。 日志大小介于 512KB 到 128MB 之间，但可以通过 `-l size=日志大小` 来设置，其中日志的单位可以是：

- s：扇区
- b：block
- k：KB
- m：MB
- g：GB
- t：TB
- p：PB
- e：EB

```bash
mkfs.xfs -f -l size=64m ~/xfs.img
```

### 设置文件系统标签

Label 或者说 Volume Name 可以用来说明文件系统的用途，可以通过 `-L 标签` 来设置

```bash
mkfs.xfs -f -L TEST ~/xfs.img
```

可以使用 `xfs_admin` 来查看当前的label

```bash
xfs_admin -l ~/xfs.img
```

## 挂载 XFS 文件系统

在挂载时，可以使用一些性能增强的选项来发掘 XFS 文件系统的性能

```bash
mount -t xfs ~/xfs.img /mnt/xfs -o noatime,nodiratime
```

其他常见的 `-o` 选项包括:

- allocsize：延时分配时，预分配缓冲区的大小
- discard / nodiscard：块设备是否自动回收空间
- largeio：大块分配（建议不要使用）
- nolargeio：尽量小块分配
- noatime：读取文件时不更新访问时间
- nodiratime：不更新目录的访问时间
- norecovery：挂载时不运行日志恢复
- logbufs：内存中的日志缓冲区数量
- logbsize：内存中每个日志缓存区的大小