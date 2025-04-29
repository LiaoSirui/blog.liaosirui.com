## `cpufreq`子系统

- `cpufreq`子系统负责在运行时对 CPU 频率和电压的动态调整，以达到性能和功耗的平衡，它也叫`DVFS(Dynamic Voltage Frequency Scaling)`
- `DVFS`原理：CMOS 电路中功耗与电压的平方成正比，与频率也成正比。此外，频率越高，性能也越强，相应的能耗就增大（需要 Trade-off）

### 原理：CPU performance/frequency scaling

处理器硬件有接口暴露给内核，可以设置 CPU 的运行 frequency/voltage，或者说选择不同的 **`P-state`**.

一般来说，

- 内核调度器会在一些重要事件发生时（例如新建或销毁进程）， 或者定期（every iteration of the scheduler tick）回调 cpufreq update 方法，更新 cpufreq 状态。
- cpufreq 根据状态状态信息，可以动态调整 p-state 级别。

这个功能称为 CPU performance scaling or CPU frequency scaling

### 架构：governor+driver

`cpufreq framework`，提供驱动（`cpufreq driver`）与策略（`cpufreq governor`）、`cpufreq core` 来对驱动和策略进行管理

## cpufreq 的五种模式

cpufreq 是一个动态调整 cpu 频率的模块，系统启动时生成一个文件夹 `/sys/devices/system/cpu/cpu0/cpufreq/`，里面有几个文件，其中 scaling_min_freq 代表最低频率，scaling_max_freq 代表最高频率，scalin_governor 代表 cpu 频率调整模式，用它来控制 CPU 频率

```bash
cd /sys/devices/system/cpu/cpu0/cpufreq/

affected_cpus
bios_limit
cpuinfo_cur_freq
cpuinfo_max_freq
cpuinfo_min_freq
cpuinfo_transition_latency
freqdomain_cpus
related_cpus
scaling_available_frequencies
scaling_available_governors
scaling_cur_freq
scaling_driver
scaling_governor
scaling_max_freq
scaling_min_freq
scaling_setspeed

# 查看当前的调节器
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
conservative

# 查看频率信息
cpupower frequency-info

analyzing CPU 0:
  driver: acpi-cpufreq
  CPUs which run at the same hardware frequency: 0
  CPUs which need to have their frequency coordinated by software: 0
  maximum transition latency: 10.0 us
  hardware limits: 800 MHz - 2.10 GHz
  available frequency steps:  2.10 GHz, 2.10 GHz, 2.00 GHz, 1.90 GHz, 1.80 GHz, 1.70 GHz, 1.60 GHz, 1.50 GHz, 1.40 GHz, 1.30 GHz, 1.20 GHz, 1.10 GHz, 1000 MHz, 900 MHz, 800 MHz
  available cpufreq governors: conservative userspace powersave ondemand performance
  current policy: frequency should be within 800 MHz and 2.10 GHz.
                  The governor "performance" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 2.10 GHz (asserted by call to kernel)
  boost state support:
    Supported: yes
    Active: yes
```

1. performance: 顾名思义只注重效率，将 CPU 频率固定工作在其支持的最高运行频率上，而不动态调节。
2. Userspace: 最早的 cpufreq 子系统通过 userspace governor 为用户提供了这种灵活性。系统将变频策略的决策权交给了用户态应用程序，并提供了相应的接口供用户态应用程序调节 CPU 运行频率使用。也就是长期以来都在用的那个模式。可以通过手动编辑配置文件进行配置
3. powersave: 将 CPU 频率设置为最低的所谓 “省电” 模式，CPU 会固定工作在其支持的最低运行频率上。因此这两种 governors 都属于静态 governor，即在使用它们时 CPU 的运行频率不会根据系统运行时负载的变化动态作出调整。这两种 governors 对应的是两种极端的应用场景，使用 performance governor 是对系统高性能的最大追求，而使用 powersave governor 则是对系统低功耗的最大追求。
4. ondemand: 按需快速动态调整 CPU 频率， 一有 cpu 计算量的任务，就会立即达到最大频率运行，等执行完毕就立即回到最低频率；ondemand：userspace 是内核态的检测，用户态调整，效率低。而 ondemand 正是人们长期以来希望看到的一个完全在内核态下工作并且能够以更加细粒度的时间间隔对系统负载情况进行采样分析的 governor。 在 ondemand governor 监测到系统负载超过 up_threshold 所设定的百分比时，说明用户当前需要 CPU 提供更强大的处理能力，因此 ondemand governor 会将 CPU 设置在最高频率上运行。但是当 ondemand governor 监测到系统负载下降，可以降低 CPU 的运行频率时，到底应该降低到哪个频率呢？ ondemand governor 的最初实现是在可选的频率范围内调低至下一个可用频率，例如 CPU 支持三个可选频率，分别为 1.67GHz、1.33GHz 和 1GHz ，如果 CPU 运行在 1.67GHz 时 ondemand governor 发现可以降低运行频率，那么 1.33GHz 将被选作降频的目标频率。
5. conservative: 与 ondemand 不同，平滑地调整 CPU 频率，频率的升降是渐变式的，会自动在频率上下限调整，和 ondemand 的区别在于它会按需分配频率，而不是一味追求最高频率；

## 参考资料

- <https://blog.51cto.com/u_11529070/9175151>
- <https://docs.kernel.org/6.0/translations/zh_CN/cpu-freq/cpufreq-stats.html>
- <https://www.cnblogs.com/LoyenWang/p/11385811.html>
- <https://huataihuang.gitbooks.io/cloud-atlas/content/os/linux/kernel/cpu/acpi_cpufreq.html>
- <https://blog.csdn.net/zhouhuaooo/article/details/127419771>