## nsenter 简介

`nsenter` 用来进入到某些指定的 namespace 中执行命令，可以方便地进行容器的调试

安装 nsenter

```bash
dnf install -y util-linux
```

源码地址：

```bash
git clone git://git.kernel.org/pub/scm/utils/util-linux/util-linux.git
```

源码构建：

```bash
cd $(mktemp -d)

export INST_UTIL_LINUX_VERSION=v2.24
curl -sL \
  https://www.kernel.org/pub/linux/utils/util-linux/${INST_UTIL_LINUX_VERSION}/util-linux-${INST_UTIL_LINUX_VERSION/v/}.tar.gz \
  -o util-linux-${INST_UTIL_LINUX_VERSION/v/}.tar.gz

tar zxvf util-linux-${INST_UTIL_LINUX_VERSION/v/}.tar.gz -C . && cd util-linux-${INST_UTIL_LINUX_VERSION/v/}

./autogen.sh

./configure --without-python --disable-all-programs --enable-nsenter && make
```

## 使用指南

 nsenter 命令的语法：

```plain
nsenter [options] [program [arguments]]

options:

-a, --all # enter all namespaces of the target process by the default /proc/[pid]/ns/* namespace paths.
-m, --mount[=<file>] # 进入 mount 命令空间。如果指定了 file，则进入 file 的命名空间
-u, --uts[=<file>]   # 进入 UTS 命名空间。如果指定了 file，则进入 file 的命名空间
-i, --ipc[=<file>]   # 进入 System V IPC 命名空间。如果指定了 file，则进入 file 的命名空间
-n, --net[=<file>]   # 进入 net 命名空间。如果指定了 file，则进入 file 的命名空间
-p, --pid[=<file>    # 进入 pid 命名空间。如果指定了 file，则进入 file 的命名空间
-U, --user[=<file>   # 进入 user 命名空间。如果指定了 file，则进入 file 的命名空间
-t, --target <pid>   # 指定被进入命名空间的目标进程的 pid
-G, --setgid gid     # 设置运行程序的 GID
-S, --setuid uid     # 设置运行程序的 UID
-r, --root[=directory] # 设置根目录
-w, --wd[=directory]   # 设置工作目录
```

## 调试容器

### 调试 docker 容器

`nsenter` 常用的一个场景是进入到另外一个进程的 namespace 中进行调试

查看容器进程在宿主机的 PID

```bash
docker inspect -f '{{.State.Pid}}' 容器
```

查看所有容器的宿主机 PID

```bash
docker ps -aq  | xargs -i docker inspect -f  '{{.State.Pid}} {{ .Name }} ' {}
```

调试容器的 network namespace

```bash
nsenter -n --pid -t 30837 /bin/bash
```

- `-t 30837` 表示进程的 pid
- `--net / -n` 表示进入到进程的 net namespace
- `--pid` 表示进入到进程的 PID namespace
- `bash` 是执行的命令

这样就得到一个 shell，它所有的命令都是在进程的网络和 PId namespace 中执行的

### 调试 containerd 容器

方式与 Docker 相同

获取 Pid 的方式变为：

```bash
crictl ps -aq  | xargs -i crictl inspect \
  --template  '{{.info.pid}} {{ .info.config.metadata.name }}' \
  --output go-template {}
```

### 调试 pod

获取 pod pid 的方式：

```bash
kubectl get pod -o template --template='{{range .status.containerStatuses}}{{.containerID}}{{end}}'
```

注意，要去到容器所在的节点才能进行调试
