## 安装 runc

使用如下命令安装 runc

最新的 Release 可以从 <https://github.com/opencontainers/runc/releases> 获取

```bash
export RUNC_VERSION=v1.1.4

curl -sL https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.amd64 -o /usr/local/bin/runc-${RUNC_VERSION}

chmod +x /usr/local/bin/runc-${RUNC_VERSION}

ln -s /usr/local/bin/runc-${RUNC_VERSION} /usr/bin/runc
ln -s /usr/local/bin/runc-${RUNC_VERSION} /usr/local/bin/runc
```

查看二进制文件和软链

```bash
ls -al /usr/bin/runc /usr/local/bin/runc /usr/local/bin/runc-${RUNC_VERSION}
```

## 安装 containerd

最新的 release 可以从 <https://github.com/containerd/containerd/releases> 获取

下载 containerd

```bash
export CONTAINERD_VERSION=v1.6.15

cd $(mktemp -d)
curl -sL \
	https://github.com/containerd/containerd/releases/download/${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION/v/}-linux-amd64.tar.gz \
	-o containerd-${CONTAINERD_VERSION/v/}-linux-amd64.tar.gz

# 解压 containerd
mkdir -p /usr/local/containerd-${CONTAINERD_VERSION/v/}
tar zxvf containerd-${CONTAINERD_VERSION/v/}-linux-amd64.tar.gz -C /usr/local/containerd-${CONTAINERD_VERSION/v/}

ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-shim /usr/bin/containerd-shim
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd /usr/bin/containerd
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-shim-runc-v1 /usr/bin/containerd-shim-runc-v1
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-stress /usr/bin/containerd-stress
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-shim-runc-v2 /usr/bin/containerd-shim-runc-v2
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/ctr /usr/bin/ctr

ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-shim /usr/local/bin/containerd-shim
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd /usr/local/bin/containerd
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-shim-runc-v1 /usr/local/bin/containerd-shim-runc-v1
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-stress /usr/local/bin/containerd-stress
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/containerd-shim-runc-v2 /usr/local/bin/containerd-shim-runc-v2
ln -s /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin/ctr /usr/local/bin/ctr
```

查看二进制文件和软链

```bash
ls -al /usr/local/containerd-${CONTAINERD_VERSION/v/}/bin
ls -al /usr/bin/containerd* /usr/bin/ctr
ls -al /usr/local/bin/containerd* /usr/local/bin/ctr
```

生成配置文件

```bash
# 生成 containerd 配置
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
```

编写 service 文件

```bash
# 编写 service 文件
wget https://raw.githubusercontent.com/containerd/containerd/${CONTAINERD_VERSION}/containerd.service -O /usr/lib/systemd/system/containerd.service
```

内容为

```ini
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
```

启动 containerd

```bash
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd
systemctl status containerd
```

配置 cgroups 驱动：<https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/#containerd-systemd>

```bash
[root@devmaster1 ~]# cat -n /etc/containerd/config.toml  | grep -i systemd
    67        systemd_cgroup = false
   125                SystemdCgroup = true
```

如果不满足，则编辑文件

```bash
vim /etc/containerd/config.toml +125
```

配置使用代理

```bash
mkdir /etc/systemd/system/containerd.service.d

cat > /etc/systemd/system/containerd.service.d/http_proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://10.244.244.2:7891"
Environment="HTTPS_PROXY=http://10.244.244.2:7891"
Environment="ALL_PROXY=socks5://10.244.244.2:7891"
Environment="NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.liaosirui.com"
EOF

systemctl daemon-reload

systemctl restart containerd
```

## 安装 docker

参考官网文档： <https://docs.docker.com/engine/install/binaries/#install-daemon-and-client-binaries-on-linux>

下载 docker 二进制版本，请选择最新最稳定的CE版本

<https://download.docker.com/linux/static/stable/x86_64/>

```bash
export DOCKER_VERSION=v20.10.9

cd $(mktemp -d)

wget https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION/v/}.tgz -O docker-ce.tgz

tar zxvf docker-ce.tgz -C .
```

移动所需二进制文件，建立软链

```bash
mv ./docker /usr/local/docker-${DOCKER_VERSION/v/}

ln -s /usr/local/docker-${DOCKER_VERSION/v/}/dockerd /usr/bin/dockerd
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-proxy /usr/bin/docker-proxy
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker /usr/bin/docker
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-init /usr/bin/docker-init

ln -s /usr/local/docker-${DOCKER_VERSION/v/}/dockerd /usr/local/bin/dockerd
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-proxy /usr/local/bin/docker-proxy
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker /usr/local/bin/docker
ln -s /usr/local/docker-${DOCKER_VERSION/v/}/docker-init /usr/local/bin/docker-init

```

