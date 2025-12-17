
## 命令对比

| 命令           | docker         | crictl（推荐）  | ctr                    |
| -------------- | -------------- | --------------- | ---------------------- |
| 查看容器列表   | docker ps      | crictl ps       | ctr -n k8s.io c ls     |
| 查看容器详情   | docker inspect | crictl inspect  | ctr -n k8s.io c info   |
| 查看容器日志   | docker logs    | crictl logs     | 无                     |
| 容器内执行命令 | docker exec    | crictl exec     | 无                     |
| 挂载容器       | docker attach  | crictl attach   | 无                     |
| 容器资源使用   | docker stats   | crictl stats    | 无                     |
| 创建容器       | docker create  | crictl create   | ctr -n k8s.io c create |
| 启动容器       | docker start   | crictl start    | ctr -n k8s.io run      |
| 停止容器       | docker stop    | crictl stop     | 无                     |
| 删除容器       | docker rm      | crictl rm       | ctr -n k8s.io c del    |
| 查看镜像列表   | docker images  | crictl images   | ctr -n k8s.io i ls     |
| 查看镜像详情   | docker inspect | crictl inspecti | 无                     |
| 拉取镜像       | docker pull    | crictl pull     | ctr -n k8s.io i pull   |
| 推送镜像       | docker push    | 无              | ctr -n k8s.io i push   |
| 删除镜像       | docker rmi     | crictl rmi      | ctr -n k8s.io i rm     |
| 查看Pod列表    | 无             | crictl pods     | 无                     |
| 查看Pod详情    | 无             | crictl inspectp | 无                     |
| 启动Pod        | 无             | crictl runp     | 无                     |
| 停止Pod        | 无             | crictl stopp    | 无                     |

## ctr 命令 - Containerd 管理命令

它是一个不受支持的调试和管理客户端，用于与容器守护进程进行交互。

因为它不受支持，所以命令、选项和操作不能保证向后兼容。

containerd 引入了 namespace 概念，每个 image 和 container 都会在各自的 namespace 下可见，目前 k8s 会使用 `k8s.io` 以及 `default` 作为命名空间。

- 当导入本地镜像时 ctr 不支持压缩。
- 通过 `ctr containers create` 创建容器后，只是一个静态的容器，容器中的用户进程并没有启动，所以还需要通过 `ctr task start` 来启动容器进程。当然也可以用 `ctr run` 的命令直接创建并运行容器。在进入容器操作时与 docker 不同的是，必须在 `ctr task exec` 命令后指定`--exec-id` 参数，这个 id 可以随便写只要唯一就行。
- ctr 没有 stop 容器的功能，只能暂停（ctr task pause）或者杀死（ctr task kill）容器

