## OOM

OOM（Out Of Memory，简称 OOM）指系统内存已用完，在 linux 系统中，如果内存用完会导致系统无法正常工作，触发系统 panic 或者 OOM killer。

OOM killer 是 linux 内核的一个机制，该机制会监控那些占用内存过大的进程，尤其是短时间内消耗大量内存的进程，在系统的内存即将不够用时结束这些进程从而保障系统的整体可用性。

## OOM 相关参数

### `panic_on_oom`

panic_on_oom 参数是控制系统遇到 OOM 时如何反应的。当系统遇到 OOM 的时候，通常会有两种选择：

- 触发系统 panic，可能会出现频繁宕机的情况。
- 选择一个或者几个进程，触发 OOM killer，结束选中的进程，释放内存，让系统保持整体可用。

可以通过以下命令查看参数取值：`cat /proc/sys/vm/panic_on_oom` 或者 `sysctl -a | grep panic_on_oom`

- 值为 0：内存不足时，触发 OOM killer。
- 值为 1：内存不足时，根据具体情况可能发生 kernel panic，也可能触发 OOM killer。
- 值为 2：内存不足时，强制触发系统 panic，导致系统重启。

例如将参数设置为 0，可用以下两种方式：

- 临时配置，立即生效，但重启后恢复成默认值。`sysctl -w vm.panic_on_oom=0`

- 持久化配置，系统重启仍生效。执行命令 `vim /etc/sysctl.conf`，在该文件中添加一行 `vm.panic_on_oom =0`，再执行命令 `sysctl –p` 或重启系统后生效。

### `oom_kill_allocating_task`

当系统选择触发 OOM killer，试图结束某些进程时，oom_kill_allocating_task 参数会控制选择哪些进程，有以下两种选择：

- 触发 OOM 的进程。
- oom_score 得分最高的进程。

可以通过以下命令查看参数取值：`cat /proc/sys/vm/oom_kill_allocating_task` 或者 `sysctl -a | grep oom_kill_allocating_task`

- 值为 0：选择 oom_score 得分最高的进程。
- 值为非 0：选择触发 OOM 的进程。

例如将该参数设置成 1，可用以下两种方式：

- 临时配置，立即生效，但重启后恢复成默认值。`sysctl -w vm.oom_kill_allocating_task=1`

- 持久化配置，系统重启仍生效。执行命令 `vim /etc/sysctl.conf`，在该文件中添加一行 `vm.oom_kill_allocating_task=1`，再执行命令 `sysctl –p` 或重启系统后生效。

### `oom_score`

指进程的得分，主要有两部分组成：

- 系统打分，主要是根据该进程的内存使用情况由系统自动计算。
- 用户打分，也就是 oom_score_adj，可以自定义。

可以通过调整 oom_score_adj 的值进而调整一个进程最终的得分。通过以下命令查看参数取值：`cat /proc/进程id/oom_score_adj`

- 值为 0：不调整 oom_score。
- 值为负值：在实际打分值上减去一个折扣。
- 值为正值：增加该进程的 oom_score。

例如将进程 id 为 2939 的进程 oom_score_adj 参数值设置为 1000，可用以下命令：`echo 1000 > /proc/2939/oom_score_adj`

### `oom_dump_tasks`

oom_dump_tasks 参数控制 OOM 发生时是否记录系统的进程信息和 OOM killer 信息。

例如 dump 系统中所有的用户空间进程关于内存方面的一些信息，包括：进程标识信息、该进程使用的内存信息、该进程的页表信息等，这些信息有助于了解出现 OOM 的原因。

可以通过以下命令查看参数取值：`cat /proc/sys/vm/oom_dump_tasks` 或者 `sysctl -a | grep oom_dump_tasks`

- 值为 0：OOM 发生时不会打印相关信息。
- 值为非 0：以下三种情况会调用 dump_tasks 打印系统中所有 task 的内存状况。
  - 由于 OOM 导致 kernel panic。
  - 没有找到需要结束的进程。
  - 找到进程并将其结束的时候。

例如将该参数设置成 0，可用以下两种方式：

- 临时配置，立即生效，但重启后恢复成默认值。`sysctl –w vm.oom_dump_tasks=0`
- 持久化配置，系统重启仍生效。执行命令 `vim /etc/sysctl.conf`，在该文件中添加一行 `vm.oom_dump_tasks=0`，再执行命令 `sysctl –p` 或重启系统后生效。