## 安装

```bash
dnf install -y smartmontools
```

## 查看固态盘总写入量等信息

首先找到固态盘的设备名。

在终端中输入`ls /dev/nvm*`

![image-20221201104746043](.assets/image-20221201104746043.png)

`/dev/nvme0` 和 `/dev/nvme1` 就是固态盘的设备名。

然后输入

```
smartctl -a /dev/nvme0
```

得到输出

```
smartctl 7.2 2020-12-30 r5155 [x86_64-linux-5.14.0-70.30.1.el9_0.x86_64] (local build)
Copyright (C) 2002-20, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       HS-SSD-CC300 256G
Serial Number:                      30073844560
Firmware Version:                   SN09111
PCI Vendor/Subsystem ID:            0x1e4b
IEEE OUI Identifier:                0x000000
Total NVM Capacity:                 256,060,514,304 [256 GB]
Unallocated NVM Capacity:           0
Controller ID:                      0
NVMe Version:                       1.4
Number of Namespaces:               1
Namespace 1 Size/Capacity:          256,060,514,304 [256 GB]
Namespace 1 Utilization:            219,253,913,088 [219 GB]
Namespace 1 Formatted LBA Size:     512
Namespace 1 IEEE EUI-64:            000000 0000000001
Local Time is:                      Thu Dec  1 10:48:16 2022 CST
Firmware Updates (0x16):            3 Slots, no Reset required
Optional Admin Commands (0x0017):   Security Format Frmw_DL Self_Test
Optional NVM Commands (0x001f):     Comp Wr_Unc DS_Mngmt Wr_Zero Sav/Sel_Feat
Log Page Attributes (0x03):         S/H_per_NS Cmd_Eff_Lg
Maximum Data Transfer Size:         128 Pages
Warning  Comp. Temp. Threshold:     90 Celsius
Critical Comp. Temp. Threshold:     95 Celsius

Supported Power States
St Op     Max   Active     Idle   RL RT WL WT  Ent_Lat  Ex_Lat
 0 +     6.50W       -        -    0  0  0  0        0       0
 1 +     5.80W       -        -    1  1  1  1        0       0
 2 +     3.60W       -        -    2  2  2  2        0       0
 3 -   0.0500W       -        -    3  3  3  3     5000   10000
 4 -   0.0025W       -        -    4  4  4  4     8000   45000

Supported LBA Sizes (NSID 0x1)
Id Fmt  Data  Metadt  Rel_Perf
 0 +     512       0         0

=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        40 Celsius
Available Spare:                    100%
Available Spare Threshold:          1%
Percentage Used:                    0%
Data Units Read:                    495,622 [253 GB]
Data Units Written:                 427,742 [219 GB]
Host Read Commands:                 2,567,076
Host Write Commands:                494,270
Controller Busy Time:               10
Power Cycles:                       12
Power On Hours:                     1,781
Unsafe Shutdowns:                   6
Media and Data Integrity Errors:    0
Error Information Log Entries:      39
Warning  Comp. Temperature Time:    0
Critical Comp. Temperature Time:    0
Temperature Sensor 1:               50 Celsius
Temperature Sensor 2:               51 Celsius
Temperature Sensor 3:               52 Celsius
Temperature Sensor 4:               53 Celsius
Temperature Sensor 5:               54 Celsius
Temperature Sensor 6:               55 Celsius
Temperature Sensor 7:               56 Celsius
Temperature Sensor 8:               57 Celsius

Error Information (NVMe Log 0x01, 16 of 64 entries)
Num   ErrCount  SQId   CmdId  Status  PELoc          LBA  NSID    VS
  0         39     0  0x000e  0x2002  0x000            0     0     -

```

指标含义
ID1：Critical Warning 警告状态
RAW 数值显示 0 为正常无警告，1 为过热警告，2 为闪存介质引起的内部错误导致可靠性降级，3 为闪存进入只读状态，4 为增强型断电保护功能失效（只针对有该特性的固态硬盘）。

正常情况下 ID1 的 RAW 属性值应为 0，当显示为 1 时代表 NVMe 固态硬盘已经过热，需要改善散热条件或降低工作负载。属性值为 2 时应考虑返修或更换新硬盘，当属性值为 3 时硬盘已经进入只读状态，无法正常工作，应抓紧时间备份其中的数据。家用固态硬盘通常不会配备增强型断电保护（完整断电保护），所以通常该项目不会显示为 4。

ID2：Temperature 当前温度（十进制显示）

ID3：Available Spare 可用冗余空间（百分比显示）
指示当前固态硬盘可用于替换坏块的保留备用块占出厂备用块总数量的百分比。该数值从出厂时的 100% 随使用过程降低，直至到零。ID3 归零之前就有可能产生不可预料的故障，所以不要等到该项目彻底归零才考虑更换新硬盘。

ID4：Available Spare Threshold 备用空间阈值
与 ID3 相关，当 ID3 的数值低于 ID4 所定义的阈值之后，固态硬盘被认为达到极限状态，此时系统可能会发出可靠性警告。该项数值由厂商定义，通常为 10% 或 0%。

ID5：Percentage Used 已使用的写入耐久度（百分比显示）
该项显示已产生的写入量占厂商定义总写入寿命的百分比。该项数值为动态显示，计算结果与写入量及固态硬盘的 TBW 总写入量指标有关。新盘状态下该项目为 0%

ID6：Data Units Read 读取扇区计数（1000）
该项数值乘以 1000 后即为读取的扇区（512Byte）数量统计。

ID7：Data Units Write 写入扇区计数（1000）
该项数值乘以 1000 后即为写入的扇区（512Byte）数量统计。

ID8：Host Read Commands 读取命令计数
硬盘生命周期内累计接收到的读取命令数量统计。

ID9：Host Write Commands 写入命令计数
硬盘生命周期内累计接收到的写入命令数量统计。

ID10：Controller Busy Time 主控繁忙时间计数
该项统计的是主控忙于处理 IO 命令的时间总和（单位：分钟）。当 IO 队列有未完成的命令时，主控即处于 “忙” 的状态。

ID11：Power Cycles 通电次数

ID12：Power On Hours 通电时间

ID13：Unsafe Shut downs 不安全关机次数（异常断电计数）

ID14：Media and Data Integrity Errors 闪存和数据完整性错误

主控检测到未恢复的数据完整性错误的次数。正常情况下主控不应检测到数据完整性错误（纠错应该在此之前完成），当有不可校正的 ECC、CRC 校验失败或者 LBA 标签不匹配错误发生时，该数值会增加。正常情况下 ID14 应保持为零。

ID15：Number of Error Information Log Entries 错误日志条目计数

控制器使用期限内，发生的错误信息日志条目的数量统计。正常情况该项目应为零。

以下项目为非标准项，并非所有 NVMe SSD 都支持显示。
ID16：Warning Composite Temperature Time 过热警告时间
ID17：Critical Composite Temerature Time 过热临界温度时间
ID18-25：Temperature Sensor X：多个温度传感器（若存在）的读数

## 参考资料

- <https://blog.csdn.net/qq_24343177/article/details/122521952>
