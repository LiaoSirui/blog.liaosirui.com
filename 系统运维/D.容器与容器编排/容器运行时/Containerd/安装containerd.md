
## 基础环境准备

参考 Kubernetes 容器运行时接口进行安装前的基础环境准备

### 配置内核模块

模块加载：

```bash
modprobe overlay
modprobe br_netfilter
```

写入文件持久化：

```bash
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
```

<https://wiki.archlinux.org/title/Kernel_module_(简体中文)>

目前，所有必要模块的加载均由 udev 自动完成。所以，如果不需要使用任何额外的模块，就没有必要在任何配置文件中添加启动时加载的模块。但是，有些情况下可能需要在系统启动时加载某个额外的模块，或者将某个模块列入黑名单以便使系统正常运行。

内核模块可以在 `/etc/modules-load.d/` 下的文件中明确列出，以便systemd在引导过程中加载它们。每个配置文件都以 `/etc/modules-load.d/<program>.conf` 的样式命名。 配置文件仅包含要加载的内核模块名称列表，以换行符分隔。空行和第一个非空白字符为 # 或 ; 的行被忽略。

### 配置 sysctl

设置所需的 sysctl 参数，这些参数在重新启动后仍然存在：

```bash
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```

应用 sysctl 参数而不重新启动：

```bash
sysctl --system
```

## 安装 containerd.io

Rocky Linux 默认安装了 Podman，需要先卸载。否则会和 Docker 依赖组件冲突。

```bash
dnf -y erase podman buildah
```

添加存储库：

```bash
dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

参考的源配置（使用阿里镜像源）：

```plain
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/$basearch/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-stable-debuginfo]
name=Docker CE Stable - Debuginfo $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/debug-$basearch/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-stable-source]
name=Docker CE Stable - Sources
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/source/stable
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-test]
name=Docker CE Test - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-test-debuginfo]
name=Docker CE Test - Debuginfo $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/debug-$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-test-source]
name=Docker CE Test - Sources
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/source/test
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-nightly]
name=Docker CE Nightly - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-nightly-debuginfo]
name=Docker CE Nightly - Debuginfo $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/debug-$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

[docker-ce-nightly-source]
name=Docker CE Nightly - Sources
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/$releasever/source/nightly
enabled=0
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg

```

安装：

```bash
dnf --enablerepo=docker-ce-stable install containerd.io --nobest --allowerasing
```

## 初始化 Containerd.io 基础配置

### 默认配置

初始化配置

```bash
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

### 修改 sandbox

（可以配置镜像加速，此步骤可省略）

修改默认的 sandbox 镜像：

```bash
sed -ir 's#sandbox_image = \S\w+.*$#sandbox_image = "registry.aliyuncs.com/k8sxio/pause:3.6"#g' /etc/containerd/config.toml

sed -ir "s#https://registry-1.docker.io#https://docker.mirrors.ustc.edu.cn#g"
```

### 存储路径

查看默认的配置文件，其中root与state 分别表示 Containerd 有两个不同的存储路径，一个用来保存持久化数据，一个用来保存运行时状态。

```plain
...
root = "/data/containerd/data" 
state = "/data/containerd/state"
...
```

root 用来保存持久化数据，包括 Snapshots, Content, Metadata 以及各种插件的数据。每一个插件都有自己单独的目录，Containerd 本身不存储任何数据，它的所有功能都来自于已加载的插件

```bash
tree -L 2 /data/containerd/data
```

目录结构如下：

```plain
[root@devmaster ~]# tree -L 2 /data/containerd/data
/data/containerd/data
├── io.containerd.content.v1.content
│   ├── blobs
│   └── ingest
├── io.containerd.grpc.v1.introspection
│   └── uuid
├── io.containerd.metadata.v1.bolt
│   └── meta.db
├── io.containerd.runtime.v1.linux
├── io.containerd.runtime.v2.task
│   ├── default
│   └── k8s.io
├── io.containerd.snapshotter.v1.native
│   └── snapshots
├── io.containerd.snapshotter.v1.overlayfs
│   ├── metadata.db
│   └── snapshots
└── tmpmounts

```

state 用来保存临时数据，包括 sockets、pid、挂载点、运行时状态以及不需要持久化保存的插件数据

```bash
tree -L 2 /data/containerd/state
```

目录结构如下：

```plain
[root@devmaster ~]# tree -L 2 /data/containerd/state
/data/containerd/state
├── io.containerd.runtime.v1.linux
└── io.containerd.runtime.v2.task
    ├── default
    └── k8s.io
```

### oom_score

```plain
oom_score = -999
```

Containerd 是容器的守护者，一旦发生内存不足的情况，理想的情况应该是先杀死容器，而不是杀死 Containerd。

