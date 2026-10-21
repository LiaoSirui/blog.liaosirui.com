文档：

- <https://wiki.parabola.nu/Fixing_illegal_instruction_issues>

遇到的问题

```bash
Illegal instruction (core dumped)
```

排查方式如下：

```bash
gdb 指定程序

# 继续执行
(gdb) run

# 崩溃后打印现场
(gdb) bt

# 打印 pc
(gdb) display/i $pc
```

查找哪个指令集有问题指令
