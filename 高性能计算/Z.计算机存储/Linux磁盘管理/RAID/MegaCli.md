## MegaCli 简介

MegaCli 是一款管理维护硬件 RAID 软件，可以通过它来了解当前 raid 卡的所有信息，包括 raid 卡的型号，raid 的阵列类型，raid 上各磁盘状态等等。通常，我们对硬盘当前的状态不太好确定，一般通过机房人员巡检来完成，而 MegaCli 可以轻松通过远程完成硬盘类巡检。

安装

```bash
wget https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
uzip 8-07-14_MegaCLI.zip
dnf localinstall -y MegaCli-8.07.14-1.noarch.rpm

# wget http://mirror.cogentco.com/pub/misc/MegaCli-8.07.14-1.noarch.rpm
# dnf localinstall -y MegaCli-8.07.14-1.noarch.rpm
```

额外安装软件包

```bash
dnf install -y ncurses-compat-libs
```

安装完毕之后 MegaCli64 所在路径为`/opt/MegaRAID/MegaCli/ MegaCli64`，在此路径下可以运行 MegaCli64 工具，切换到其它路径下则不能执行，此时为了使用方便，可以考虑将 `/opt/MegaRAID/MegaCli/MegaCli64` 追加到系统 PATH 变量

```bash
ln -s /opt/MegaRAID/MegaCli/MegaCli64 /usr/sbin/MegaCli64
```

## 常用查看命令

###  查看 RAID 卡状态

查 raid 卡信息 （可以查看 raid 卡时间，raid 卡时间和系统时间可能不一致，raid 卡日志用的是 raid 卡时间）

```bash
MegaCli64 -AdpAllInfo -aALL
```

查看 raid 卡日志

```bash
MegaCli64 -FwTermLog -Dsply -aALL
```

显示 Raid 卡型号，Raid 设置，Disk 相关信息

```bash
MegaCli64 -cfgdsply -aALL
```

### 查看 Controller 信息

显示适配器个数

```bash
MegaCli64 -AdpCount
```

显示所有适配器信息

```bash
MegaCli64 -AdpAllInfo -aAll
```

显示适配器时间

```bash
MegaCli64 -AdpGetTime -aALL
```

### 查看 BBU 信息

查看电池信息

```bash
MegaCli64 -AdpBbuCmd -aAll
```

查看充电状态

```bash
MegaCli64 -AdpBbuCmd -GetBbuStatus -aALL |grep 'Charger Status'
```

查看 BBU 状态信息

```bash
MegaCli64 -AdpBbuCmd -GetBbuStatus -aALL
```

显示 BBU 容量信息

```bash
MegaCli64 -AdpBbuCmd -GetBbuCapacityInfo -aALL
```

显示 BBU 设计参数

```bash
MegaCli64 -AdpBbuCmd -GetBbuDesignInfo -aALL
```

显示当前 BBU 属性

```bash
MegaCli64 -AdpBbuCmd -GetBbuProperties -aALL
```

当前 raid 缓存状态，raid 缓存状态设置为 wb 的话要注意电池放电事宜，设置电池放电模式为自动学习模式

```bash
MegaCli64 -ldgetprop -dskcache -Lall -aALL
```

设置电池为学习模式为循环模式

```bash
MegaCli -AdpBbuCmd -BbuLearn -aN|-a0,1,2|-aALL
```

### 查看硬盘信息

查看硬盘信息 （查看磁盘有无坏道：Media Error Count ）

一般通过 MegaCli 巡检到的 Media Error Count: 0 Other Error Count: 0 这两个数值来确定阵列中磁盘是否有问题

- Medai Error Count 表示磁盘可能错误，可能是磁盘有坏道，这个值不为 0 值得注意，数值越大，危险系数越高

- Other Error Count 表示磁盘可能存在松动，可能需要重新再插入

```bash
MegaCli64 -PDList -aALL
```

Megacli 查看硬盘状态，盘笼 ID，slot 以及是否是热备盘：

```bash
MegaCli64 -PDList -aALL | grep -E "^Enclosure Device|^Slot|^Raw|^Firmware|^Comm"
```

让硬盘 LED 灯闪烁

```bash
MegaCli64 -PdLocate -start -physdrv[0:1] -a0
```

### 查看 RAID 信息

查 raid 级别、显示所有逻辑磁盘组信息

```bash
MegaCli64 -LDInfo -Lall -aALL
```

查看虚拟磁盘信息

```bash
MegaCli64 -LdPdInfo -aALL |grep -E "Target Id|Slot Number|Firmware state"
```

扫描外来配置&清除

```bash
MegaCli64 -cfgforeign -scan -a0
MegaCli64 -cfgforeign -clear -a0
```

### 查看和设置磁盘缓存策略

查看磁盘缓存策略

```bash
# 显示 0 RAID 卡 0 RAID 组的缓存策略
MegaCli64 -LDGetProp -Cache -L0 -a0

# 显示 1 RAID 卡 0 RAID 组的缓存策略
MegaCli64 -LDGetProp -Cache -L1 -a0

# 显示所有 RAID 卡 0 RAID 组的缓存策略
MegaCli64 -LDGetProp -Cache -LALL -a0

# 显示所有 RAID 卡 所有 RAID 组的缓存策略
MegaCli64 -LDGetProp -Cache -LALL -aALL

MegaCli64 -LDGetProp -DskCache -LALL -aALL
```

设置磁盘的缓存模式和访问方式 （Change Virtual Disk Cache and Access Parameters）

缓存策略解释： 