```bash
# 1) 名称空间查看创建或删除
ctr namespace create devops
ctr namespace ls -q
  # devops
  # k8s.io
ctr namespace remove devops


# 2) 镜像查看及其操作
ctr -n k8s.io images ls | grep "busybox"
  # docker.io/library/busybox:1.33.1 application/vnd.docker.distribution.manifest.list.v2+json sha256:930490f97e5b921535c153e0e7110d251134cc4b72bbb8133c6a5065cc68580d 752.6 KiB linux/386,linux/amd64,linux/arm/v5,linux/arm/v6,linux/arm/v7,linux/arm64/v8,linux/mips64le,linux/ppc64le,linux/s390x io.cri-containerd.image=managed
ctr -n k8s.io images ls -q | grep "busybox"   # docker.io/library/busybox:1.33.1
ctr -n k8s.io i rm k8s.gcr.io/pause:3.2       # 删除镜像
ctr -n k8s.io i pull -k k8s.gcr.io/pause:3.2  # 拉取镜像
ctr -n k8s.io i push -k k8s.gcr.io/pause:3.2  # 推送镜像
ctr -n k8s.io i export pause.tar k8s.gcr.io/pause:3.2 # 导出镜像
ctr -n k8s.io i import pause.tar              # 导入镜像
ctr -n k8s.io images check  | grep "busybox"  # 镜像检查
  # docker.io/library/busybox:1.33.1  application/vnd.docker.distribution.manifest.list.v2+json sha256:930490f97e5b921535c153e0e7110d251134cc4b72bbb8133c6a5065cc68580d complete (2/2) 750.1 KiB/750.1 KiB true
ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2         # 镜像标记 Tag 更改
ctr -n k8s.io i tag --force registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2 # 若新镜像 reference 已存在需要先删除新 reference 或者如下方式强制替换
ctr -n k8s.io i label docker.io/library/busybox:1.33.1 name=weiyigeek-test  # 设置镜像标签
  # io.cri-containerd.image=managed,name=weiyigeek-test
ctr -n k8s.io i label docker.io/library/busybox:1.33.1 name=""              # 清除镜像标签
  # io.cri-containerd.image=managed
ctr i mount docker.io/library/nginx:alpine /mnt # 镜像挂载到主机目录 /mnt 中
ctr i unmount /mnt # 将镜像从主机目录上卸载


# 3) 镜像内容编辑,对镜像的更高级操作可以使用子命令 content.
# 在线编辑镜像的 blob 并生成一个新的 digest
→ ctr content ls
→ ctr content edit --editor vim sha256:fdd7fff110870339d34cf071ee90fbbe12bdbf3d1d9a14156995dfbdeccd7923


# 4) 容器查看及其操作
ctr -n k8s.io container ls
  # CONTAINER                                                           IMAGE                                                            RUNTIME
  # 3d840c5cf157c322c1c0839d0166d80550fe49ca53544e1d589bd44f422b1f81    registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2    io.containerd.runc.v2
ctr -n k8s.io container create docker.io/library/busybox:latest busybox                       # 创建容器(并没有处于运行状态，只是一个静态的容器)
ctr -n k8s.io container info 39d36ef08456bed24a52bf1c845facbd9f93c35cbd65b16739b4746ab1811cb5 # 查看创建的容器详情（注意这个必须是完整的容器ID）和 docker inspect 类似
ctr -n k8s.io container rm 39d36ef08456bed24a52bf1c845facbd9f93c35cbd65b16739b4746ab1811cb5   # 删除容器
ctr -n k8s.io container label busybox name=weiyigeek-test     # 设置容器标签
  # io.containerd.image.config.stop-signal=SIGTERM,name=weiyigeek-test

# 5) 容器真正运行是由任务(Task)相关操作实现
ctr -n k8s.io task start -d nginx  # 启动容器
ctr -n k8s.io tasks ls
  # TASK     PID      STATUS
  # nginx    12708    RUNNING
ctr -n k8s.io task pause nginx     # 暂停容器
ctr -n k8s.io task resume nginx    # 恢复容器
ctr -n k8s.io task ps nginx        # 查看容器中所有进程的 PID (宿主机中的PID)
ctr -n k8s.io task exec --exec-id 0 -t nginx sh # 进入容器,必须要指定唯一的--exec-id。
ctr -n k8s.io tasks kill -a -s 9 {id}  # 停止容器内的Task
ctr -n k8s.io task metric 37d0ff9d8df20d34c652ee286c17e0626d8838d6d546a28e8246151fffd99b98 # 获取容器的 cgroup 信息，用于获取容器的内存、CPU 和 PID 的限额与使用量。
  # ID                                                                  TIMESTAMP
  # 37d0ff9d8df20d34c652ee286c17e0626d8838d6d546a28e8246151fffd99b98    2021-07-11 03:33:18.421996083 +0000 UTC
  # METRIC                   VALUE
  # memory.usage_in_bytes    65269760
  # memory.limit_in_byte     9223372036854771712
  # memory.stat.cache        4157440
  # cpuacct.usage            44769155237
  # cpuacct.usage_percpu     [22375115908 22394039329 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
  # pids.current             43
  # pids.limit               4582

# 6) 一步到位,直接进行容器创建并运行。
ctr -n k8s.io run --null-io --net-host -d
–env PASSWORD=$drone_password
–mount type=bind,src=/etc,dst=/host-etc,options=rbind:rw
–mount type=bind,src=/root/.kube,dst=/root/.kube,options=rbind:rw
-log-uri file:///var/log/xx.log
WeiyiGeek:Test sysreport bash /sysreport/run.sh

# 7) 每一个顶级配置块的命名都是 plugins."io.containerd.xxx.vx.xxx" 这种形式，其实每一个顶级配置块都代表一个插件，其中 io.containerd.xxx.vx 表示插件的类型，vx 后面的 xxx 表示插件的 ID。
ctr plugin ls
  # TYPE                            ID                    PLATFORMS      STATUS
  # io.containerd.content.v1        content               -              ok
  # io.containerd.snapshotter.v1    btrfs                 linux/amd64    error
  # io.containerd.snapshotter.v1    devmapper             linux/amd64    error
```

