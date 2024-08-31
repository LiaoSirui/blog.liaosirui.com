
```bash
dnf -y install 'dnf-command(copr)'

dnf -y copr enable rhcontainerbot/container-selinux
```

将在我们的系统中添加 CRI-O 1.24 存储库。将 CRI-O 的版本号导出为变量。

```bash
export KUBE_VERSION=1.24

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/devel:kubic:libcontainers:stable.repo

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${KUBE_VERSION}.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${KUBE_VERSION}/CentOS_8/devel:kubic:libcontainers:stable:cri-o:${KUBE_VERSION}.repo
```

列出系统上可用的存储库：

```bash
dnf -y repolist
```

配置存储库后，在 Rocky Linux 8 上安装 CRI-O 容器运行时：

```bash
dnf install -y cri-o cri-tools
```

启动 crio 服务

```bash
systemctl enable --now crio
```

检查服务状态

```bash
systemctl status crio
```

CRI-O sock 文件的路径是：

```bash
ls /var/run/crio/crio.sock
```

拉取镜像

```bash
crictl pull alpine:latest
```

查看镜像列表

```bash
crictl images
```

要设置容器注册表并设置优先级，请编辑文件：

```bash
vim /etc/containers/registries.conf
```

示例配置

```bash
unqualified-search-registries = ["registry.fedoraproject.org", "registry.access.redhat.com", "registry.centos.org", "docker.io"]
```