查看二进制和软链

```bash
ls -al /usr/local/docker-${DOCKER_VERSION/v/}
ls -al /usr/bin/docker*
ls -al /usr/local/bin/docker*
```

创建一个 system 管理文件，参考

- <https://github.com/docker/docker-ce/blob/master/components/engine/contrib/init/systemd/docker.service>
- <https://github.com/moby/moby/blob/v20.10.19/contrib/init/systemd/docker.servic>

```bash
wget https://raw.githubusercontent.com/moby/moby/v20.10.19/contrib/init/systemd/docker.service \
  -O /usr/lib/systemd/system/docker.service
```

配置文件内容如下：

```ini
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
```

创建 docker.socket，参考

- <https://github.com/docker/docker-ce/blob/master/components/engine/contrib/init/systemd/docker.socket>
- <https://github.com/moby/moby/blob/v20.10.19/contrib/init/systemd/docker.socket>

```bash
curl -L https://raw.githubusercontent.com/moby/moby/v20.10.19/contrib/init/systemd/docker.socket \
  -o /usr/lib/systemd/system/docker.socket
```

内容如下：

```bash
[Unit]
Description=Docker Socket for the API

[Socket]
# If /var/run is not implemented as a symlink to /run, you may need to
# specify ListenStream=/var/run/docker.sock instead.
ListenStream=/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
```

把上面的 group 改为 root

配置 docker 服务端

```bash
mkdir -p /etc/docker
vim /etc/docker/daemon.json 
```

内容如下：

```bash
{
    "debug": false,
    "insecure-registries": [
      "0.0.0.0/0"
    ],
    "ip-forward": true,
    "ipv6": false,
    "live-restore": true,
    "log-driver": "json-file",
    "log-level": "warn",
    "log-opts": {
      "max-size": "100m",
      "max-file": "2"
    },
    "selinux-enabled": false,
    "metrics-addr" : "0.0.0.0:9323",
    "experimental" : true,
    "storage-driver": "overlay2"
}
```

重启进程

```bash
systemctl daemon-reload
systemctl start docker.service

# 设置开机自动启动
systemctl enable docker
```

配置代理

```bash
mkdir /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/containerd.service.d/http_proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://10.244.244.1:8899"
Environment="HTTPS_PROXY=http://10.244.244.1:8899"
Environment="ALL_PROXY=socks5://10.244.244.1:8899"
Environment="NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.liaosirui.com"
EOF

systemctl daemon-reload
systemctl restart docker
```

## 安装 nerdctl

最新 release 可以从：<https://github.com/containerd/nerdctl/releases> 获取

下载 nerdctl

```bash
export NERDCTL_VERSION=v1.1.0

# 下载 nerdctl
cd $(mktemp -d)
curl -L https://github.com/containerd/nerdctl/releases/download/${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION/v/}-linux-amd64.tar.gz \
  -o nerdctl-${NERDCTL_VERSION/v/}-linux-amd64.tar.gz

mkdir -p /usr/local/nerdctl-${NERDCTL_VERSION/v/}
tar zxvf nerdctl-${NERDCTL_VERSION/v/}-linux-amd64.tar.gz -C /usr/local/nerdctl-${NERDCTL_VERSION/v/}
```

建立软链

```bash
ln -s /usr/local/nerdctl-${NERDCTL_VERSION/v/}/nerdctl /usr/bin/nerdctl
ln -s /usr/local/nerdctl-${NERDCTL_VERSION/v/}/nerdctl /usr/local/bin/nerdctl
```

查看二进制文件和生成的软链

```bash
ls -al /usr/local/nerdctl-${NERDCTL_VERSION/v/}
ls -al /usr/bin/nerdctl /usr/local/bin/nerdctl
```

配置 alias

```bash
echo "alias dockern='nerdctl --namespace k8s.io'"  >> ~/.bashrc
echo "alias dockern-compose='nerdctl compose'"  >> ~/.bashrc
source ~/.bashrc
```

下载 cni 插件，最新版本可以从 <https://github.com/containernetworking/plugins/releases>

```bash
export CNI_VERSION=v1.2.0

cd $(mktemp -d)
wget --no-check-certificate https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz \
  -O cni-plugins-linux-amd64-${CNI_VERSION}.tgz

mkdir -p /usr/local/cni-plugins-${CNI_VERSION}
tar xvf cni-plugins-linux-amd64-${CNI_VERSION}.tgz -C /usr/local/cni-plugins-${CNI_VERSION}

ln -s /usr/local/cni-plugins-${CNI_VERSION} /usr/local/cni-plugins
```