- WT (Write through) ，即直写，表示将数据写入硬盘时，不经过阵列卡缓存直接写入，是默认策略
- WB (Write back)，即回写，表示数据写入硬盘时，先写入阵列卡缓存，当缓存写满时再写入硬盘；使用回写策略既能提高逻辑盘写入性能，也能增加磁盘寿命。使用回写策略，数据可能会留在缓存，在服务器断电且阵列卡没有电池时会导致数据丢失
- NORA (No Read Ahead)，即不预读
- RA (Read Ahead)，即强制预读，在进行读取操作时，预先把后面顺序的数据载入阵列卡卡缓存，这样能在顺序读写环境提供很好的性能，但是在随机读的环境中反而降低读取性能，它适合文件系统，而不适合数据库系统
- ADRA (Adaptive Read Ahead)，即自适应预读，在缓存和I/O空闲时进行预读，是默认策略
- C (Cached)，表示读取操作先缓存到阵列卡，这有利于数据的再次快速读取
- D (Direct)，表示读取操作不缓存到阵列卡缓存，是默认策略

示例

```bash
MegaCli64 -LDSetProp WT|WB|NORA|RA|ADRA -L0 -a0

MegaCli64 -LDSetProp -Cached|-Direct -L0 -a0

# enable / disable disk cache
MegaCli64 -LDSetProp -EnDskCache|-DisDskCache -L0 -a0
```

## 阵列管理

指定硬盘的位置时，`[Enclosure Device ID: Slot Number]`

特殊情况：

```bash
Enclosure Device ID: N/A
```

此时使用 `?` 替换 Enclosure Device ID

```bash
MegaCli64 -PdLocate -start -physdrv[?:1] -a0 
```

### 创建阵列

创建阵列，不指定热备

```bash
MegaCli64 -CfgLdAdd -r5 [0:0,0:1,0:2,0:3] WB Direct -a0
```

创建一个 raid5 阵列，指定阵列的热备盘是物理盘 4

```bash
MegaCli64 -CfgLdAdd -r5 [0:0,0:1,0:2,0:3] WB Direct -Hsp [0:4] -a0
```

创建一个 raid10 阵列，由物理盘 1,2 和 3,4 分别做 raid1，再将两组 raid1 做 raid0

```bash
MegaCli64 -CfgSpanAdd -r10 -Array0[0:1,0:2] -Array1[0:3,0:4] WB Direct -a0
```

### 删除阵列

```bash
MegaCli64 -CfgLdDel -L1 -a1
```

### 在线添加磁盘

```bash
MegaCli64 -LDRecon -Start -r5 -Add -PhysDrv[1:4] -L1 -a0
```

### 全局热备

指定第 5 块盘作为全局热备

```bash
MegaCli64 -PDHSP -Set [-EnclAffinity] [-nonRevertible] -PhysDrv[1:5] -a0
```

指定第 5 块盘为某个阵列的专用热备

```bash
MegaCli64 -PDHSP -Set [-Dedicated [-Array1]] [-EnclAffinity] [-nonRevertible] -PhysDrv[1:5] -a0
```

删除全局热备

```bash
MegaCli64 -PDHSP -Rmv -PhysDrv[8:11] -a0
```

### 某块物理盘下线/上线

将某块物理盘下线

```bash
MegaCli64 -PDOffline -PhysDrv [1:4] -a0
```

将某块物理盘上线

```bash
MegaCli64 -PDOnline -PhysDrv [1:4] -a0
```

### 查看物理磁盘重建进度

```bash
MegaCli64 -PDRbld -ShowProg -PhysDrv [1:5] -a0

MegaCli64 -PDRbld -ProgDsply -PhysDrv [1:5] -a0
```

### 部分硬盘切换直通

```bash
MegaCli64 -PDMakeJBOD -PhysDrv[?:4] -a0
```

## 初始化

快速初始化

```bash
 MegaCli64 -LDInit -start –L0 -a0
```

完全初始化

```bash
MegaCli64 -LDInit -start -full –L0 -a0
```

### 查看创建进度

初始化同步块的过程，可以看看其进度

```bash
MegaCli64 -LDInit -ShowProg -LALL -aALL

MegaCli64 -LDInit -ProgDsply -LALL -aALL
```

查看阵列后台初始化进度

```bash
MegaCli64 -LDBI -ShowProg -LALL -aALL

MegaCli64 -LDBI -ProgDsply -LALL -aALL
```

## RIAD 一致性检查

```bash
# 禁用一致性检查
MegaCli64 -AdpCcSched -Dsbl -Aall

# 启用一致性检查
MegaCli64 -AdpCcSched -ModeConc -Aall

# 查看一直性检查 信息
MegaCli64 -AdpCcSched -info -Aall
```

## flush raid cache

```bash
MegaCli64 -AdpCacheFlush -Aall
```

## 其他

### Direct PD  Mapping

查询 DirectPDmapping 状态

```bash
MegaCli64 -directpdmapping -Dsply -a0
```

设置 DirectPDmapping 为关闭状态

```bash
Megacli64 -directpdmapping -Dsbl -a0
```

### 无法初始化排查

The specified physical disk does not have the appropriate attributes to complete
the requested command.

```bash
MegaCli64 -PDMakeGood -PhysDrv '[?:0]' -Force -a0
```

## 参考文档

- <https://blog.51cto.com/u_15169172/2710846>

- <https://www.cnblogs.com/Pigs-Will-Fly/p/14327418.html>

- <https://www.cnblogs.com/machangwei-8/p/10403626.html>

- <https://support.huawei.com/enterprise/zh/doc/EDOC1000163568/98e64f3c>
