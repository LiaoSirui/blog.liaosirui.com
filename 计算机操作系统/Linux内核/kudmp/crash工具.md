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

（2）进入 core 文件所在路径， 执行如下命令：

```bash
crash vmcore /usr/lib/debug/lib/modules/<对应内核调试文件>/vmlinux
```

## 常用命令

| 命令         | 功能                 | 示例                                                         |
| ------------ | -------------------- | ------------------------------------------------------------ |
| `bt`         | 打印函数调用栈       | displays a task's kernel-stack backtrace，可以指定进程号 `bt <pid>` |
| `log`        | 打印系统消息缓冲区   | displays the kernel log_buf contents，如 `log \| tail -n 30` |
| `ps`         | 显示进程的状态       | `>` 表示活跃的进程，如 `ps | grep RU`                        |
| `sys`        | 显示系统概况         |                                                              |
| `kmem -i`    | 显示内存使用信息     |                                                              |
| `dis <addr>` | 对给定地址进行反汇编 |                                                              |

## 常见问题

- vmcore 和 vmlinux 出现不匹配问题的解决方法

PAE 物理地址扩展，软件包 `kernel-PAE-debuginfo`

## 参考文档

- <https://www.ctyun.cn/developer/article/421358102605893>
- <https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/running-and-exiting-the-crash-utility_analyzing-a-core-dump>

- <https://blog.csdn.net/WANGYONGZIXUE/article/details/128431816>