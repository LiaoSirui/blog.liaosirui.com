## Linux RT 简介

Linux-RT 是指 Linux Real-Time（实时）的简称，它是针对实时性能优化的 Linux 内核版本。传统的 Linux 内核并不是专为实时性设计的，因此在一些对实时性要求较高的应用场景下，可能无法满足实时性要求。Linux-RT 通过对 Linux 内核进行调整和优化，以提供更可预测、更低延迟的实时性能。

Linux-RT 的主要特点和优势包括：

- 实时性能： Linux-RT 对内核进行了调整和优化，使其具有更可预测、更低延迟的实时性能。这对于需要实时响应的应用场景非常重要，如工业自动化、机器人控制、音视频处理等领域。
- 抢占性： Linux-RT 引入了抢占式调度（Preemptive Scheduling），允许内核中断正在执行的任务以执行更高优先级的任务。这可以降低任务响应时间，提高实时性能。
- 内核锁优化： Linux-RT 对内核中的锁机制进行了优化，减少了锁的竞争和持有时间，从而降低了内核的上下文切换延迟。
- 高分辨率计时器： Linux-RT 引入了高分辨率计时器（High Resolution Timer），提供微秒级的计时精度，更精确地控制任务执行时间。
- 优先级继承： Linux-RT 支持优先级继承（Priority Inheritance），避免了优先级反转问题，提高了实时任务的响应性能。

## 参考资料

- <https://blog.csdn.net/qq_42241500/article/details/136167651>

- <https://docs.redhat.com/zh-cn/documentation/red_hat_enterprise_linux_for_real_time/10/html/installing_rhel_for_real_time/configuring-kernel-rt-as-the-default-boot-kernel>