配置 nerdctl

```bash
# 配置 nerdctl
mkdir -p /etc/nerdctl/

cat > /etc/nerdctl/nerdctl.toml << 'EOF'
namespace         = "k8s.io"
insecure_registry = true
cni_path          = "/usr/local/cni-plugins"
EOF
```

## 配置 buildkit

最新的 release 可以从：<https://github.com/moby/buildkit/releases> 获取

下载 buildkit

```bash
export BUILD_KIT_VERSION=v0.11.1

cd $(mktemp -d)
wget https://github.com/moby/buildkit/releases/download/${BUILD_KIT_VERSION}/buildkit-${BUILD_KIT_VERSION}.linux-amd64.tar.gz \
  -O buildkit-${BUILD_KIT_VERSION}.linux-amd64.tar.gz

mkdir -p /usr/local/buildkit-${BUILD_KIT_VERSION}
tar zxvf buildkit-${BUILD_KIT_VERSION}.linux-amd64.tar.gz -C /usr/local/buildkit-${BUILD_KIT_VERSION}

ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildctl /usr/bin/buildctl
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-aarch64 /usr/bin/buildkit-qemu-aarch64
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-arm /usr/bin/buildkit-qemu-arm
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-i386 /usr/bin/buildkit-qemu-i386
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-mips64 /usr/bin/buildkit-qemu-mips64
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-mips64el /usr/bin/buildkit-qemu-mips64el
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-ppc64le /usr/bin/buildkit-qemu-ppc64le
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-riscv64 /usr/bin/buildkit-qemu-riscv64
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-s390x /usr/bin/buildkit-qemu-s390x
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-runc /usr/bin/buildkit-runc
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkitd /usr/bin/buildkitd

ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildctl /usr/local/bin/buildctl
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-aarch64 /usr/local/bin/buildkit-qemu-aarch64
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-arm /usr/local/bin/buildkit-qemu-arm
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-i386 /usr/local/bin/buildkit-qemu-i386
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-mips64 /usr/local/bin/buildkit-qemu-mips64
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-mips64el /usr/local/bin/buildkit-qemu-mips64el
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-ppc64le /usr/local/bin/buildkit-qemu-ppc64le
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-riscv64 /usr/local/bin/buildkit-qemu-riscv64
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-qemu-s390x /usr/local/bin/buildkit-qemu-s390x
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkit-runc /usr/local/bin/buildkit-runc
ln -s /usr/local/buildkit-${BUILD_KIT_VERSION}/bin/buildkitd /usr/local/bin/buildkitd
```

配置 buildkit

```bash
# /etc/buildkit/buildkitd.toml 为 buildkitd 默认配置
mkdir -p /etc/buildkit/

cat > /etc/buildkit/buildkitd.toml << 'EOF'
debug = true
# root is where all buildkit state is stored.
root = "/var/lib/buildkit"
# insecure-entitlements allows insecure entitlements, disabled by default.
insecure-entitlements = [ "network.host", "security.insecure" ]

[worker.oci]
  enabled = true
  platforms = [ "linux/amd64", "linux/arm64" ]
  snapshotter = "auto"
  rootless = false
  noProcessSandbox = false
  gc = true
  gckeepstorage = 9000
  max-parallelism = 4

  [[worker.oci.gcpolicy]]
    keepBytes = 512000000
    keepDuration = 172800
    filters = [ "type==source.local", "type==exec.cachemount", "type==source.git.checkout"]

[registry."19.15.14.158:31104"]
  mirrors = ["19.15.14.158:31104"]
  http = true       #使用http协议
  insecure = true    #不验证安全证书
[registry."mmzwwwdocker.xxxxxx.com:31104"]
  mirrors = ["mmzwwwdocker.xxxxxxx.com:31104"]
  http = true  #使用http协议
  insecure = true  #不验证安全证书
EOF
```

设置 service 文件

```bash
cat > /etc/systemd/system/buildkit.service << 'EOF'
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit

[Service]
ExecStart=/usr/local/bin/buildkitd --oci-worker=false --containerd-worker=true

[Install]
WantedBy=multi-user.target
EOF
```

重启 buildkit

```bash
systemctl daemon-reload
systemctl enable buildkit
systemctl start buildkit
systemctl status buildkit
```

测试

```bash
cd $(mktemp -d)
mkcd test

cat > Dockerfile << 'EOF'
FROM alpine
EOF

dockern build --platform arm64,amd64 -t  test1 .
```

