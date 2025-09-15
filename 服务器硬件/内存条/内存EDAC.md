## EDAC

DRAM（Dynamic Random Access Memory），即动态随机存取存储器，最为常见的系统内存。ECC 是 “Error Checking and Correcting” 的简写，中文名称是 “错误检查和纠正”。ECC 内存，即应用了能够实现错误检查和纠正技术（ECC）的内存条。EDAC，即 Error Detection And Correction（错误检测与纠正）。

常见内存故障类型

- Corrected error：可纠正错误（CE），该错误被检测到并且被纠正，不影响系统运行，比如内存 DDR 单 bit 错误，可以通过 ECC 纠正。
- Deferred error：延迟的错误（DE），没有被沉默（silently）传播，可能是系统潜在的错误。比如内存控制器写数据到内存条，发现要写的数据存在不可纠正错误，它会将该错误数据写到内存，并打上 poison 标记，则为 deferred 错误。
- Uncorrected error：不可纠正错误（UE），该错误被检测到且未被纠正或延迟，它又可划分为下面几个子类：潜伏错误或可重启错误（UEO）、带标记错误或可恢复错误（UER）、不可恢复错误（UEU）、不可抑制错误（UC）。

## 故障定位

查看 message 日志确定类型

```bash
# grep kernel /var/log/messages

Sep 15 08:37:28 bak-data-server-112 kernel: EDAC MC2: 1 CE memory read error on CPU_SrcID#0_MC#2_Chan#0_DIMM#0 (channel:0 slot:0 page:0x90ba03 offset:0x400 grain:32 syndrome:0x0 -  err_code:0x0080:0x0090  SystemAddress:0x90ba03400 ProcessorSocketId:0x0 MemoryControllerId:0x2 ChannelAddress:0x222e80e00 ChannelId:0x0 RankAddress:0x445d01c0 PhysicalRankId:0x0 DimmSlotId:0x0 DimmRankId:0x0 Row:0x1424 Column:0x520 Bank:0x0 BankGroup:0x2 ChipSelect:0x0 ChipId:0x4)
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]: Hardware error from APEI Generic Hardware Error Source: 0
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]: It has been corrected by h/w and requires no further action
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]: event severity: corrected
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:  Error 0, type: corrected
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:  fru_text: Card01, ChnE, DIMM0
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:   section_type: memory error
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:    error_status: Storage error in DRAM memory (0x0000000000000400)
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:   physical_address: 0x000000090ba03400
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:   node:0 card:4 module:0
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:   error_type: 2, single-bit ECC
Sep 15 08:37:28 bak-data-server-112 kernel: {7415}[Hardware Error]:   DIMM location: not present. DMI handle: 0x0000
```

故障确认及定位故障内存槽位

```bash
# grep "[0-9]" /sys/devices/system/edac/mc/mc*/csrow*/ch*_ce_count

/sys/devices/system/edac/mc/mc0/csrow0/ch0_ce_count:0
/sys/devices/system/edac/mc/mc0/csrow0/ch1_ce_count:0
/sys/devices/system/edac/mc/mc0/csrow1/ch0_ce_count:0
/sys/devices/system/edac/mc/mc0/csrow1/ch1_ce_count:0
/sys/devices/system/edac/mc/mc2/csrow0/ch0_ce_count:7836
/sys/devices/system/edac/mc/mc2/csrow0/ch1_ce_count:0
/sys/devices/system/edac/mc/mc2/csrow1/ch0_ce_count:0
/sys/devices/system/edac/mc/mc2/csrow1/ch1_ce_count:0
```

- `count`：不为 0 的行即代表存在内存错误
- `mc`: 第几个 CPU
- `csrow`：内存通道
- `ch*`：通道内的第几根内存

使用 edac 工具来检测服务器内存故障

对于 ECC,REG 这些带有纠错功能的内存故障检测是一件很头疼的事情，出现故障，还是可以连续运行几个月甚至几年，但如果运气不好，随时都会挂掉，好在 linux 中提供了一个 edac-utils 内存纠错诊断工具，可以用来检查服务器内存潜在的故障。

安装

```bash
dnf install -y libsysfs edac-utils
```

执行检测命令，可查看纠错提示如下

```bash
# edac-util -v

mc0: 0 Uncorrected Errors with no DIMM info
mc0: 0 Corrected Errors with no DIMM info
mc0: csrow0: 0 Uncorrected Errors
mc0: csrow0: CPU_SrcID#0_MC#0_Chan#0_DIMM#0: 0 Corrected Errors
mc0: csrow0: CPU_SrcID#0_MC#0_Chan#1_DIMM#0: 0 Corrected Errors
mc0: csrow1: 0 Uncorrected Errors
mc0: csrow1: CPU_SrcID#0_MC#0_Chan#0_DIMM#1: 0 Corrected Errors
mc0: csrow1: CPU_SrcID#0_MC#0_Chan#1_DIMM#1: 0 Corrected Errors
mc1: 0 Uncorrected Errors with no DIMM info
mc1: 0 Corrected Errors with no DIMM info
mc2: 0 Uncorrected Errors with no DIMM info
mc2: 0 Corrected Errors with no DIMM info
mc2: csrow0: 0 Uncorrected Errors
mc2: csrow0: CPU_SrcID#0_MC#2_Chan#0_DIMM#0: 7836 Corrected Errors
mc2: csrow0: CPU_SrcID#0_MC#2_Chan#1_DIMM#0: 0 Corrected Errors
mc2: csrow1: 0 Uncorrected Errors
mc2: csrow1: CPU_SrcID#0_MC#2_Chan#0_DIMM#1: 0 Corrected Errors
mc2: csrow1: CPU_SrcID#0_MC#2_Chan#1_DIMM#1: 0 Corrected Errors
mc3: 0 Uncorrected Errors with no DIMM info
mc3: 0 Corrected Errors with no DIMM info
```

其中

- `mc02` 表示 表示内存控制器 2
- `CPU_Src_ID#0` 表示源 CPU0
- `Channel#0`  表示通道 0
- `DIMM#0`  标示内存槽 0
- `Corrected Errors` 代表已经纠错的次数

## 其他

错误检测和检测(EDAC)单元是用于检测和更正从错误更正代码(ECC)内存错误的设备。通常，EDAC 选项的范围是从没有 ECC 检查对所有内存节点进行定期扫描以找出错误。EDAC 级别越高，BIOS 使用的时间就越长。这可能导致缺少关键事件期限。

要提高响应时间，请关闭 EDAC。如果无法做到这一点，将 EDAC 配置为最低功能级别。 		