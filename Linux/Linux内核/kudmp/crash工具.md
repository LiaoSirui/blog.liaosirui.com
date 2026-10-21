## crash 简介

crash 是一款可用来离线分析 linux 内核转存文件的工具，它整合了部分 gdb 的功能，可以查看堆栈、dmesg 日志、内核数据结构、反汇编等等，功能非常强大。crash 可支持多种工具生成的转存文件格式，例如 kdump、netdump、diskdump 等，而且还可以分析虚拟机 Xen 和 Kvm 上生成的内核转存文件

crash 与 linux 内核紧密耦合，需要与 linux 内核匹配。如果你的内核版本较新，crash 很可能无法解析，可以尝试安装最新的 crash 工具

使用 crash 来调试 vmcore，至少需要两个参数：

- 未压缩的内核映像文件 vmlinux。认位于 `/usr/lib/debug/lib/modules/$(uname -r)/vmlinux`，由内核调试信息包提供
- 内存转储文件 vmcore，由 kdump 或 sysdump 转存的内核奔溃现场快照

（1）安装 kernel-debug

```bash
# 提供调试头文件
dnf install -y --enablerepo="base-debuginfo" install kernel-debuginfo
```

离线安装 debug-info

可以从 <https://kojidev.rockylinux.org/koji/packageinfo?packageID=202> 获取

```bash
https://kojidev.rockylinux.org/kojifiles/packages/kernel/4.18.0/425.3.1.el8/x86_64/kernel-debuginfo-4.18.0-425.3.1.el8.x86_64.rpm

https://kojidev.rockylinux.org/kojifiles/packages/kernel/4.18.0/425.3.1.el8/x86_64/kernel-debuginfo-common-x86_64-4.18.0-425.3.1.el8.x86_64.rpm
```

（2）进入 core 文件所在路径， 执行如下命令：

```bash
crash vmcore /usr/lib/debug/lib/modules/<对应内核调试文件>/vmlinux
```

就以触发宕机的 CPU 上当时运行的进程为例

```bash
task -R stack
```

使用 mach 指令获取内核栈的大小

```bash
mach | grep SIZE
```

上面`KERNEL STACK SIZE`表示的就是内核栈的大小，这里是 16KB

Rd 命令默认是按 8 字节为单位，所以 16KB 的话，需要读取 2KB，也就是 `0x800`，此外，加入 -s 选项，这样可以将内核栈里的函数符号翻译成符号名加偏移的格式。

```bash
rd -s 0xffff973108079080 0x800
```

或者使用

```bash
bt -r
```

bt 还提供了`-T/t`参数，这样会把内核栈里可以解析的部分打印出来

```bash
bt -T
```

## 常用命令

查看系统中所有进程的信息

```bash
ps
```

查看进程的内存映射情况

```bash
vm
```

查看所有 CPU 的状态

```bash
cpu
```

查看内核模块信息

```bash
mod
```

查看某个函数的调用栈

```bash
bt func_name
```

列出所有可用的命令

```bash
help
```

分析崩溃发生的位置

```bash
bt -a
```

查看内存使用信息

```bash
kmem -i
```

## 常见问题

- vmcore 和 vmlinux 出现不匹配问题的解决方法

PAE 物理地址扩展，软件包 `kernel-PAE-debuginfo`

## 参考文档

- <https://www.ctyun.cn/developer/article/421358102605893>
- <https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/running-and-exiting-the-crash-utility_analyzing-a-core-dump>
- <https://blog.csdn.net/WANGYONGZIXUE/article/details/128431816>
