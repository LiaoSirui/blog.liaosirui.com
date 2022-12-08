## 简介

dnf - 新一代的 RPM 软件包管理器

DNF 包管理器作为 YUM 包管理器的升级替代品，它能自动完成更多的操作。

## 在旧的发行版中安装 DNF 包管理器

DNF 并未默认安装在 RHEL 或 CentOS 7系统中，为了安装 DNF ，必须先安装并启用 epel-release 依赖。

在系统中执行以下命令：

```bash
yum install epel-release
```

使用 epel-release 依赖中的 YUM 命令来安装 DNF 包。在系统中执行以下命令：

```bash
yum install dnf
```

## 使用

基于 rocky linux 9

```bash
NAME="Rocky Linux"
VERSION="9.1 (Blue Onyx)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="9.1"
PLATFORM_ID="platform:el9"
PRETTY_NAME="Rocky Linux 9.1 (Blue Onyx)"
ANSI_COLOR="0;32"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:rocky:rocky:9::baseos"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
ROCKY_SUPPORT_PRODUCT="Rocky-Linux-9"
ROCKY_SUPPORT_PRODUCT_VERSION="9.1"
REDHAT_SUPPORT_PRODUCT="Rocky Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="9.1"
```

### 查看 DNF 包管理器版本

用处：该命令用于查看安装在您系统中的 DNF 包管理器的版本

```bash
dnf –version
```

版本信息：

```plain
4.12.0
  Installed: dnf-0:4.12.0-4.el9.noarch at Fri Dec  2 08:10:03 2022
  Built    : Rocky Linux Build System (Peridot) <releng@rockylinux.org> at Tue Nov 15 09:28:34 2022

  Installed: rpm-0:4.16.1.3-19.el9_1.x86_64 at Fri Dec  2 08:09:20 2022
  Built    : Rocky Linux Build System (Peridot) <releng@rockylinux.org> at Tue Nov 15 16:42:25 2022
```

### 查看系统中可用的 DNF 软件库

用处：该命令用于显示系统中可用的 DNF 软件库

```bash
dnf repolist
```

默认开启的仓库如下：

```bash
repo id                                                 repo name
appstream                                               Rocky Linux 9 - AppStream
baseos                                                  Rocky Linux 9 - BaseOS
extras                                                  Rocky Linux 9 - Extras
```

一些 rocky9 可用的源：

```bash
# 提供 htop 等工具
dnf install -y epel-release

https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo

# 暂无 rhel9
dnf install -y https://developer.download.nvidia.com/compute/machine-learning/repos/rhel8/x86_64/nvidia-machine-learning-repo-rhel8-1.0.0-1.x86_64.rpm
```

注意默认的开发套件版本已经很高，不需要使用 Software Collections ( SCL ) Repository

```bash
# gcc --version
gcc (GCC) 11.3.1 20220421 (Red Hat 11.3.1-2)
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# g++ --version
g++ (GCC) 11.3.1 20220421 (Red Hat 11.3.1-2)
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# ldd --version
ldd (GNU libc) 2.34
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
Written by Roland McGrath and Ulrich Drepper.

# make --version
GNU Make 4.3
Built for x86_64-redhat-linux-gnu
Copyright (C) 1988-2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

# skopeo --version
skopeo version 1.9.4-dev

# node -v
v16.17.1

# go version
go version go1.18.4 linux/amd64

# python3 --version
# 注意这个发行版不再提供 python2
Python 3.9.14
```

### 查看系统中可用和不可用的所有的 DNF 软件库

用处：该命令用于显示系统中可用和不可用的所有的 DNF 软件库

```bash
dnf repolist all
```

全部仓库如下：

