## oomd

在 5.x 内核中，当内存使用水位持续非常高的场景下，相比 3.10 低版本内核 5.x 内核会更多的尝试去回收内存而不是尽早触发 oom，所以这种场景下回收内存行为有比较大的概率会导致磁盘压力升高，因为大量 cache 会落盘，但由于进程持续运行会将进程的二进制文件持续读取到内存中，最终导致的现象就是内存持续回收，进程持续读二进制数据到内存，CPU 忙于回收内存和读取数据，磁盘的读 IO 也持续跑满，GuestOS 出现夯机。

- <https://github.com/facebookincubator/oomd>
- oomd 提供了多种监控系统压力的方式，主要是内存和 IO 维度：<https://github.com/facebookincubator/oomd/blob/main/docs/core_plugins.md>

## systemd-oomd

`systemd-oomd` 是一个用户空间内存不足（Out-Of-Memory, OOM）守护进程，用于在系统内存严重不足或压力过大时，主动终止占用过多资源的进程来保护系统

- 基于内存压力触发：它会监控系统或特定控制组（cgroup v2）的内存压力（Memory Pressure），在 Linux 内核传统的 OOM 杀手触发之前先行介入。
- 用户空间管理：代码源自 Facebook 的 `oomd` 工具，能够利用 `systemd` 的层级结构，对用户会话或特定服务切片进行精细化管理。
- 可配置策略：允许管理员设定阈值（如内存压力百分比和持续时间），当超出配额时按规则杀掉对应的进程组。

## 使用

测试代码

```python
import os
import sys
import gc
import time

def allocate_large_memory(size_in_mb):
    chunk_size = 4 * 1024  # 4KB
    total_size_in_bytes = size_in_mb * 1024 * 1024
    large_memory_chunks = []

    for _ in range(total_size_in_bytes // chunk_size):
        chunk = bytearray(chunk_size)
        large_memory_chunks.append(chunk)

    remaining_bytes = total_size_in_bytes % chunk_size
    if remaining_bytes > 0:
        last_chunk = bytearray(remaining_bytes)
        large_memory_chunks.append(last_chunk)

    gc.disable()
    return large_memory_chunks

def set_oom_adj(pid):
    print("Setting oom_adj for pid %d..." % pid)
    cmd = "echo -17 > /proc/%d/oom_adj" % pid
    ret = os.system(cmd)
    if ret != 0:
        return ret
    return 0

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: mem.py [mem_size(mb)].")
        exit(0)

    pid = os.getpid()
    ret = set_oom_adj(pid)
    if ret == 0:
        size_in_mb = int(sys.argv[1])
        large_memory_chunks = allocate_large_memory(size_in_mb)

        total_allocated_size = sum(len(chunk) for chunk in large_memory_chunks) / (1024 * 1024)
        print(f"Allocated {total_allocated_size:.2f}MB of memory using 4KB chunks.")

        time.sleep(1000)
    else:
        print("Error setting oom_adj...")
```



## K8s 上使用

不希望把资源浪费在内存颠簸/垃圾回收导致的 Trash/Stall 上，想要提前、果断地干掉引发内存压力的容器，结合 `systemd-oomd` 的 PSI（Pressure Stall Information）机制

传统的内核 OOM 只有在内存彻底耗尽（Absolute OOM）时才会触发，而此时系统往往已经因为频繁的 Page Cache 换入换出（Thrashing） 导致 CPU 飙升、I/O 死锁，整个节点陷入卡死状态。利用 PSI，我们可以在系统还没死透、但容器已经开始 “痛苦挣扎” 时，提前将其 kill。

Kubernetes 会把 Pod 按照服务质量（QoS）分为 `kubepods-besteffort.slice` 和 `kubepods-burstable.slice`。我们可以利用 systemd 的配置覆盖（Override）机制，让 `systemd-oomd` 仅对容器切片进行压力监控。

按需进行设置

- `/etc/systemd/system/kubepods.slice.d/override.conf`

- `/etc/systemd/system/kubepods-besteffort.slice.d/override.conf`
- `/etc/systemd/system/kubepods-burstable.slice.d/override.conf` 有 Request 但 Limit 较高的 Pod

创建或编辑 `/etc/systemd/system/kubepods.slice.d/override.conf`：

```bash
[Slice]
# 开启该 Cgroup 切片的内存 PSI 监控
ManagedOOMMemoryPressure=kill
# 当该切片的内存压力（Memory Pressure）在一定时间内持续超过阈值时触发
ManagedOOMMemoryPressureLimit=80%

# 允许 systemd-oomd 基于当前切片的压力进行清理
# systemd-oomd 会尝试寻找该 slice 下压力最大的子 cgroup 并将其杀掉，而不是扩大到整个系统

```

为了防止容器的内存压力被 `systemd-oomd` 错误地归咎于管理进程（如 `kubelet` 或 `containerd`）必须显式保护它们。

为 Kubelet 创建 `/etc/systemd/system/kubelet.service.d/oomd-protect.conf`：

```ini
[Service]
ManagedOOMMemoryPressure=avoid
ManagedOOMSwapPressure=avoid

```

为 Containerd 创建 `/etc/systemd/system/containerd.service.d/oomd-protect.conf`：

```ini
[Service]
ManagedOOMMemoryPressure=avoid
ManagedOOMSwapPressure=avoid

```

## 参考资料

- <https://developer.volcengine.com/articles/7383944273697341466>