## 安装 k8s

配置免密，方便操作

```bash
echo '10.244.244.201 devmaster' >> /etc/hosts
echo '10.244.244.211 devnode1' >> /etc/hosts
echo '10.244.244.212 devnode2' >> /etc/hosts

ssh -p 10240 root@10.244.244.201
ssh -p 10241 root@10.244.244.211
ssh -p 10242 root@10.244.244.212
```

关闭防火墙和 selinux

```bash
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# selinux
# 1、临时关闭
setenforce 0
# 2、永久关闭SELinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
# 3、查看SELinux状态
sestatus
```

关闭 swap

```bash
# 1、临时关闭 swap 分区
swapoff -a

# 2、永久关闭
sed -ri 's/.*swap.*/#&/' /etc/fstab

# 3、查看 swap 分区是否已经关闭，若 swap 一行都显示 0，则表示关闭成功
free -m
```

安装 chrony 服务

```bash
dnf install -y chrony

# 启动 chrony 服务
systemctl start chronyd

# 设置开机自启
systemctl enable chronyd

# 查看 chrony 服务状态
systemctl status chronyd
```

可参考，但不是必要的

```bash
# 修改 /etc/chrony.conf 配置文件

# 1、编辑 /etc/chrony.conf 配置文件
vim /etc/chrony.conf

# 2、配置阿里云的 ntp 服务
# * 注释掉默认的 ntp 服务器，因为该服务器同步时间略慢
# pool 2.pool.ntp.org iburst

# 格式为：server 服务器ip地址 iburst 
# 添加阿里云的 ntp 服务器，可以多写几个 ntp 服务器，防止第一个服务器宕机，备用的其他 ntp 服务器可以继续进行时间同步
# ip 地址为服务器 ip 地址，iburst 代表的是快速同步时间 
pool ntp1.aliyun.com iburst
pool ntp2.aliyun.com iburst
pool ntp3.aliyun.com iburst
```

配置内核参数

```bash
# 1、编写 kubernetes.conf 配置
vim /etc/sysctl.d/kubernetes.conf

# 2、填写如下内容
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
# net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720

# -------------------------解释-------------------------
# net.bridge.bridge-nf-call-iptables=1：开启 ipv4 的过滤规则
# net.bridge.bridge-nf-call-ip6tables=1：开启 iptables 中 ipv6 的过滤规则
# net.ipv4.ip_forward=1：开启服务器的路由转发功能
# vm.swappiness=0：禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
# vm.overcommit_memory=1：不检查物理内存是否够用
# vm.panic_on_oom=0：开启 OOM
# net.ipv6.conf.all.disable_ipv6=1：禁止 ipv6

# 3、执行命令，使其配置文件生效
modprobe br_netfilter
sysctl -p /etc/sysctl.d/kubernetes.conf
1
```

开启 kube-proxy 的 ipvs 前置条件

从 kubernetes 的 1.8 版本开始，kube-proxy 引入了 ipvs 模式，ipvs 模式与 iptables 同样基于 Netfilter，但是 ipvs 模式采用的是 hash 表，因此当 service 数量达到一定规模时，hash 查表的速度优势就会显现出来，从而提高 service 的服务性能

```bash
# 1、安装ipvsadm 和 ipset
dnf -y install ipvsadm ipset

# 2、编辑 ipvs.modules 配置文件，使其永久生效

mkdir -p /etc/sysconfig/modules
vim /etc/sysconfig/modules/ipvs.modules

# 3、填写如下内容
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- br_netfilter
modprobe -- nf_conntrack

# 4、设置文件权限
chmod 755 /etc/sysconfig/modules/ipvs.modules

# 5、查看是否已经正确加载所需的内核模块
bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack

vim /etc/modules-load.d/ipvs.conf
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
br_netfilter
nf_conntrack
```

添加源

```bash
# 1、编辑 kubernetes.repo 文件
vim /etc/yum.repos.d/kubernetes.repo

# 2、添加如下内容
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
```

```bash
dnf list kubelet --showduplicates | grep 1.24 | sort -r 

dnf install -y kubelet-1.24.4-0 kubeadm-1.24.4-0 kubectl-1.24.4-0
# 建议安装更高版本的

# dnf versionlock kubelet kubeadm kubectl

dnf install -y iproute-tc
```

修改 kubelet 配置文件，关闭 swap

```bash
# 1、编辑kubelet配置文件
vim /etc/sysconfig/kubelet

# 2、添加 --fail-swap-on=false 参数
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
```

启动

