## tuned 简介

Linux 提供了一种简单的系统调优方法，那就是通过 tuned 服务。

其中 tuned 是服务端程序，用来监控和收集系统各个组件的数据，并依据数据提供的信息动态调整系统设置，达到动态优化系统的目的。tuned-adm 是客户端程序，用来和 tuned 打交道，用命令行的方式管理和配置 tuned，tuned-adm 提供了一些预先配置的优化方案可供直接使用，比如：笔记本、虚拟机、存储服务器等。

安装 tuned 包：

```bash
dnf install -y tuned
```

将 tuned 服务设置为开机启动，并启动 tuned 服务：

```bash
systemctl enable --now tuned
```

执行 `dnf  info tuned` 命令，可以看到该包的介绍：它声称自己是 "动态调整系统设置的守护进程。通过定期监控几个系统组件的使用情况来实现这一点。根据这些信息，组件将进入更低或更高的节能模式，以适应当前的使用情况。目前只实现了以太网网络和 ATA 硬盘设备。"

```bash
> dnf  info tuned
Last metadata expiration check: 3:10:03 ago on Mon Feb 13 08:17:32 2023.
Available Packages
Name         : tuned
Version      : 2.19.0
Release      : 1.el9
Architecture : noarch
Size         : 294 k
Source       : tuned-2.19.0-1.el9.src.rpm
Repository   : baseos
Summary      : A dynamic adaptive system tuning daemon
URL          : http://www.tuned-project.org/
License      : GPLv2+
Description  : The tuned package contains a daemon that tunes system settings dynamically.
             : It does so by monitoring the usage of several system components periodically.
             : Based on that information components will then be put into lower or higher
             : power saving modes to adapt to the current usage. Currently only ethernet
             : network and ATA harddisk devices are implemented.
```

## tuned-adm

可以通过 `tuned-adm` 命令与 tuned 守护进程交互。

tuned-adm 的可用选项和配置文件列表：

```bash
> tuned-adm
usage: tuned-adm [-h] [--version] [--debug] [--async] [--timeout TIMEOUT] [--loglevel LOGLEVEL] {list,active,off,profile,profile_info,recommend,verify,auto_profile,profile_mode} ...
```

tuned-adm 选项可以列出、禁用、提取某个 profile 的信息、获取 profile 的使用建议、验证设置有没有被修改、自动选择 profile 等。

tuned 的 profile 存储在 `/usr/lib/tuned/` 目录（不同版本的 tuned 可能包含不同的 profile 或配置）。

常用的 profile 介绍：

- `virtual-host`：将服务器作为虚拟机的宿主机进行优化。
- `virtual-guest`：将服务器作为运行在 “virtual-host” 之上的虚拟机进行优化。
- `powersaving`：尽量减少电力消耗。
- `balanced`：在节能和性能之间进行平衡。
- `desktop`：基于平衡的、更好的应用程序响应能力。
- `throughput-performance`：最大吞吐量。
- `latency-performance`：减少延迟并提供性能。
- `network-throughput`：基于 `throughput-performance`，但是有额外的网络调优。

如上所述，每个 profile 都是一种权衡：在提高性能时需要更多的功耗，或者提高吞吐量也可能会增加延迟。

```bash
> tuned-adm list
Available profiles:
- accelerator-performance     - Throughput performance based tuning with disabled higher latency STOP states
- balanced                    - General non-specialized tuned profile
- desktop                     - Optimize for the desktop use-case
- hpc-compute                 - Optimize for HPC compute workloads
- intel-sst                   - Configure for Intel Speed Select Base Frequency
- latency-performance         - Optimize for deterministic performance at the cost of increased power consumption
- network-latency             - Optimize for deterministic performance at the cost of increased power consumption, focused on low latency network performance
- network-throughput          - Optimize for streaming network throughput, generally only necessary on older CPUs or 40G+ networks
- optimize-serial-console     - Optimize for serial console use.
- powersave                   - Optimize for low power consumption
- throughput-performance      - Broadly applicable tuning that provides excellent performance across a variety of common server workloads
- virtual-guest               - Optimize for running inside a virtual guest
- virtual-host                - Optimize for running KVM guests
Current active profile: throughput-performance
```

最后一行列出了当前激活的 profile 为 `throughput-performance`，也可以通过 `tuned-adm active` 命令查看：

```bash
> tuned-adm active
Current active profile: throughput-performance
```

启用 `latency-performance` profile：

```bash
# 激活 latency-performance profile
> tuned-adm profile latency-performance

# 验证激活结果
> tuned-adm active
Current active profile: latency-performance
```

特意使用 `sysctl -w vm.swappiness=69` 命令修改系统配置：

```bash
# 查看 vm.swappiness 的当前值
> sysctl -a | grep swappiness
vm.swappiness = 0

# 修改 vm.swappiness 的值
> sysctl -w vm.swappiness=69
vm.swappiness = 69
```

执行 `tuned-adm verify` 命令，验证 profile 的配置是否有变化：

```bash
# 检查 profile 配置是否有变化
> tuned-adm verify
Verification failed, current system settings differ from the preset profile.
You can mostly fix this by restarting the TuneD daemon, e.g.:
  systemctl restart tuned
or
  service tuned restart
Sometimes (if some plugins like bootloader are used) a reboot may be required.
See TuneD log file ('/var/log/tuned/tuned.log') for details.
```

系统设置与预设值不一样，可以重启 tuned 守护进程恢复配置。

默认情况下，动态调优是被禁用的，可以在配置文件 `/etc/tuned/tuned-main.conf` 中查看。

