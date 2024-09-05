从`proc`文件系统读取内存指标：`/proc/meminfo`、`/proc/vmstat`等等

`/proc/meminfo`，`/proc/vmstat` 没有容器化，这意味着他们不是 cgroup-aware，将始终显示来自主机系统（物理机或虚拟机）的内存编号作为一个整体，这对现代 Linux 容器（Heroku、Docker 等）毫无用处。容器内的进程不能依赖`free`,`top`和其他进程来确定它们必须使用多少内存；它们受到 cgroup 施加的限制，并且不能使用主机系统中的所有可用内存。

要么是一个用于 proc 的自定义挂载选项

```
mount -t proc -o meminfo-from-cgroup none /path/to/container/proc
```

https://fabiokung.com/2014/03/13/memory-inside-linux-containers/

https://shuheikagawa.com/blog/2017/05/27/memory-usage/