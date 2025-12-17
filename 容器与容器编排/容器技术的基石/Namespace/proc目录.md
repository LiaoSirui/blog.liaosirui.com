## proc 目录

每个进程都有一个 `/proc/[pid]/ns` 的目录，里面保存了该进程所在对应 namespace 的链接：

``` bash
> ls -l /proc/$$/ns/

lrwxrwxrwx 1 root root 0 Mar 10 11:13 cgroup -> 'cgroup:[4026531835]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 ipc -> 'ipc:[4026531839]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 mnt -> 'mnt:[4026531841]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 net -> 'net:[4026531840]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 pid -> 'pid:[4026531836]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 pid_for_children -> 'pid:[4026531836]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 time -> 'time:[4026531834]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 time_for_children -> 'time:[4026531834]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 user -> 'user:[4026531837]'
lrwxrwxrwx 1 root root 0 Mar 10 11:13 uts -> 'uts:[4026531838]'
```

每个文件都是对应 namespace 的文件描述符，方括号里面的值是 namespace 的 inode

如果两个进程所在的 namespace 一样，那么它们列出来的 inode 是一样的；反之亦然

如果某个 namespace 中没有进程了，它会被自动删除，不需要手动删除；但是有个例外，如果 namespace 对应的文件某个应用程序打开，那么该 namespace 是不会被删除的，这个特性可以让我们保持住某个 namespace，以便后面往里面添加进程

需要注意的是，上面列出来是正常运行的 `bash` 程序的 namespace，并没有运行任何的容器，也没有执行任何和 namespace 有关的操作。也就是说，所有的程序都会有 namespace，可以简单理解成 namespace 其实就是进程的属性，然后操作系统把这个属性相同的进程组织到一起，起到资源隔离的作用

## 内核中的实现

每个进程都对应一个 `task_struct` 结构体，其中包含了 nsproxy 变量（<https://github.com/torvalds/linux/blob/v6.2/include/linux/sched.h#L1094-L1095>）:

```c
struct task_struct {
    // ...
    volatile long state;    /* -1 unrunnable, 0 runnable, >0 stopped */
    void *stack;
    // ...

    /* namespaces */
    struct nsproxy *nsproxy;
}
```

而 nsproxy 中保存的就是指向该进程所有 namespace 的指针， `clone` 和 `unshare` 每次系统调用都会导致 nsproxy 被复制

<https://github.com/torvalds/linux/blob/v6.2/include/linux/nsproxy.h#L15-L42>

```c
/*
 * A structure to contain pointers to all per-process
 * namespaces - fs (mount), uts, network, sysvipc, etc.
 *
 * The pid namespace is an exception -- it's accessed using
 * task_active_pid_ns.  The pid namespace here is the
 * namespace that children will use.
 *
 * 'count' is the number of tasks holding a reference.
 * The count for each namespace, then, will be the number
 * of nsproxies pointing to it, not the number of tasks.
 *
 * The nsproxy is shared by tasks which share all namespaces.
 * As soon as a single namespace is cloned or unshared, the
 * nsproxy is copied.
 */
struct nsproxy {
	atomic_t count;
	struct uts_namespace *uts_ns;
	struct ipc_namespace *ipc_ns;
	struct mnt_namespace *mnt_ns;
	struct pid_namespace *pid_ns_for_children;
	struct net 	     *net_ns;
	struct time_namespace *time_ns;
	struct time_namespace *time_ns_for_children;
	struct cgroup_namespace *cgroup_ns;
};
extern struct nsproxy init_nsproxy;
```

因为每个进程使用的 namespace 不同，因此访问得到的资源信息也不相同，从而达到资源隔离的效果

## 模拟 nsenter 实现

```c
#define _GNU_SOURCE
#include <fcntl.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define errExit(msg)        \
    do                      \
    {                       \
        perror(msg);        \
        exit(EXIT_FAILURE); \
    } while (0)

char *const container_args[] = {"/bin/bash", NULL};

int main(int argc, char *argv[])
{
    int fd;

    if (argc < 2)
    {
        fprintf(stderr, "%s /proc/PID/ns/FILE args...\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    fd = open(argv[1], O_RDONLY); /* Get descriptor for namespace */
    if (fd == -1)
        errExit("open");

    if (setns(fd, 0) == -1) /* Join that namespace */
        errExit("setns");

    execv(container_args[0], container_args); /* Execute a command in namespace */
    errExit("execv");
}

```