```bash
repo id                             repo name                                                                          status
appstream                           Rocky Linux 9 - AppStream                                                          enabled
appstream-debug                     Rocky Linux 9 - AppStream - Debug                                                  disabled
appstream-source                    Rocky Linux 9 - AppStream - Source                                                 disabled
baseos                              Rocky Linux 9 - BaseOS                                                             enabled
baseos-debug                        Rocky Linux 9 - BaseOS - Debug                                                     disabled
baseos-source                       Rocky Linux 9 - BaseOS - Source                                                    disabled
crb                                 Rocky Linux 9 - CRB                                                                disabled
crb-debug                           Rocky Linux 9 - CRB - Debug                                                        disabled
crb-source                          Rocky Linux 9 - CRB - Source                                                       disabled
devel                               Rocky Linux 9 - Devel WARNING! FOR BUILDROOT ONLY DO NOT LEAVE ENABLED             disabled
extras                              Rocky Linux 9 - Extras                                                             enabled
extras-debug                        Rocky Linux 9 - Extras Debug                                                       disabled
extras-source                       Rocky Linux 9 - Extras Source                                                      disabled
highavailability                    Rocky Linux 9 - High Availability                                                  disabled
highavailability-debug              Rocky Linux 9 - High Availability - Debug                                          disabled
highavailability-source             Rocky Linux 9 - High Availability - Source                                         disabled
nfv                                 Rocky Linux 9 - NFV                                                                disabled
nfv-debug                           Rocky Linux 9 - NFV Debug                                                          disabled
nfv-source                          Rocky Linux 9 - NFV Source                                                         disabled
plus                                Rocky Linux 9 - Plus                                                               disabled
plus-debug                          Rocky Linux 9 - Plus - Debug                                                       disabled
plus-source                         Rocky Linux 9 - Plus - Source                                                      disabled
resilientstorage                    Rocky Linux 9 - Resilient Storage                                                  disabled
resilientstorage-debug              Rocky Linux 9 - Resilient Storage - Debug                                          disabled
resilientstorage-source             Rocky Linux 9 - Resilient Storage - Source                                         disabled
rt                                  Rocky Linux 9 - Realtime                                                           disabled
rt-debug                            Rocky Linux 9 - Realtime Debug                                                     disabled
rt-source                           Rocky Linux 9 - Realtime Source                                                    disabled
sap                                 Rocky Linux 9 - SAP                                                                disabled
sap-debug                           Rocky Linux 9 - SAP Debug                                                          disabled
sap-source                          Rocky Linux 9 - SAP Source                                                         disabled
saphana                             Rocky Linux 9 - SAPHANA                                                            disabled
saphana-debug                       Rocky Linux 9 - SAPHANA Debug                                                      disabled
saphana-source                      Rocky Linux 9 - SAPHANA Source                                                     disable
```

常用的默认关闭的源：

```
plus
devel
crb
```

### 列出所有 RPM 包

用处：该命令用于列出用户系统上的所有来自软件库的可用软件包和所有已经安装在系统上的软件包

```bash
dnf list
```

### 列出所有安装了的 RPM 包

用处：该命令用于列出所有安装了的 RPM 包

```bash
dnf list installed
```

### 列出所有可供安装的 RPM 包

用处：该命令用于列出来自所有可用软件库的可供安装的软件包

```bash
dnf list available
```

### 搜索软件库中的 RPM 包

用处：当你不知道你想要安装的软件的准确名称时，你可以用该命令来搜索软件包。你需要在 ”search” 参数后面键入软件的部分名称来搜索。（在本例中使用”nano”）

```bash
dnf search nano
```

### 查找某一文件的提供者

用处：当你想要查看是哪个软件包提供了系统中的某一文件时，你可以使用这条命令。（在本例中，将查找 ”/bin/bash” 这个文件的提供者）

```bash
dnf provides /bin/bash
```

可以直接搜索命令名

```bash
# dnf provides jq
Last metadata expiration check: 2:25:09 ago on Wed Dec  7 14:32:31 2022.
jq-1.6-12.el9.i686 : Command-line JSON processor
Repo        : appstream
Matched from:
Provide    : jq = 1.6-12.el9

jq-1.6-12.el9.x86_64 : Command-line JSON processor
Repo        : @System
Matched from:
Provide    : jq = 1.6-12.el9

jq-1.6-12.el9.x86_64 : Command-line JSON processor
Repo        : appstream
Matched from:
Provide    : jq = 1.6-12.el9

```

