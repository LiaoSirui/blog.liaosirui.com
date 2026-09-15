## libbpf 简介

`libbpf`是内核提供的一个功能库

`eBPF`程序的运行流程如图所示：

![libbpf_ebpf_0](.assets/libbpf简介/libbpf_ebpf_0.png)

- 生成`eBPF`程序字节码，字节码最终被内核中的「虚拟机」执行
- 通过系统调用加载`eBPF`字节码到内核中，将`eBPF`程序`attach`到各个事件、函数
- 创建`map`，用于在内核态与用户态进行数据交互
- 「事件」、`TP`点触发时，调用`attach`的`eBPF`字节码并执行其功能

## 示例

统计一段时间中`syscall`调用次数，项目文件结构如下：

- `syscall_count_kern.c`为`eBPF`程序的`c`代码，使用`clang`编译为`eBPF`字节码
- `syscall_count_user.cpp`为用户态程序，用于调用`libbpf`加载`eBPF`字节码

### eBPF 字节码生成

字节码生成有多种方式：

- 手动编写字节码（手写汇编指令），使用`libbpf`中的内存加载模式
- 编写`c`代码，由`clang`生成，使用`libbpf`解析`elf`文件获取相关字节码信息
- 一些其他工具能够解析脚本语言生成字节码（`bpftrace`）

使用`clang`进行编译，创建`eBPF`程序：

```c
#include <asm/types.h>
#include <linux/types.h>

#include <bpf/bpf_helpers.h>
#include <linux/bpf.h>

// SEC 宏会将此字符串放到一个 elf 文件中的独立段里面供加载器检查
char LICENSE[] SEC("license") = "Dual BSD/GPL";

int my_pid = 0;

// 此处使用的 tracepoint，在每次进入 write 系统调用的时候触发
SEC("tp/syscalls/sys_enter_write")
int handle_tp(void *ctx) {
  int pid = bpf_get_current_pid_tgid() >> 32;

  if (pid != my_pid)
    return 0;
  // 可 cat /sys/kernel/debug/tracing/trace 查看调试信息
  bpf_printk("BPF triggered from PID %d.\n", pid);
  return 0;
}


```

生成 `vmlinux.h` 文件：

```bash
# 拷贝到工程目录下
bpftool btf dump file -/sys/kernel/btf/vmlinux format c > ./vmlinux.h
```

编译生成字节码（注意要使用`-g -O2`否则加载时会报错）

```bash
clang -g -O2 -target bpf -D__TARGET_ARCH_x86 \
  -I/usr/src/kernels/$(uname -r)/include/uapi/ \
  -I/usr/src/kernels/$(uname -r)/include/ \
  -I/usr/include/bpf/ -c minimal.bpf.c -o minimal.bpf.o
```

转换为 skel

```bash
bpftool gen skeleton minimal.bpf.o > minimal.skel.h
```

### libbpf 库使用

使用`libbpf`库加载`eBPF`程序代码如下：

```cpp
#include "minimal.skel.h" // 这就是上一步生成的skeleton，minimal的“框架”
#include <bpf/libbpf.h>
#include <stdio.h>
#include <sys/resource.h> // rlimit使用
#include <unistd.h>

int main(int argc, char **argv) {
  struct minimal_bpf *skel; // bpftool生成到skel文件中，格式都是xxx_bpf。
  int err;

  struct rlimit rlim = {
      .rlim_cur = 512UL << 20,
      .rlim_max = 512UL << 20,
  };
  // bpf程序需要加载到lock memory中，因此需要将本进程的lock mem配大些
  if (setrlimit(RLIMIT_MEMLOCK, &rlim)) {
    fprintf(stderr, "set rlimit error!\n");
    return 1;
  }
  // 第一步，打开bpf文件，返回指向xxx_bpf的指针（在.skel中定义）
  skel = minimal_bpf__open();
  if (!skel) {
    fprintf(stderr, "Failed to open BPF skeleton\n");
    return 1;
  }

  // 第二步，加载及校验bpf程序
  err = minimal_bpf__load(skel);
  if (err) {
    fprintf(stderr, "Failed to load and verify BPF skeleton\n");
    goto cleanup;
  }

  // 第三步，附加到指定的hook点
  err = minimal_bpf__attach(skel);
  if (err) {
    fprintf(stderr, "Failed to attach BPF skeleton\n");
    goto cleanup;
  }

  printf("Successfully started! Please run `sudo cat "
         "/sys/kernel/debug/tracing/trace_pipe` "
         "to see output of the BPF programs.\n");

  for (;;) {
    /* trigger our BPF program */
    fprintf(stderr, ".");
    sleep(1);
  }
cleanup:
  minimal_bpf__destroy(skel);
  return -err;
}

```

编译用户态程序

```bash
gcc -I/usr/src/kernels/$(uname -r)/include/uapi/ \
  -I/usr/src/kernels/$(uname -r)/include/ \
  -I/usr/include/bpf/ -W -c minimal.c -o minimal.o
```

链接成为可执行程序

```bash
gcc minimal.o -lbpf -lelf -lz -o minimal
```