- 容器默认使用 fifo 创建日志文件, 有可能因为 fifo 容量导致业务运行阻塞。
- 需要停止容器时需要先停止容器内的 Task 再删除容器。
- ctr 没有 stop 容器的功能，只能暂停或者杀死容器。
- Container 创建阶段: 一个 container 对象只是包含了运行一个容器所需的资源及配置的数据结构，意味着 namespaces、rootfs 和容器的配置都已经初始化成功了，只是用户进程（这里是 nginx）还没有启动。
- Container 运行阶段: 一个容器真正的运行起来是由 Task 对象实现的，task 代表任务的意思，可以为容器设置网卡，还可以配置工具来对容器进行监控等。

## crictl 命令 - 容器运行时接口 (CRI) CLI

crictl 是 CRI 兼容的容器运行时命令行对接客户端， 你可以使用它来检查和调试 Kubernetes 节点上的容器运行时和应用程序。

由于该命令是为 k8s 通过 CRI 使用 containerd 而开发的（主要是调试工具），其他非 k8s 的创建的 crictl 是无法看到和调试的，简单的说用 ctr run 运行的容器无法使用 crictl 看到。

- crictl 命令工具 和 它的源代码在 cri-tools 代码库
- crictl 默认使用命名空间 k8s.io
- cri plugin 区别对待 pod 和 container

### config

使用 crictl config 命令获取并设置 crictl 客户端配置选项

```bash
crictl config [command options] [<crictl options>]
```

例如，`crictl config --set debug=true` 在提供后续 crictl 命令时将启用调试模式。

可选选项：

```bash
runtime-endpoint:      Container runtime endpoint
image-endpoint:        Image endpoint
timeout:               Timeout of connecting to server (default: 2s)
debug:                 Enable debug output (default: false)
pull-image-on-create:  Enable pulling image on create requests (default: false)
disable-pull-on-run:   Disable pulling image on run requests (default: false)
```

启用 pull-image-on-create 后，将修改 create container 命令以首先拉取容器的映像。

此功能用作使创建容器更容易、更快。crictl 可能希望不要提取创建容器所需的图像。例如，镜像可能已经被拉取或以其他方式加载到容器运行时中，或者用户可能在没有网络的情况下运行。因此，默认值 pull-image-on-create 为 false。

默认情况下，运行命令首先提取容器映像，并且 disable-pull-on-run 为 false。某些用户 crictl 可能希望将其设置 disable-pull-on-run 为true，以在使用 run 命令时默认情况下不拉取镜像。

要覆盖这些默认的拉取配置设置，--no-pull 并 --with-pull 为 create 和 run 命令提供了选项。

### 用法

```bash
crictl [全局选项]命令[命令选项] [参数...]
```

**指令**：

- `attach`：附加到正在运行的容器
- `create`：创建一个新的容器
- `exec`：在正在运行的容器中运行命令
- `version`：显示运行时版本信息
- `images`：列出镜像
- `inspect`：显示一个或多个容器的状态
- `inspecti`：返回一个或多个镜像的状态
- `imagefsinfo`：返回镜像文件系统信息
- `inspectp`：显示一个或多个pods的状态
- `logs`：获取容器的日志
- `port-forward`：将本地端口转发到Pod
- `ps`：列出容器
- `pull`：从镜像库拉取镜像
- `runp`：运行一个新的pod
- `rm`：删除一个或多个容器
- `rmi`：删除一个或多个镜像
- `rmp`：删除一个或多个pod
- `pods`：列出pods
- `start`：启动一个或多个已创建的容器
- `info`：显示容器运行时的信息
- `stop`：停止一个或多个运行中的容器
- `stopp`：停止一个或多个正在运行的Pod
- `update`：更新一个或多个正在运行的容器
- `config`：获取并设置crictl客户端配置选项
- `stats`：列出容器资源使用情况统计信息
- `completion`：输出bash shell完成代码
- `help, h`：显示命令列表或一个命令的帮助

**其他指令**：

