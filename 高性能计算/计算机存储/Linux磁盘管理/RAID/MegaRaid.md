## MegaCli 简介

MegaCli 是一款管理维护硬件 RAID 软件，可以通过它来了解当前 raid 卡的所有信息，包括 raid 卡的型号，raid 的阵列类型，raid 上各磁盘状态等等。通常，我们对硬盘当前的状态不太好确定，一般通过机房人员巡检来完成，而 MegaCli 可以轻松通过远程完成硬盘类巡检。

一般通过 MegaCli 巡检到的 Media Error Count: 0 Other Error Count: 0 这两个数值来确定阵列中磁盘是否有问题；Medai Error Count 表示磁盘可能错误，可能是磁盘有坏道，这个值不为 0 值得注意，数值越大，危险系数越高，Other Error Count 表示磁盘可能存在松动，可能需要重新再插入。

安装

```bash
wget https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
uzip 8-07-14_MegaCLI.zip
rpm -ivh MegaCli-8.07.14-1.noarch.rpm

# wget http://mirror.cogentco.com/pub/misc/MegaCli-8.07.14-1.noarch.rpm
# rpm -ivh MegaCli-8.07.14-1.noarch.rpm

# 软链接目录
ln -s /opt/MegaRAID/MegaCli/MegaCli64 /usr/bin/MegaCli
```

## 常用命令

查 raid 级别、显示所有逻辑磁盘组信息

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -LDInfo -Lall -aALL
```

查 raid 卡信息 （可以查看 raid 卡时间，raid 卡时间和系统时间可能不一致，raid 卡日志用的是 raid 卡时间）

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -aALL
```

查看硬盘信息 （查看磁盘有无坏道：Media Error Count ）

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL
```

查看 raid 卡日志

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -FwTermLog -Dsply -aALL
```

显示 Raid 卡型号，Raid 设置，Disk 相关信息

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -cfgdsply -aALL
```

查看虚拟磁盘信息

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -LdPdInfo -aALL |grep -E "Target Id|Slot Number|Firmware state"
```

Megacli 查看硬盘状态，盘笼 ID，slot 以及是否是热备盘：

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL | grep -E "^Enclosure Device|^Slot|^Raw|^Firmware|^Comm"
```

在线添加磁盘

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -LDRecon -Start -r5 -Add -PhysDrv[1:4] -L1 -a0
```

创建阵列，不指定热备

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -CfgLdAdd -r5 [1:2,1:3,1:4] WB Direct -a0
```

创建一个 raid5 阵列，由物理盘 2,3,4 构成，指定阵列的热备盘是物理盘 5

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -CfgLdAdd -r5 [1:2,1:3,1:4] WB Direct -Hsp[1:5] -a0
```

指定第 5 块盘作为全局热备

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PDHSP -Set [-EnclAffinity] [-nonRevertible] -PhysDrv[1:5] -a0
```

指定第 5 块盘为某个阵列的专用热备

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PDHSP -Set [-Dedicated [-Array1]] [-EnclAffinity] [-nonRevertible] -PhysDrv[1:5] -a0
```

删除全局热备

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PDHSP -Rmv -PhysDrv[8:11] -a0
```

删除阵列

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -CfgLdDel -L1 -a1
```

将某块物理盘下线

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PDOffline -PhysDrv [1:4] -a0
```

将某块物理盘上线

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PDOnline -PhysDrv [1:4] -a0
```

清除所有的 raid 组的配置

```bash
# 清除所有的 raid 组的配置
/opt/MegaRAID/MegaCli/MegaCli64  -cfgclr  -a0

# 删除指定的 raid 组(Target Id: 0)的 raid 组，可以通过上面的“查看逻辑盘详细信息”得到
/opt/MegaRAID/MegaCli/MegaCli64  -cfglddel  -L1 -a0
```

让硬盘 LED 灯闪烁

```bash
/opt/MegaRAID/MegaCli/MegaCli64 -PdLocate -start –physdrv[252:0] -a0 
```