### 查看软件包详情

用处：当你想在安装某一个软件包之前查看它的详细信息时，这条命令可以帮到你。（在本例中，将查看”nano”这一软件包的详细信息）

```bash
dnf info nano
```

### 安装软件包

用处：使用该命令，系统将会自动安装对应的软件及其所需的所有依赖（在本例中，将用该命令安装 nano 软件）

```bash
dnf install nano
```

### 升级软件包

用处：该命令用于升级制定软件包（在本例中，将用命令升级 ”systemd” 这一软件包）

```bash
dnf update systemd
```

### 检查系统软件包的更新

用处：该命令用于检查系统中所有软件包的更新

```bash
dnf check-update
```

### 升级所有系统软件包

用处：该命令用于升级系统中所有有可用升级的软件包

```bash
dnf update 或 dnf upgrade
```

### 删除软件包

用处：删除系统中指定的软件包（在本例中将使用命令删除”nano”这一软件包）

```bash
dnf remove nano 或 dnf erase nano
```

### 删除无用孤立的软件包

用处：当没有软件再依赖它们时，某一些用于解决特定软件依赖的软件包将会变得没有存在的意义，该命令就是用来自动移除这些没用的孤立软件包。

```bash
dnf autoremove
```

### 删除缓存的无用软件包

用处：在使用 DNF 的过程中，会因为各种原因在系统中残留各种过时的文件和未完成的编译工程。可以使用该命令来删除这些没用的垃圾文件。

```bash
dnf clean all
```

### 获取有关某条命令的使用帮助

用处：该命令用于获取有关某条命令的使用帮助（包括可用于该命令的参数和该命令的用途说明）（本例中将使用命令获取有关命令”clean”的使用帮助）

```bash
dnf help clean
```

### 查看所有的 DNF 命令及其用途

用处：该命令用于列出所有的 DNF 命令及其用途

```bash
dnf help
```

### 查看 DNF 命令的执行历史

用处：您可以使用该命令来查看您系统上 DNF 命令的执行历史。通过这个手段您可以知道在自您使用 DNF 开始有什么软件被安装和卸载。

```bash
dnf history
```

### 查看所有的软件包组

用处：该命令用于列出所有的软件包组

```bash
dnf grouplist
```

可以查看所有的软件包组

```bash
# dnf grouplist
Last metadata expiration check: 2:27:22 ago on Wed Dec  7 14:32:31 2022.
Available Environment Groups:
   Server with GUI
   Minimal Install
   Workstation
   KDE Plasma Workspaces
   Custom Operating System
   Virtualization Host
Installed Environment Groups:
   Server
Installed Groups:
   Container Management
   Development Tools
   Headless Management
Available Groups:
   Fedora Packager
   Xfce
   Legacy UNIX Compatibility
   Console Internet Tools
   .NET Development
   Graphical Administration Tools
   Network Servers
   RPM Development Tools
   Scientific Support
   Security Tools
   Smart Card Support
   System Tools
```

常用的为
```bash
Development Tools # 开发工具包
Container Management # 包含 podman、skopeo、buildah 等工具，慎重安装，与现有 docker / containerd 体系冲突
Fonts # 字体库
```

### 安装一个软件包组

用处：该命令用于安装一个软件包组（本例中，将用命令安装”Educational Software”这个软件包组）

```bash
dnf groupinstall 'Educational Software'
```

安装开发工具集

```bash
dnf groupinstall 'Development Tools'
```

### 升级一个软件包组中的软件包

用处：该命令用于升级一个软件包组中的软件包（本例中，将用命令升级”Educational Software”这个软件包组中的软件）

```bash
dnf groupupdate 'Educational Software'
```

### 删除一个软件包组

用处：该命令用于删除一个软件包组（本例中，将用命令删除”Educational Software”这个软件包组）

```bash
dnf groupremove 'Educational Software'
```