- `--timeout`，`-t`：连接服务器的超时时间（以秒为单位）（默认值：10s）。0 或更少将被解释为未设置并转换为默认值。没有设置超时值的选项，支持的最小超时为 `1s`
- `--debug`，`-D`：启用调试输出
- `--help`，`-h`：显示帮助
- `--version`，`-v`：打印 crictl 的版本信息
- `--config`，`-c`：客户端配置文件的位置。如果未指定并且默认目录不存在，则也会搜索该程序的目录（默认目录：`/etc/crictl.yaml`）[`$ CRI_CONFIG_FILE`]

### 实践

```plain
# 0) 镜像查看及其操作
crictl images --digests
  # IMAGE                                                                         TAG                 DIGEST              IMAGE ID            SIZE
  # docker.io/calico/cni                                                          v3.18.4             278fd825d089e       021ecb3cb5348       44.7MB
crictl images nginx   # - 打印某个镜像
crictl images -q      # - 只打印镜像ID
  # sha256:8c811b4aec35f259572d0f79207bc0678df4c736eeec50bc9fec37ed936a472a
crictl images -o [json|yaml|table]   # - 镜像详细信息
crictl inspecti busybox              # - 查看镜像信息
crictl pull busybox                  # - 拉取 busybox 镜像
crictl push weiyigeek.top/busybox    # - 推送 busybox 镜像
crictl rmi docker.io/library/busybox # - 容器删除
  # Deleted: docker.io/library/busybox:1.33.1
  # Deleted: docker.io/library/busybox:latest

# 1) 容器查看及其操作
crictl ps -a  # - 打印在 k8s.io 命名空间下的业务容器
crictl --runtime-endpoint /run/containerd/containerd.sock ps -a | grep kube | grep -v pause # - 查看过滤指定的容器相关信息
  # CONTAINER ID        IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID
  # 8db74c2bf7595       ebc659140e762       3 days ago          Running             calico-node               0                   5af3d484b32c0
crictl create f84dd361f8dc51518ed291fbadd6db537b0496536c1d2d6c05ff943ce8c9a54f[创建的 Pod 的 ID] container-config.json pod-config.json # - 创建容器
crictl start 3e025dd50a72d956c4f14881fbb5b1080c9275674e95fb67f965f6478a957d60  # - 启动容器
crictl stop 3e025dd50a72d956c4f14881fbb5b1080c9275674e95fb67f965f6478a957d60   # - 删除容器
crictl exec -i -t 1f73f2d81bf98 ls # - 容器上执行命令

# 2) Pod查看与操作
$ crictl pods
  # POD ID              CREATED             STATE               NAME                                   NAMESPACE           ATTEMPT
  # 5af3d484b32c0       4 days ago          Ready               calico-node-zvst7                      kube-system         0
$ crictl pods --name nginx-65899c769f-wv2gp  # - 打印某个固定pod.
$ crictl pods --label run=nginx              # - 根据标签筛选pod.
$ crictl runp pod-config.json                # - 使用 crictl runp 命令应用 JSON 文件并运行沙盒。
$ crictl inspectp --output table $POD_ID     # - 用crictl查看pod的信息
$ crictl stopp $POD_ID  # - 停止Pod
$ crictl rmp  $POD_ID   # - 删除Pod

# 3) 日志查看
crictl --runtime-endpoint /run/containerd/containerd.sock logs --tail 50 8db74c2bf7595

# 4) 容器占用资源状态查看
crictl stats
  # CONTAINER           CPU %               MEM                 DISK                INODES
  # 8db74c2bf7595       0.69                53.37MB             274.4kB             81

# 5) 额外信息显示，例如版本及其显示有关 Containerd 和 CRI 插件的状态和配置信息
crictl version
  # Version:  0.1.0
  # RuntimeName:  containerd
  # RuntimeVersion:  1.5.11
  # RuntimeApiVersion:  v1alpha2
crictl info -o go-template --template "{{index .status}}"  # 格式化输出
  # map[conditions:[map[message: reason: status:true type:RuntimeReady] map[message: reason: status:true type:NetworkReady]]]
```

