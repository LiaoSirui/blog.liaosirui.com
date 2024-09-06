## BCC 简介

BCC: Toolkit and library for efficient BPF-based kernel tracing

BCC 是一个基于 eBPF 的高效跟踪检测内核、运行程序的工具，并且包含了须有有用的命令行工具和示例程序

BCC减轻了使用 C 语言编写 eBPF 程序的难度，它包含了一个 LLVM 之上的包裹层，前端使用 Python 和 Lua

它也提供了一个高层的库可以直接整合进应用。它适用于许多任务，包括性能分析和网络流量控制

BCC给出的常见工具：

![img](.assets/BCC%E7%AE%80%E4%BB%8B/bcc_tracing_tools_2019.20c5cdb8.png)



## 入门示例

### 开发环境准备

安装 eBPF 开发依赖：

```bash
dnf --enablerepo=crb install -y \
    bpftrace \
    bpftool \
    libbpf-devel elfutils-libelf-devel \
    bcc-tools bcc-devel
```

### 开发 eBPF 程序

先写一下 c 的 helloworld 函数，这个是给 ebpf 内核态使用的。

```c
// hello.c
int hello_world(void *ctx)
{
    bpf_trace_printk("Hello, World!");
    return 0;
}
```

再写一个用户态的调用函数，用 python，这里会依赖 bcc 库

```python
# hello.py
#!/usr/bin/env python3
# 1) import bcc library
from bcc import BPF
# 2) load BPF program
b = BPF(src_file="hello.c")
# 3) attach kprobe
b.attach_kprobe(event="do_sys_open", fn_name="hello_world")
# 4) read and print /sys/kernel/debug/tracing/trace_pipe
b.trace_print()
```

### eBPF 的开发和执行过程

![img](.assets/image-20230222170839754.png)

- 第一步，使用 C 语言开发一个 eBPF 程序；
- 第二步，借助 LLVM 把 eBPF 程序编译成 BPF 字节码；
- 第三步，通过 bpf 系统调用，把 BPF 字节码提交给内核；
- 第四步，内核验证并运行 BPF 字节码，并把相应的状态保存到 BPF 映射中；
- 第五步，用户程序通过 BPF 映射查询 BPF 字节码的运行状态。

Helloworld 借助了 BCC（BPF Compiler Collection）进行编译和调用。

BCC 是一个 BPF 编译器集合，包含了用于构建 BPF 程序的编程框架和库，并提供了大量可以直接使用的工具。

使用 BCC 的好处是，它把上述的 eBPF 执行过程通过内置框架抽象了起来，并提供了 Python、C++ 等编程语言接口。这样，你就可以直接通过 Python 语言去跟 eBPF 的各种事件和数据进行交互。