### 从特定的软件包库安装特定的软件

用处：该命令用于从特定的软件包库安装特定的软件（本例中将使用命令从软件包库 epel 中安装 phpmyadmin 软件包）

```bash
dnf –enablerepo=epel install phpmyadmin
```

例如平时关闭 k8s 的库

```
# cat /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=0
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
```

软件查找可以从：<https://pkgs.org/>

再例如安装 `hdf5-devel`

<img src=".assets/image-20221207171414129.png" alt="image-20221207171414129" style="zoom:50%;" />

```bash
dnf --enablerepo=devel install -y mysql-devel
```

Rocky8 安装 `libaec-devel`

<img src=".assets/image-20221207171537032.png" alt="image-20221207171537032" style="zoom:50%;" />

```bash
dnf --enablerepo=powertools install -y libaec-devel
```

### 更新软件包到最新的稳定发行版

用处：该命令可以通过所有可用的软件源将已经安装的所有软件包更新到最新的稳定发行版

```bash
dnf distro-sync
```

### 重新安装特定软件包

用处：该命令用于重新安装特定软件包（本例中，将使用命令重新安装 ”nano” 这个软件包）

```bash
dnf reinstall nano
```

### 回滚某个特定软件的版本

用处：该命令用于降低特定软件包的版本（如果可能的话）（本例中，将使用命令降低 ”acpid” 这个软件包的版本）

```bash
dnf downgrade acpid
```

样例输出：

```bash
Using metadata from Wed May 20 12:44:59 2015
No match for available package: acpid-2.0.19-5.el7.x86_64
Error: Nothing to do.
```

### 安装特定的版本

先查询版本

```bash
# dnf list kubelet --showduplicates | grep 1.24 | sort -r
kubelet.x86_64                       1.24.8-0                        kubernetes
kubelet.x86_64                       1.24.7-0                        kubernetes
kubelet.x86_64                       1.24.6-0                        kubernetes
kubelet.x86_64                       1.24.5-0                        kubernetes
kubelet.x86_64                       1.24.4-0                        kubernetes
kubelet.x86_64                       1.24.3-0                        kubernetes
kubelet.x86_64                       1.24.2-0                        kubernetes
kubelet.x86_64                       1.24.1-0                        kubernetes
kubelet.x86_64                       1.24.0-0                        kubernetes
```

安装指定版本：

```bash
dnf install -y kubelet-1.24.4-0 kubeadm-1.24.4-0 kubectl-1.24.4-0
```

### 固定软件包版本

该功能依赖 dnf 的插件完成

```bash
 dnf install -y "dnf-command(versionlock)"
```

使用示例

```bash
dnf versionlock gcc-*
```

### 仅下载软件包

常用于配置离线构建镜像

```bash
 dnf install [包名] --downloadonly --downloaddir=[文件路径]
```

例如

```bash
# 进入一个临时目录
cd $(mktemp -d)

# 下载软件包（实际使用时，尽量启动一个最小安装的容器来完成）
dnf install skopeo --downloadonly --downloaddir=.

# 下载会包含该软件包及其依赖
# ls
containers-common-1-45.el9_1.x86_64.rpm     criu-libs-3.17-4.el9.x86_64.rpm    fuse3-libs-3.10.2-5.el9.0.1.x86_64.rpm   libnet-1.2-6.el9.x86_64.rpm        slirp4netns-1.2.0-2.el9.x86_64.rpm
container-selinux-2.189.0-1.el9.noarch.rpm  crun-1.5-1.el9.x86_64.rpm          fuse-common-3.10.2-5.el9.0.1.x86_64.rpm  libslirp-4.4.0-7.el9.x86_64.rpm    yajl-2.1.0-21.el9.x86_64.rpm
criu-3.17-4.el9.x86_64.rpm                  fuse3-3.10.2-5.el9.0.1.x86_64.rpm  fuse-overlayfs-1.9-1.el9.x86_64.rpm      skopeo-1.9.4-0.1.el9_1.x86_64.rpm
```



