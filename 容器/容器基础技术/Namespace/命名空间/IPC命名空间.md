## IPC 命名空间

IPC 是进程间通信的意思，作用是每个 namespace 都有自己的 IPC，防止不同 namespace 进程能互相通信（这样存在安全隐患）

IPC namespace 隔离的是 IPC（Inter-Process Communication） 资源，也就是进程间通信的方式，包括 System V IPC 和 POSIX message queues。每个 IPC namespace 都有自己的 System V IPC 和 POSIX message queues，并且对其他 namespace 不可见，这样的话，只有同一个 namespace 下的进程之间才能够通信

下面这些 `/proc` 中内容对于每个 namespace 都是不同的：

- `/proc/sys/fs/mqueue` 下的 POSIX message queues
- `/proc/sys/kernel` 下的 System V IPC，包括 msgmax, msgmnb, msgmni, sem, shmall, shmmax, shmmni, and shm_rmid_forced
- `/proc/sysvipc/`：保存了该 namespace 下的 system V ipc 信息

## IPC 隔离测试

在 linux 下和 ipc 打交道，需要用到以下两个命令：

- `ipcs`：查看 IPC（共享内存、消息队列和信号量）的信息
- `icmk`：创建 IPC（共享内存、消息队列和信号量）的信息

先看一下全局 ipc namespace，readlink 会读取 link 的值

```bash
readlink /proc/$$/ns/ipc
```

查看系统消息队列 ipc，发现为空。然后用 `ipcmk` 创建出来一个 message queue 

```bash
> ipc -q

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages  

> ipcmk -Q

Message queue id: 0

> ipcs -q 

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages    
0x7db67947 0          root       644        0            0     
```

修改 clone 函数的 flags，增加  `CLONE_NEWIPC`

```c
pid_t child_pid =
    clone(
        // 子进程将执行 container_func 这个函数
        container_func,
        container_stack + sizeof(container_stack),
        // 这里 SIGCHLD 是子进程退出后返回给父进程的信号，跟 namespace 无关
        CLONE_NEWIPC | SIGCHLD,
        // 传给child_func的参数
        NULL);
```

完整代码：

```c
#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

// 设置子进程要使用的栈空间
#define STACK_SIZE (1024 * 1024)
static char container_stack[STACK_SIZE];

#define errExit(code, msg) \
    ;                      \
    {                      \
        if (code == -1)    \
        {                  \
            perror(msg);   \
            exit(-1);      \
        }                  \
    }

char *const container_args[] = {"/bin/bash", NULL};

static int container_func(void *arg)
{
    pid_t pid = getpid();
    printf("Container[%d] - inside the container!\n", pid);

    // 用一个新的 bash 来替换掉当前子进程
    // 这样我们就能通过 bash 查看当前子进程的情况
    // bash 退出后，子进程执行完毕
    execv(container_args[0], container_args);

    // 从这里开始的代码将不会被执行到，因为当前子进程已经被上面的 bash 替换掉了;
    // 所以如果执行到这里，一定是出错了
    printf("Container[%d] - oops!\n", pid);
    return 1;
}

int main(int argc, char *argv[])
{
    pid_t pid = getpid();
    printf("Parent[%d] - create a container!\n", pid);

    // 创建并启动子进程，调用该函数后，父进程将继续往后执行，也就是执行后面的 waitpid
    pid_t child_pid =
        clone(
            // 子进程将执行 container_func 这个函数
            container_func,
            container_stack + sizeof(container_stack),
            // 这里 SIGCHLD 是子进程退出后返回给父进程的信号，跟 namespace 无关
            CLONE_NEWIPC | SIGCHLD,
            // 传给child_func的参数
            NULL);
    errExit(child_pid, "clone");

    waitpid(child_pid, NULL, 0); // 等待子进程结束

    printf("Parent[%d] - container exited!\n", pid);
    return 0;
}

```

运行程序，自动创建新的 ipc namespace

看一下 ipc namespace 对应的文件，发现和之前全局 ipc namespace 不同

```bash
```



保持上面的程序不退出，在另外一个终端运行 join_ns 程序，加入到 ipc namespace，发现可以通过 `ipcs` 看到这个 namespace 中已经创建的 message queue。证明我们使用的 ipc namespace 和上面的容器是一样的