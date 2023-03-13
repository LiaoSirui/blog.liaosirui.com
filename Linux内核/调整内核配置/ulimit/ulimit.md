## ulimit 简介

`ulimit` 用于 shell 启动进程所占用的资源

## limit

`ulimit` 指令可以用来查看以及设置单个用户可以使用的系统资源大小

查看当期进程的限制：

```bash
> cat /proc/$$/limits

Limit                     Soft Limit           Hard Limit           Units
Max cpu time              unlimited            unlimited            seconds
Max file size             unlimited            unlimited            bytes
Max data size             unlimited            unlimited            bytes
Max stack size            8388608              unlimited            bytes
Max core file size        0                    unlimited            bytes
Max resident set          unlimited            unlimited            bytes
Max processes             512476               512476               processes
Max open files            1024                 524288               files
Max locked memory         65536                65536                bytes
Max address space         unlimited            unlimited            bytes
Max file locks            unlimited            unlimited            locks
Max pending signals       512476               512476               signals
Max msgqueue size         819200               819200               bytes
Max nice priority         0                    0
Max realtime priority     0                    0
Max realtime timeout      unlimited            unlimited            us
```

## 软资源限制和硬资源限制

- 硬资源限制代表了物理限制，即物理上最大能达到的值
- 软资源可以由用户管理，进行限制，但是最大值不能超过硬限制

## 修改方式

### 用户级修改临时生效方法

ulimit 命令身是分软限制和硬限制：

- `-H`就是硬限制
- `-S`就是软限制。

默认显示的是软限制，如果运行 ulimit 命令修改时没有加上 -H 或 -S，就是两个参数一起改变。硬限制就是实际的限制，而软限制是警告限制，只会给出警告。

```bash
ulimit -SHn 10000
```

### 用户级修改永久有效方式

修改 `/etc/security/limits.conf` 文件，添加如下内容：

```bash
* soft nofile 204800
* hard nofile 204800

* soft nproc 204800
* hard nproc 204800
```

查看用户级修改是否生效

```bash
ulimit -a
```

item 说明

- core - limits the core file size (KB)

```bash
# -c: core file size (blocks)         0
ulimit -c
```

- data - max data size (KB)

```bash
# -d: data seg size (kbytes)          unlimited
ulimit -d
```

- fsize - maximum filesize (KB)

```bash
# -f: file size (blocks)              unlimited
ulimit -f
```

- memlock - max locked-in-memory address space (KB)

```bash
# -l: locked-in-memory size (kbytes)  64
ulimit -l
```

- nofile - max number of open file descriptors

```bash
# -n: file descriptors                1024
ulimit -n
```

- rss - max resident set size (KB)

```bash
# -m: resident set size (kbytes)      unlimited
ulimit -m
```

- stack - max stack size (KB)

```bash
# -s: stack size (kbytes)             8192
ulimit -s
```

- cpu - max CPU time (MIN)

```bash
# -t: cpu time (seconds)              unlimited
ulimit -t
```

- nproc - max number of processes

```bash
# -u: processes                       512476
ulimit -u
```

- as - address space limit (KB)

```bash
# -v: address space (kbytes)          unlimited
ulimit -v
```

- maxlogins - max number of logins for this user

```bash
```

- maxsyslogins - max number of logins on the system

```bash
```

- priority - the priority to run user process with

```bash
# -e: max nice                        0
ulimit -e
```

- locks - max number of file locks the user can hold

```bash
# -x: file locks                      unlimited
ulimit -x
```

- sigpending - max number of pending signals

```bash
# -i: pending signals                 512476
ulimit -i
```

- msgqueue - max memory used by POSIX message queues (bytes)

```bash
# -q: bytes in POSIX msg queues       819200
ulimit -q
```

- nice - max nice priority allowed to raise to values: [-20, 19]

```bash
ulimit -n
```

- rtprio - max realtime priority

```bash
# -r: max rt priority                 0
ulimit -r
```



