## Linux 虚拟化方案

Libvirt、qemu 和 kvm 的组合提供了完整的虚拟化功能，它们是解决 Linux 虚拟化方案的重要部分。

![img](.assets/kvm-architecture.png)

### libvirt

官方：

- 官网：<https://libvirt.org/>

- GitHub Mirror：<https://github.com/libvirt/libvirt>

Libvirt 是一个开源项目，以守护进程的方式运行，管理虚拟化平台 (kvm、qemu、Xen、lxc、...)

通常使用 libvirt 提供的接口管理 kvm，图形化工具 virt-manager 就是调用 libvirt，管理远程或本地的 hypervisors；Libvirt 提供的 virsh 命令行工具，是主流的 hypervisor 命令行管理工具

### qemu

QEMU 是通用和开源的机器模拟器和虚拟化器。在作为虚拟化器的时候，以近乎原生的性能运行 kvm 和 Xen 虚拟机。

### kvm

KVM (Kernel-based Virtual Machine) 是基于硬件辅助的开源全虚拟化解决方案。它包括名为 `kvm.ko` 的通用内核模块、以及基于硬件的 (如基于 Intel 的 `kvm-intel.ko` 或基于 AMD 的 `kvm-adm.ko` 模块) 内核模块。KVM 加载这些模块，将 Linux 内核变成 hypervisor，从而实现虚拟化。

除了内核模块，KVM 中还包括 qemu-kvm。QEMU-KVM 是 kvm 团队针对 qemu 开发的、用于管理和创建虚拟机的工具。

通过 kvm 的 `/dev/kvm` 设备文件，应用程序可以执行 ioctl() 函数的系统调用。QEMU-KVM 使用 `/dev/kvm` 设备文件与 kvm 通信，并创建、初始化和管理虚拟机的 kernel-mode 上下文。

## 安装

### 检查 CPU 是否支持虚拟化

KVM 需要 CPU 虚拟化功能的支持，只能在支持虚拟化的 CPU 上运行，即具有 VT 功能的 Inter CPU 或具有 AMD-V 功能的 AMD CPU。

查看 cpu 是否开启虚拟化

```bash
> lscpu | grep Virtualization
Virtualization:                  AMD-V

> lscpu | grep Virtualization
Virtualization:                  VT-x
```

也执行以下命令，查看 CPU 是否支持虚拟化：

```bash
# Intel vmx
# AMD svm
> grep -E '(vmx|svm)' /proc/cpuinfo
# egrep -c '(vmx|svm)' /proc/cpuinfo

flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon nopl xtopology tsc_reliable nonstop_tsc cpuid pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch cpuid_fault invpcid_single pti ssbd ibrs ibpb stibp tpr_shadow vnmi ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 invpcid rdseed adx smap clflushopt xsaveopt xsavec xgetbv1 xsaves arat md_clear flush_l1d arch_capabilities
...
```

如果输出为空，表示 CPU 不支持虚拟化，或者该功能未启用。

要想启用 CPU 虚拟化功能，对于物理机，开机进入 BIOS，在 CPU 中找到高级设置，开启并保存退出。如果是在 VMware Workstations 这类用于学习的虚拟环境中，需要在虚拟机停机的状态下启用此功能，路径大概是 `设置 --> 硬件 --> 处理器`，勾选虚拟化引擎的选项

### 安装相关包

安装 libvirt 和 qemu 软件包

```bash
dnf install -y \
  qemu-kvm \
  libvirt virt-install virt-viewer \
  bridge-utils

# dnf group install -y "Virtualization Hypervisor"
```

相关软件：

- `virt-install` 通过 CLI 安装虚拟机
- `virt-viewer` 在 GUI 模式下执行 virt-install 命令后，会自动弹出 virt-viewer 窗口，进行引导安装
- `virt-manager` 在 GUI 模式下管理虚拟机 

检查是否满足安装需求：

```bash
> virt-host-validate qemu

  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : PASS
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : WARN (No ACPI DMAR table found, IOMMU either disabled in BIOS or not supported by this hardware platform)
  QEMU: Checking for secure guest support                                    : WARN (Unknown if this platform has Secure Guest support)
```

查看内核模块是否加载了 `kvm`

```bash
> lsmod | grep kvm
kvm_intel             385024  0
kvm                  1105920  1 kvm_intel
irqbypass              16384  1 kvm

> lsmod | grep kvm
kvm_amd               155648  0
kvm                  1105920  1 kvm_amd
irqbypass              16384  1 kvm
ccp                   118784  1 kvm_amd
```

### 常见问题处理

处理：`No ACPI DMAR table found, IOMMU either disabled in BIOS or not supported by this hardware platform`

需要先在 bios 上开启 intel iommu

处理：`IOMMU appears to be disabled in kernel. Add intel_iommu=on to kernel cmdline arguments`

```bash
vim /etc/default/grub
# 添加：intel_iommu=on
# GRUB_CMDLINE_LINUX="... intel_iommu=on iommu=pt"

# 重新生成 grub2 config 文件
> grub2-mkconfig -o /boot/grub2/grub.cfg

# 验证：
> dmesg | grep -e DMAR | grep -i iommu
```

`Unknown if this platform has Secure Guest support` 可以忽略

## 启动

### 启动 libvirtd

启动 libvirtd 服务，并将其设为开机启动：

```bash
systemctl enable libvirtd --now
 
systemctl status libvirtd
```

libvirtd 启动成功后，会创建名为 `virbr0` 的虚拟网卡：

```bash
> ifconfig virbr0
virbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        ether 52:54:00:69:fc:61  txqueuelen 1000  (Ethernet)
        RX packets 141555  bytes 10579268 (10.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 162294  bytes 256260353 (244.3 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

### 验证安装结果

通过 `virsh net-list` 和 `virsh list` 命令验证 kvm 虚拟化环境是否正确部署：

```bash
> virsh net-list
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes

> virsh list
 Id   Name   State
--------------------

```

以上输出，说明已成功部署 kvm 虚拟化环境
