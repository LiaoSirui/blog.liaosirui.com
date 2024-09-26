## BIOS

### Intel 超线程技术

Advanced -> CPU Configuration -> Hyper-Threading(All) -> Enable

- 全称：Intel Hyper-Threading
- 物理CPU核数：4个
- 逻辑CPU核数：物理CPU核数*2 = 8个
- 一个CPU可以跑两个线程，类似于1个CPU核变成了2个CPU核
- 通常会对程序有一个性能的提升，通常提升的范围大约在15%-30%之间，真实性能提升取决于具体的程序

### 硬件辅助虚拟化技术

Advanced -> CPU Configuration -> Intel Virtualization Technology -> Enable

为弥补x86处理器的虚拟化缺陷，市场的驱动催生了`VT-x`，Intel推出了基于x86架构的硬件辅助虚拟化技术(Intel Virtualization Technology, Intel VT)。

目前，Intel VT技术包含`CPU、内存和I/O`三方面的虚拟化技术。

CPU硬件辅助虚拟化技术，分为

- 对应安腾架构的VT-i(Intel Virtualization Technology for ltanium)

- 对应x86架构的VT-x(Intel Virtualization Technology for x86)

- AMD AMD-V

内存硬件辅助虚拟化技术包括EPT(Extended Page Table)技术

I/O硬件辅助虚拟化技术的代表 VT-d(Intel Virtualization Technology for Directed I/O)

###  x2apic

Advanced -> CPU Configuration -> X2APIC -> Enable

Advanced -> CPU Configuration -> X2APIC_OPT_OUT Flag -> Enable

x2apic为Intel提供的xAPIC增强版，针对中断寻址、APIC寄存器访问进行改进优化。在虚拟化环境下，x2APIC提供的APIC寄存器访问优化对于性能有明显改进

### 电源模式选项

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> Power Technology (能源技术)  -> Custom(调试)

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> Energy Performance Tuning (能源性能调节)   -> Disable

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> Performance BIAS Setting(性能偏差设置)  -> Performance(高性能)

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> Energy Efficient Turbo(节能涡轮)  -> Enable

关闭节能模式，打开性能模式

### CPU State Control

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> CPU C State Control   -> Package C State Limit -> C0/C1 state

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> CPU C State Control   -> CPU C3 Report -> Disable

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> CPU C State Control   -> CPU C6 Report -> Disable

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> CPU C State Control   -> Enhanced Halt State (C1E)   -> Disable

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> CPU C State Control   -> ACPI T-State   -> Disable

- C1E Support

C1E(Enhanced Halt State)增强型空闲电源管理状态转换，一种可以令CPU省电的功能，开启后CPU在低负载状态通过降低电压与倍频来达到节电的目的

- CPU C-State

CPU C-State是一项深度节能技术，其中C3、C6、C7的节能效果逐渐依次增强，但CPU恢复到正常工作状态的时间依次增加，设置C3 Report打开即支持C3节能，其他相同

- Package C State limit

C状态限制：如果限制到C0，C1E就不起作用；如果限制到C2，就不能进入C3更节能状态；默认是自动的，超频时可以设置为No Limit(不限制)

### EIST 自动降频

Advanced -> CPU Configuration -> Advanced Power Management Configuration -> CPU P State Control -> EIST (P-States) -> Disable

智能降频技术，它能够根据不同的系统工作量自动调节处理器的电压和频率，以减少耗电量和发热量。从而不需要大功率散热器散热，也不用担心长时间使用电脑会不稳定，而且更加节能。 EIST全称为“Enhanced Intel SpeedStep Technology”，是Intel开发的Intel公司专门为移动平台和服务器平台处理器开发的一种节电技术。

### VT-d

Advanced -> Chipset Configuration -> North Bridge -> IIO Configuration -> Intel Vt for Directed I/O (VT-d) -> Enable

I/O硬件辅助虚拟化技术的代表VT-d(Intel Virtualization Technology for Directed I/O)，是定向I/0虚拟化技术，开启了可以对虚拟机使用存储设备有提升

### Numa

Advanced -> ACPI Settings -> NUMA -> Enabled

## ESXi

- 更改电源策略

选择【管理】-【硬件】-【电源管理】-【更改策略】- 高性能

- 关闭内存交换

- 更改密码策略

选择“管理”选项卡——“高级设置”，找到“Security.AccountLockFailures”，然后右键选择“编辑选项“ 设置为 0

- 找到“VMkernel.Boot.hyperthreadingMitigationIntraVM”，鼠标右键选择“编辑设置”。设置为 False

## 参考文档

- <https://blog.csdn.net/z136370204/article/details/110794027>

- <https://o-my-chenjian.com/2018/03/22/VMware-Performance-optimization/#bios%E4%BC%98%E5%8C%96>
