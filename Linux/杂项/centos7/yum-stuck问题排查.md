查看进程状态

```bash
[root@55191e66630c /]# ps -C yum -o pid,%cpu,command
    PID %CPU COMMAND
    127  1.2 /usr/bin/python /usr/bin/yum install glibc -y
    150 99.4 /usr/bin/python /usr/bin/yum install glibc -y
```

yum 命令在执行时会涉及网络和磁盘 I/O 操作，因此也可能由于网络或存储设备的问题导致 CPU 占用率过高

可以使用其他工具来进一步分析 yum 进程的状态，例如 strace、lsof 等命令，找出造成高 CPU 使用率的原因

```
# strace -p <yum_pid> 
[root@55191e66630c /]# strace -p 150
fcntl(1043138306, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138307, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138308, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138309, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138310, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138311, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138312, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138313, F_GETFD)              = -1 EBADF (Bad file descriptor)
fcntl(1043138314, F_GETFD)              = -1 EBADF (Bad file descriptor)
```

这段 strace 输出显示了一系列 fcntl 系统调用，每个调用都返回了 EBADF 错误（Bad file descriptor）

这通常意味着某个文件描述符已经关闭或者根本不存在，因此无法执行相应的操作

在这个例子中，文件描述符的值看起来很大，可能是由于 yum 进程打开了大量的文件导致的；如果进程打开了太多的文件，会占用系统资源并增加进程管理的负担，进而导致一些文件描述符被错误地关闭

使用 lsof 命令来查看 yum 进程当前都打开了哪些文件。如果打开的文件过多，可能会占用系统资源并增加进程管理负担，从而导致一些文件描述符被错误地关闭

```bash
# lsof -p <yum_pid> 
```

查看系统已经使用的文件描述符

将输出三个值，分别是：

- 第一个值表示当前已经分配但未使用的文件描述符数量
- 第二个值表示当前正在使用的文件描述符数量
- 第三个值表示系统可用的最大文件描述符数量

```bash
> cat /proc/sys/fs/file-nr

6104    0       1024000
# sysctl -w fs.file-max=1024000
```

上述输出表示当前有 6104 个文件描述符已经分配但未使用，0 个文件描述符正在使用，系统可用的最大文件描述符数量为 1024000



```
After some research, I have found that ulimit -n, ulimit -Hn, ulimit -Sn value inside the container was 1073741824, and it made yum check every possible file descriptor, from 0 to 1073741824.

I have inserted --ulimit nofile=1024:262144 in docker commandline (like docker run --ulimit nofile=1024:262144 --name test -p 2202:22/tcp -i -t centos:7 /bin/bash), and yum update worked fine! Now I can enjoy yum on docker happily!


Is there also a solution without setting it in every docker container and maybe in containerd? I am experiencing similar issues in centos 7.9 containers running on centos 9 hosts using Kubernetes/containerd. Yum installations take hours instead of minutes.

Update: I've added LimitNOFILE=1048576 to the service unit of containerd now and it works.
```

运行如下带有 ulimit 限制的容器：

``` bash
docker run --ulimit nofile=1024:262144 -it --rm dockerhub.bigquant.ai:5000/bigquant/dockerstacks-base:master_latest bash
```

LimitNOFILE是Linux系统中用来限制一个进程可以打开的文件描述符数量的参数。文件描述符是操作系统对文件、网络套接字等I/O资源的抽象，Linux系统可以使用文件描述符来读取、写入和执行I/O操作。每个进程在启动时会分配一定数量的文件描述符，若进程需要打开更多的文件，则需要使用额外的文件描述符。如果进程没有被限制使用文件描述符的数量，那么它可以无限制地打开文件，这可能会导致系统资源耗尽。

通过设置LimitNOFILE参数，管理员可以限制一个进程可以打开的文件描述符数量，从而避免系统资源的过度占用。如果进程尝试打开超出此限制的文件描述符，将会收到"Too many open files"错误。

综上给出解决方法：

- docker build 可以使用 `--ulimit nofile=1024:262144`