- `dynamic_tuning` 的值是布尔值，0 或 False 时，禁用动态调优；
- 1 或 True 时，启动动态调优。

此外，Cockpit 也提供了修改 profile 的界面。

## 自定义 tuned profile

Tuned profiles 是如何创建及工作的呢？

以 `latency-performance` 作为示例，通过 `/usr/lib/tuned/latency-performance/tuned.conf` 来讨论这个问题。

```bash
> cat /usr/lib/tuned/latency-performance/tuned.conf  |grep -vi '^#' |grep -vi '^$'

[main]
summary=Optimize for deterministic performance at the cost of increased power consumption
[cpu]
force_latency=cstate.id_no_zero:1|3
governor=performance
energy_perf_bias=performance
min_perf_pct=100
[sysctl]
vm.dirty_ratio=10
vm.dirty_background_ratio=3
vm.swappiness=10
```

`man tuned.conf` 命令介绍了文件的语法，它是 ini 格式的，即一个按类别组织的文件，用方括号和等号赋值的键值对表示。

### main 部分

`[main]` 部分定义了 profile 的摘要。

可以在 `[main]` 中定义 `include`，根据现有的 profile 创建新的 profile。

在这种情况下，profile 文件中的参数有冲突时，使用新 profile 中的参数。其他部分则取决于安装的插件。

执行以下命令，查看可用的插件：

```bash
> rpm -ql tuned | grep 'plugins/plugin_.*.py$'
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_audio.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_bootloader.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_cpu.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_disk.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_eeepc_she.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_irqbalance.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_modules.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_mounts.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_net.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_rtentsk.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_scheduler.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_script.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_scsi_host.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_selinux.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_service.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_sysctl.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_sysfs.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_systemd.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_usb.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_video.py
/usr/lib/python3.9/site-packages/tuned/plugins/plugin_vm.py
```

如果相同类型的插件试图配置同一个设备，也就是它们之间有冲突时，`replace=1` 表示最后定义的插件将取代之前定义的插件。

### cpu 部分

对于 CPU，它设置了性能调节器 (`governor=performance`)，可以通过 `cat /sys/devices/system/cpu/*/cpufreq/scaling_governor` 对系统中可用的 CPU 进行检查 (如果支持)。在一些系统中，路径可能不同，甚至不存在。可以通过执行 `cpupower frequency-info - governors` 查看是否支持，其中 powerave 和 performance 是最常见的。

```bash
> cpupower frequency-info - governors
analyzing CPU 0:
  driver: acpi-cpufreq
  CPUs which run at the same hardware frequency: 0
  CPUs which need to have their frequency coordinated by software: 0
  maximum transition latency:  Cannot determine or is not supported.
  hardware limits: 2.20 GHz - 3.40 GHz
  available frequency steps:  3.40 GHz, 2.80 GHz, 2.20 GHz
  available cpufreq governors: conservative ondemand userspace powersave performance schedutil
  current policy: frequency should be within 2.20 GHz and 3.40 GHz.
                  The governor "performance" may decide which speed to use
                  within this range.
  current CPU frequency: 3.40 GHz (asserted by call to hardware)
  boost state support:
    Supported: yes
    Active: yes
    Boost States: 0
    Total States: 3
    Pstate-P0:  3400MHz
    Pstate-P1:  2800MHz
    Pstate-P2:  2200MHz
```

type 关键字定义使用的插件，这部分的名称是任意的自定义名称，通过 device 关键字指定设备。

例如，主机上有多块磁盘：sda 和用于数据备份的 sdb，为它们定义不同设置的部分：

```ini
[main_disk]
type= disk
devices=sda
readahead=>4096
[backup_disk]
type=disk
devices=!sda
spindown=1
```

名为 sda 的磁盘被配置为 readahead (预加载数据到缓存中)；其他数据磁盘设置为节能模式，在不使用时减少噪音和功耗。

### sysctl 部分

另一个有趣的插件是 sysctl，被多个 profile 使用，它以 sysctl 命令的方式定义设置。

正因为如此，可以做很多设置：定义传输控制协议 (TCP) 窗口大小以优化网络、虚拟内存管理、transparent huge pages 等。

### 集成关系

Tuned profile 可以从父级继承设置，因此不必重头定义 profile，而是在可用的 profile 中找到接近的，检查其中的配置，将其应用到自定义的 profile 中。

可以使用以下命令查看系统中定义的 profiles 部分：

```bash
> cat /usr/lib/tuned/*/tuned.conf | grep -v '^#' | grep '^\[' | sort -u
[audio]
[bootloader]
[cpu]
[disk]
[eeepc_she]
[main]
[modules]
[net]
[scheduler]
[script]
[scsi_host]
[sysctl.thunderx]
[sysctl]
[variables]
[video]
[vm.thunderx]
[vm]
```

可以看到，涉及了很多领域。

script 部分定义了一个由 `powerave profile` 使用的 shell 脚本；variables 部分由 `throughput-performance` 用来定义正则表达式，以便根据 CPU 进行匹配和应用设置。

自定义 profile 时，创建 `/etc/tuned/newprofile/` 目录 (newprofile 应改为自定义的 profile 名称)，在该目录下必须创建 `tuned.conf` 文件，文件中包含 `[main]` 部分和插件部分。比较简单的方式是复制 `/usr/lib/tuned/$profilename/` 中的文件到 `/etc/tuned/newprofile/` 目录中。

Profile 创建完成后，就可以使用 `tuned-adm profile newprofile` 命令启用这个 profile 了。