- crictl pods 列出的是 pod 的信息，包括 pod 所在的命名空间以及状态。
- crictl ps 列出的是应用容器的信息，而 docker ps 列出的是初始化容器（pause容器）和应用容器的信息，初始化容器在每个 pod 启动时都会创建，通常不会关注，从这一点上来说，crictl 使用起来更简洁明了一些
- 用 crictl 创建容器对容器运行时排错很有帮助。在运行的 Kubernetes 集群中，沙盒会随机的被 kubelet 停止和删除, 下面通过实例进行演示crictl使用。

### 创建沙盒

编写运行 Pod 沙盒的 JSON 文件，使用 crictl runp 命令应用 JSON 文件并运行沙盒。

```bash
$ cat pod-config.json
{
    "metadata": {
        "name": "nginx-sandbox",
        "namespace": "default",
        "attempt": 1,
        "uid": "hdishd83djaidwnduwk28bcsb"
    },
    "log_directory": "/tmp",
    "linux": {
    }
}

$ crictl runp pod-config.json
f84dd361f8dc51518ed291fbadd6db537b0496536c1d2d6c05ff943ce8c9a54f
```

检查沙盒是否处于就绪状态：

```bash
$ crictl pods
POD ID              CREATED             STATE               NAME                NAMESPACE           ATTEMPT
f84dd361f8dc5       17 seconds ago      Ready               busybox-sandbox     default             1
```

使用运行时处理程序运行 pod 沙盒，运行时处理程序需要运行时支持

下面的示例显示如何在 containerd 运行时上使用 runsc 处理程序运行 pod 沙盒

```bash
$ cat pod-config.json
{
    "metadata": {
        "name": "nginx-runsc-sandbox",
        "namespace": "default",
        "attempt": 1,
        "uid": "hdishd83djaidwnduwk28bcsb"
    },
    "log_directory": "/tmp",
    "linux": {
    }
}

$ crictl runp --runtime=runsc pod-config.json
c112976cb6caa43a967293e2c62a2e0d9d8191d5109afef230f403411147548c

$ crictl inspectp c112976cb6caa43a967293e2c62a2e0d9d8191d5109afef230f403411147548c
...
    "runtime": {
      "runtimeType": "io.containerd.runtime.v1.linux",
      "runtimeEngine": "/usr/local/sbin/runsc",
      "runtimeRoot": "/run/containerd/runsc"
    },
...
```

拉取 busybox 镜像然后在pod沙盒中使用 config 文件创建容器

```bash
crictl pull busybox:1.33.1
 # Image is up to date for sha256:69593048aa3acfee0f75f20b77acb549de2472063053f6730c4091b53f2dfb02

$ cat pod-config.json
{
    "metadata": {
        "name": "nginx-sandbox",
        "namespace": "default",
        "attempt": 1,
        "uid": "hdishd83djaidwnduwk28bcsb"
    },
    "log_directory": "/tmp",
    "linux": {
    }
}

$ cat container-config.json
{
  "metadata": {
      "name": "busybox"
  },
  "image":{
      "image": "busybox:1.33.1"
  },
  "command": [
      "top"
  ],
  "log_path":"busybox.log",
  "linux": {
  }
}

$ crictl create f84dd361f8dc51518ed291fbadd6db537b0496536c1d2d6c05ff943ce8c9a54f container-config.json pod-config.json
3e025dd50a72d956c4f14881fbb5b1080c9275674e95fb67f965f6478a957d60
```

列出容器并检查容器是否处于已创建状并启动容器

```bash
$ crictl ps -a
CONTAINER ID        IMAGE               CREATED             STATE               NAME                ATTEMPT
3e025dd50a72d       busybox             32 seconds ago      Created             busybox             0

$ crictl start 3e025dd50a72d956c4f14881fbb5b1080c9275674e95fb67f965f6478a957d60
3e025dd50a72d956c4f14881fbb5b1080c9275674e95fb67f965f6478a957d60

$ crictl ps
CONTAINER ID        IMAGE               CREATED              STATE               NAME                ATTEMPT
3e025dd50a72d       busybox             About a minute ago   Running             busybox             0
```

在容器中执行命令：

```bash
crictl exec -i -t 3e025dd50a72d956c4f14881fbb5b1080c9275674e95fb67f965f6478a957d60 ls
bin   dev   etc   home  proc  root  sys   tmp   usr   var
```

显示容器的统计信息：

```bash
$ crictl stats
CONTAINER           CPU %               MEM                 DISK              INODES
3e025dd50a72d       0.00                983kB             16.38kB             6
```