需要调整 Containerd 的 OOM 权重，减少其被 OOM Kill 的几率，最好是将 oom_score 的值调整为比其他守护进程略低的值。这里的 oom_socre 其实对应的是 `/proc/<pid>/oom_socre_adj`，在早期的 Linux 内核版本里使用 oom_adj 来调整权重, 后来改用 `oom_socre_adj` 了。在计算最终的 badness score 时，会在计算结果是中加上 oom_score_adj，这样用户就可以通过该在值来保护某个进程不被杀死或者每次都杀某个进程。其取值范围为 -1000 到 1000。

如果将该值设置为 -1000，则进程永远不会被杀死，因为此时 badness score 永远返回 0， 建议 Containerd 将该值设置为 -999 到 0 之间。如果作为 Kubernetes 的 Worker 节点，可以考虑设置为 -999。

### 镜像加速配置

```bash
vim /etc/containerd/config.toml
```

镜像加速的配置就在 cri 插件配置块下面的 registry 配置块，需要修改的部分如下：

```toml
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        # custom here
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://docker.mirrors.ustc.edu.cn", "http://hub-mirror.c.163.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
          endpoint = ["https://gcr.mirrors.ustc.edu.cn"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"]
          endpoint = ["https://gcr.mirrors.ustc.edu.cn/google-containers/"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
          endpoint = ["https://quay.mirrors.ustc.edu.cn"]
```

可选 aliyun:

```toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"]
  endpoint = ["https://registry.aliyuncs.com/k8sxio"]
```

- `registry.mirrors."xxx"`  表示需要配置 mirror 的镜像仓库。例如，`registry.mirrors."docker.io"` 表示配置 docker.io 的 mirror
- `endpoint` 表示提供 mirror 的镜像加速服务

### systemd 配置

```plain
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
# custom here: LimitNOFILE=infinity
LimitNOFILE=1048576
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target

```

- Delegate： 这个选项允许 Containerd 以及运行时自己管理自己创建的容器的 cgroups。如果不设置这个选项，systemd 就会将进程移到自己的 cgroups 中，从而导致 Containerd 无法正确获取容器的资源使用情况。
- KillMode : 这个选项用来处理 Containerd 进程被杀死的方式。默认情况下，systemd 会在进程的 cgroup 中查找并杀死 Containerd 的所有子进程，这肯定不是我们想要的。KillMode字段可以设置的值如下。
  - control-group（默认值）：当前控制组里面的所有子进程，都会被杀掉
  - process：只杀主进程
  - mixed：主进程将收到 SIGTERM 信号，子进程收到 SIGKILL 信号
  - none：没有进程会被杀掉，只是执行服务的 stop 命令

需要将 KillMode 的值设置为 process，这样可以确保升级或重启 Containerd 时不杀死现有的容器。bili

设置自启动：

```bash
systemctl enable containerd --now
```

### 应用配置

应用配置并重新运行 containerd 服务并查看服务状态

```bash
systemctl daemon-reload && systemctl restart containerd

systemctl status containerd.service
```

### 查看 containerd Client 与 Server 端的信息

```bash
ctr version
```

输出为：

```plain
Client:
  Version:  1.6.4
  Revision: 212e8b6fa2f44b9c21b2798135fc6fb7c53efc16
  Go version: go1.17.9

Server:
  Version:  1.6.4
  Revision: 212e8b6fa2f44b9c21b2798135fc6fb7c53efc16
  UUID: 78d557a7-bf0f-4f66-9abd-f24088983284
```

## 安装 crictl

crictl 是 CRI 兼容的容器运行时命令行接口。

可以使用它来检查和调试 Kubernetes 节点上的容器运行时和应用程序。

### 二进制安装

在 github 下载安装包：<https://github.com/kubernetes-sigs/cri-tools/releases>

```bash
export KUBE_VERSION="v1.24.1"

wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$KUBE_VERSION/crictl-$KUBE_VERSION-linux-amd64.tar.gz

tar zxvf crictl-$KUBE_VERSION-linux-amd64.tar.gz -C /usr/local/bin

rm -f crictl-$KUBE_VERSION-linux-amd64.tar.gz
```

如果要使用源安装，先设置源：

```bash
export KUBE_VERSION=1.24

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/devel:kubic:libcontainers:stable.repo

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${KUBE_VERSION}.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${KUBE_VERSION}/CentOS_8/devel:kubic:libcontainers:stable:cri-o:${KUBE_VERSION}.repo
```

从源中安装：

```bash
dnf install -y cri-o cri-tools
```

### 设置配置文件

crictl 默认连接到 `unix:///var/run/dockershim.sock`。

对于其他的运行时，可以用多种不同的方法设置端点：

- 通过设置参数 `--runtime-endpoint` 和 `--image-endpoint`
- 通过设置环境变量 `CONTAINER_RUNTIME_ENDPOINT` 和 `IMAGE_SERVICE_ENDPOINT`
- 通过在配置文件中设置端点 `--config=/etc/crictl.yaml`

还可以在连接到服务器并启用或禁用调试时指定超时值，方法是在配置文件中指定 timeout 或 debug 值，或者使用 `--timeout` 和 `--debug` 命令行参数

```bash
# 这里使用 containerd

cat >> /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 3
debug: false
EOF
```
