
k8s、docker 等很多功能、特性需要较新的linux内核支持，所以有必要在集群部署前对内核进行升级。

## 查看当前信息

查看系统版本

```bash
cat /etc/redhat-release
```

查看当前内核版本

```bash
uname -r
```

## 仓库

红帽企业版 Linux 仓库网站 <https://www.elrepo.org>，主要提供各种硬件驱动（显卡、网卡、声卡等）和内核升级相关资源；兼容 CentOS7 内核升级。

如下按照网站提示载入 elrepo 公钥及最新 elrepo 版本，然后按步骤升级内核（以安装长期支持版本 kernel-lt 为例）

载入公钥：

``` bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
```

安装 ELRepo：

```bash
yum install -y http://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
# or
rpm -Uvh http://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
```

载入 elrepo-kernel 元数据

```bash
yum --disablerepo=\* --enablerepo=elrepo-kernel repolist
```

查看可用的 rpm 包版本

```bash
yum --disablerepo=\* --enablerepo=elrepo-kernel list available
```

说明：

- lt：long term support，长期支持版本；
- ml：mainline，主线版本；

## 安装内核

安装长期支持版本的 kernel

```bash
yum --disablerepo=\* --enablerepo=elrepo-kernel install -y kernel-lt.x86_64
```

## 更改启动顺序

查看默认启动顺序

```bash
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg
```

由于是使用 EFI 启动，所以为

```bash
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/efi/EFI/centos/grub.cfg
```

```text
0 : CentOS Linux (5.4.191-1.el7.elrepo.x86_64) 7 (Core)
1 : CentOS Linux (3.10.0-1160.62.1.el7.x86_64) 7 (Core)
2 : CentOS Linux (3.10.0-1160.el7.x86_64) 7 (Core)
3 : CentOS Linux (0-rescue-ab25e83b1f644417b54070dca48529a4) 7 (Core)
```

默认启动的顺序是从0开始，新内核是从头插入，所以需要选择 0。

```bash
grub2-set-default 0
```

或者

```bash
grub-set-default 'CentOS Linux (5.4.191-1.el7.elrepo.x86_64) 7 (Core)'
# CentOS Linux (5.4.191-1.el7.elrepo.x86_64) 7 (Core)  这个是具体的版本
```

查看当前实际启动顺序

```bash
grub2-editenv list
```

```text
saved_entry=CentOS Linux (5.4.191-1.el7.elrepo.x86_64) 7 (Core)
```

编辑 /etc/default/grub 文件，设置

```bash
GRUB_DEFAULT=0
```

生成 grub 配置文件，运行 grub2-mkconfig 命令来重新创建内核配置

```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

由于使用 EFI，所以更改为：

```bash
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
```

## 清理旧版本

查看系统中已安装的内核

```bash
rpm -qa | grep kernel
```

删除旧内核

```bash
yum remove -y kernel-devel-3.10.0 kernel-3.10.0 kernel-headers-3.10.0
```

删除旧版本工具包

```bash
yum remove kernel-tools-libs.x86_64 kernel-tools.x86_64 -y
```

安装新版本工具包

```bash
yum --disablerepo=\* --enablerepo=elrepo-kernel install -y \
    kernel-lt-tools.x86_64 \
    kernel-lt-tools-libs.x86_64
```

安装新版本的其他包

```bash
yum --disablerepo=\* --enablerepo=elrepo-kernel install -y \
    kernel-lt-devel.x86_64 \
    kernel-lt-headers.x86_64
```

## Kernel 历史版本

- <https://buildlogs.centos.org/c7-kernels.x86_64/kernel/20200330213326/4.19.113-300.el8.x86_64/>
- <https://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/>

- <http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/>
- <https://mirror.hep.wisc.edu/upstream/cc/elrepo.with.5.19/kernel/el7/x86_64/RPMS/>

```bash
kernel-lt-5.4.278-1.el7.elrepo.x86_64.rpm
kernel-lt-devel-5.4.278-1.el7.elrepo.x86_64.rpm
kernel-lt-headers-5.4.278-1.el7.elrepo.x86_64.rpm
kernel-lt-tools-5.4.278-1.el7.elrepo.x86_64.rpm

http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-tools-4.19.10-1.el7.elrepo.x86_64.rpm
http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-tools-libs-4.19.10-1.el7.elrepo.x86_64.rpm

```

