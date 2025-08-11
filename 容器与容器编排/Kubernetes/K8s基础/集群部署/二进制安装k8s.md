## 安装 runc

使用如下命令安装 runc

最新的 Release 可以从 <https://github.com/opencontainers/runc/releases> 获取

```bash
export RUNC_VERSION=v1.1.6

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
export CONTAINERD_VERSION=v1.6.20

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

cat > /etc/systemd/system/containerd.service.d/http_proxy.conf << __EOF__
[Service]
Environment="HTTP_PROXY=http://proxy.local.liaosirui.com:8899"
Environment="HTTPS_PROXY=http://proxy.local.liaosirui.com:8899"
Environment="ALL_PROXY=socks5://proxy.local.liaosirui.com:8899"
Environment="NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.liaosirui.com"
__EOF__

systemctl daemon-reload

systemctl restart containerd
```

## 安装 nerdctl

最新 release 可以从：<https://github.com/containerd/nerdctl/releases> 获取

下载 nerdctl

```bash
export NERDCTL_VERSION=v1.3.1

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
echo "alias ndocker='nerdctl --namespace k8s.io'"  >> ~/.bashrc
echo "alias ndocker-compose='nerdctl compose'"  >> ~/.bashrc
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
export BUILD_KIT_VERSION=v0.11.6

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
  http = true        # 使用 http 协议
  insecure = true    # 不验证安全证书
[registry."mmzwwwdocker.xxxxxx.com:31104"]
  mirrors = ["mmzwwwdocker.xxxxxxx.com:31104"]
  http = true      # 使用 http 协议
  insecure = true  # 不验证安全证书
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
mkdir test && cd test

cat > Dockerfile << 'EOF'
FROM alpine
EOF

ndocker build --platform arm64,amd64 -t  test1 .
```

## 安装 k8s

配置免密，方便操作

```bash
echo '10.244.244.11 dev-master' >> /etc/hosts
echo '10.244.244.12 dev-node12' >> /etc/hosts
echo '10.244.244.13 dev-node13' >> /etc/hosts

ssh root@10.244.244.11
ssh root@10.244.244.12
ssh root@10.244.244.13

ssh root@dev-master
ssh root@dev-node12
ssh root@dev-node13
```

关闭防火墙和 selinux

```bash
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
```

关闭 selinux

```bash
# 1、临时关闭
setenforce 0

# 2、永久关闭SELinux
sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config

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

# 启动 chrony 服务 /设置开机自启
systemctl enable --now chronyd

# 查看 chrony 服务状态
systemctl status chronyd
```

可参考修改 ntp 服务器地址，但不是必要的

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

# 3、编辑内核模块自动加载文件
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
modprobe br_netfilter

# 4、执行命令，使其配置文件生效
sysctl -p /etc/sysctl.d/kubernetes.conf
```

> 解释
>
> - `net.bridge.bridge-nf-call-iptables=1`：开启 ipv4 的过滤规则
>
> - `net.bridge.bridge-nf-call-ip6tables=1`：开启 iptables 中 ipv6 的过滤规则
>
> - `net.ipv4.ip_forward=1`：开启服务器的路由转发功能
>
> - `vm.swappiness=0`：禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
>
> - `vm.overcommit_memory=1`：不检查物理内存是否够用
>
> - `vm.panic_on_oom=0`：开启 OOM
>
> - `net.ipv6.conf.all.disable_ipv6=1`：禁止 ipv6

添加源

```bash
# 1、编辑 kubernetes.repo 文件
vim /etc/yum.repos.d/kubernetes.repo

# 2、添加如下内容
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=0
gpgcheck=0
repo_gpgcheck=0
```

查看可以安装的 k8s 版本

```bash
dnf list --enablerepo=kubernetes kubelet --showduplicates | grep 1.27 | sort -r 

# 建议安装最新版本的
dnf install --enablerepo=kubernetes -y \
  iproute-tc \
  kubelet-1.27.1-0 \
  kubeadm-1.27.1-0 \
  kubectl-1.27.1-0
# dnf install -y 'dnf-command(versionlock)' && dnf versionlock kubelet kubeadm kubectl
```

修改 kubelet 配置文件，关闭 swap

```bash
# 1、编辑kubelet配置文件
vim /etc/sysconfig/kubelet

# 2、添加 --fail-swap-on=false 参数
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
```

设置 kubelet 开机自动启动

```bash
systemctl enable --now kubelet
```

查看镜像版本（没什么用，一般是为了从中国可访问的镜像仓库下载

```bash
> kubeadm config images list --kubernetes-version=v1.27.1

registry.k8s.io/kube-apiserver:v1.27.1
registry.k8s.io/kube-controller-manager:v1.27.1
registry.k8s.io/kube-scheduler:v1.27.1
registry.k8s.io/kube-proxy:v1.27.1
registry.k8s.io/pause:3.9
registry.k8s.io/etcd:3.5.7-0
registry.k8s.io/coredns/coredns:v1.10.1
```

指定镜像仓库

```bash
> kubeadm config images list --kubernetes-version=v1.27.1 \
  --image-repository=harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io

harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/kube-apiserver:v1.27.1
harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/kube-controller-manager:v1.27.1
harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/kube-scheduler:v1.27.1
harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/kube-proxy:v1.27.1
harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/pause:3.9
harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/etcd:3.5.7-0
harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io/coredns:v1.10.1
```

如果有代理，直接拉取镜像即可，也可指定镜像仓库

```bash
kubeadm config images pull --kubernetes-version=v1.27.1 \
  --image-repository=harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io
```

初始化 master 节点

```bash
mkdir /root/.kube

kubeadm config print init-defaults > /root/.kube/kubeadm-init.yaml

kubeadm init \
  --apiserver-advertise-address=10.244.244.11 \
  --apiserver-cert-extra-sans=apiserver.local.liaosirui.com \
  --kubernetes-version=v1.27.1 \
  --service-cidr=10.3.0.0/16 \
  --pod-network-cidr=10.4.0.0/16 \
  --node-name dev-master \
  --control-plane-endpoint="apiserver.local.liaosirui.com:6443" \
  --image-repository=harbor.local.liaosirui.com:5000/3rdparty/registry.k8s.io
```

查看节点加入的 token

```bash
 kubeadm token create --print-join-command
```

加入节点

```bash
# devnode1 
kubeadm join apiserver.local.liaosirui.com:6443 \
  --node-name devnode1 \
  --token 67n3f5.xjvndwcv4f7hzorl \
	--discovery-token-ca-cert-hash sha256:6788e66a9ad6d8f1414f9d13f282ba82bf5f5a01b4752fd26a656bb05ff59ec8

# devnode2
kubeadm join apiserver.local.liaosirui.com:6443 \
  --node-name devnode2 \
  --token 67n3f5.xjvndwcv4f7hzorl \
	--discovery-token-ca-cert-hash sha256:6788e66a9ad6d8f1414f9d13f282ba82bf5f5a01b4752fd26a656bb05ff59ec8
```

如果不使用 kubeproxy 可以使用增加 nodeSelector 的方式来关闭

```bash
> kubectl edit daemonset -n kube-system kube-proxy
...
      nodeSelector:
+       kube-proxy: disabled
        kubernetes.io/os: linux
...
```

## kubectl

配置 kubectl 工具

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
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

## crictl

配置 crictl

```bash
cat << _EOF_ > /etc/crictl.yaml
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: false
_EOF_
```

## 多 master 节点部署

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