```bash
systemctl enable kubelet
```

查看镜像版本（没什么用，一般是为了从中国区下载）

```bash
kubeadm config images list --kubernetes-version=v1.24.4

kubeadm config images pull
```

初始化 master 节点

```bash
kubeadm config print init-defaults > /data/kubeadm-init.yaml

kubeadm init \
--apiserver-advertise-address=10.244.244.101 \
--apiserver-cert-extra-sans=apiserver.local.liaosirui.com \
--kubernetes-version=v1.24.4 \
--service-cidr=10.3.0.0/16 \
--node-name devmaster1 \
--pod-network-cidr=10.4.0.0/16 \
--control-plane-endpoint="apiserver.local.liaosirui.com:6443" 

# 用不上
# --image-repository registry.aliyuncs.com/google_containers \
```

分发证书

```bash
mkdir -p /etc/kubernetes/pki/etcd
```

```bash
USER="root"
CONTROL_PLANE_IPS="10.0.0.7 10.0.0.8"
for host in ${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:etcd-ca.crt
    # Skip the next line if you are using external etcd
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:etcd-ca.key
done

HOSTNAMES="devmaster2 devmaster3"
for host in ${HOSTNAMES}; do
    scp /etc/kubernetes/pki/ca.crt "${host}":/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/ca.key "${host}":/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.key "${host}":/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.pub "${host}":/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${host}":/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.key "${host}":/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/etcd/ca.crt "${host}":/etc/kubernetes/pki/etcd/ca.crt
    # Skip the next line if you are using external etcd
    scp /etc/kubernetes/pki/etcd/ca.key "${host}":/etc/kubernetes/pki/etcd/ca.key
done
```

加入另外一个 master

```bash
kubeadm join apiserver.local.liaosirui.com:6443 --token qjjhtw.ngayg1wa1xo3q72w \
    --discovery-token-ca-cert-hash sha256:b55ba9deff1b7d08de9a4a4adcef02c71da37f413fd2aafa0144f7bca49b1484 --control-plane --apiserver-advertise-address=10.244.244.102 --node-name devmaster2

kubeadm join apiserver.local.liaosirui.com:6443 --token qjjhtw.ngayg1wa1xo3q72w \
    --discovery-token-ca-cert-hash sha256:b55ba9deff1b7d08de9a4a4adcef02c71da37f413fd2aafa0144f7bca49b1484 --control-plane --apiserver-advertise-address=10.244.244.103 --node-name devmaster3
```

配置 kubectl 工具

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

配置 crictl

```bash
/etc/crictl.yaml

runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: false
```

### calico

安装 Calico 网络插件

```bash
curl https://docs.projectcalico.org/manifests/calico.yaml -O calico.yaml
```

修改网段

```bash
# 1、修改calico.yaml配置文件
vim calico.yaml

# 由于calico.yaml配置文件中使用的pod cidr地址段默认为192.168.0.0/16，
# 与在kubeadm init初始化master节点时，指定的–pod-network-cidr地址段10.4.0.0/16不同
# 所以需要修改calico配置文件，取消CALICO_IPV4POOL_CIDR变量和value前的注释，并将value值设置为与--pod-network-cidr指定地址段相同的值，即：10.4.0.0/16
# 2、取消前面的注释，将value值改为 10.4.0.0/16
- name: CALICO_IPV4POOL_CIDR
  value: "10.4.0.0/16"
```

应用calico网络

```bash
kubectl apply -f calico.yaml
```

配置 kubectl 命令自动补全功能

```bash
# 1、安装 epel-release 和 bash-completion
dnf install -y epel-release bash-completion

# 2、配置 kubectl 命令自动补全
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

### ipvs

配置 kube-proxy 开启 ipvs

```bash
# 1、编辑kube-proxy
kubectl edit cm kube-proxy -n kube-system

# 2、修改mode
mode: ""
# 修改为  mode: "ipvs"

# 3、删除之前运行的资源类型为 pod 的 kube-proxy
kubectl get pod -n kube-system |grep kube-proxy |awk '{system("kubectl delete pod "$1" -n kube-system")}'

# 4、查看 kube-proxy 是否开启 ipvs
ipvsadm -Ln
```

### nginx-ingress

使用 helm 安装

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace


# for test
kubectl create deployment demo --image=httpd --port=80
kubectl expose deployment demo
kubectl create ingress demo-localhost --class=nginx \
  --rule="demo.localdev.me/*=demo:80"
```

安装 chart 后的提示

```bash
An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

### 查看证书过期时间

```bash
# 查看证书时间
kubeadm certs check-expiration
```
