## Linux Agent

- 下载地址：<https://customerconnect.omnissa.com/downloads/info/slug/desktop_end_user_computing/vmware_horizon/2312>

- <https://cios.dhitechnical.com/VMware/Horizon/VMware.Horizon.8.Ent/VMware%20Horizon%208/>

将 ubuntu 加入 AD 域，使用的是 realm

```bash
apt install realmd sssd-ad sssd-tools adcli -y

realm discover xxx.com
# 有如下输出即可
xxx.com
  type: kerberos
  realm-name: xxx.com
  domain-name: xxx.com
  configured: no
  server-software: active-directory
  client-software: sssd
  required-package: sssd-tools
  required-package: sssd
  required-package: libnss-sss
  required-package: libpam-sss
  required-package: adcli
  required-package: samba-common-bin

# 加入域，并且需要 administrator 的密码
realm join xxx.com

# 如果不是 administrator 用户，是其他用户，可以添加一个参数
realm join -U username xxx.com  

# 验证一下
id administrator@xxx.com

# 输出如下，即可
用户id=582600500(administrator@xxx.com) 组id=582600513(domain users@xxx.com) 组=582600513(domain users@xxx.com),582600512(domain admins@xxx.com),582600518(schema admins@xxx.com),582600572(denied rodc password replication group@xxx.com),582600520(group policy creator owners@xxx.com),582600519(enterprise admins@xxx.com

```

修改 sssd.conf，使域账号登录不用输入 `@` 后缀；同时赋予 sssd.conf 600 权限和变更所有者为 root，否则重启后进程会启动失败

```bash
vi /etc/sssd/sssd.conf

fallback_homedir = /home/%u
use_fully_qualified_names = False

chmod 600 /etc/sssd/sssd.conf

chown root:root /etc/sssd/sssd.conf

systemctl restart sssd

id sz
uid=1854401236(sz) gid=1854400363(domain users) groups=1854400363(domain users)

```

第一次使用域账号登录时，自动创建用户目录

```
pam-auth-update --enable mkhomedir
```

赋予域账号sudo权限

```bash
sudo visudo
%domain\ users  ALL=(ALL)      ALL
```

GSSAPI Error: Unspecified GSS failure. Minor code may provide more information (Server not found in Kerberos database)

```bash
vim /etc/krb5.conf

[libdefaults]
default_realm = xxx.com
rdns = false
```

安装 VHCI（不需要 USB 重定向可以跳过）

```bash
# vhci usb 内核驱动 https://udomain.dl.sourceforge.net/project/usb-vhci/linux%20kernel%20module/vhci-hcd-1.15.tar.gz
tar -zxvf vhci-hcd-1.15.tar.gz
tar -zxvf VMware-horizonagent-linux-x86_64-2103-8.2.0-17771892.tar.gz
cd vhci-hcd-1.15

#这里要用到patch指令。这里的完整路径是horzion安装包的完整路径下的。resources/vhci/patch/vhci.patch路径
#patch -p1 < /full/path/to/agent-path

# 例如 这里的horizon安装包路径为/home/apqa/VMware-horizonagent-linux-x86_64-2103-8.2.0-17771892，那么命令为
patch -p1 < /home/apqa/VMware-horizonagent-linux-x86_64-2103-8.2.0-17771892/resources/vhci/patch/vhci.patch

# 回到上级目录
cd ..

# 将提取的 VHCI 源文件复制到 /usr/src 目录
cp -r vhci-hcd-1.15 /usr/src/usb-vhci-hcd-1.15

# 将以下内容写入/usr/src/usb-vhci-hcd-1.15/dkms.conf
PACKAGE_NAME="usb-vhci-hcd"
PACKAGE_VERSION=1.15
MAKE_CMD_TMPL="make KVERSION=$kernelver"
CLEAN="$MAKE_CMD_TMPL clean"
BUILT_MODULE_NAME[0]="usb-vhci-iocifc"
DEST_MODULE_LOCATION[0]="/kernel/drivers/usb/host"
MAKE[0]="$MAKE_CMD_TMPL"
BUILT_MODULE_NAME[1]="usb-vhci-hcd"
DEST_MODULE_LOCATION[1]="/kernel/drivers/usb/host"
MAKE[1]="$MAKE_CMD_TMPL"
AUTOINSTALL="YES"

# 使用 dkms 安装驱动
dkms add usb-vhci-hcd/1.15
dkms build usb-vhci-hcd/1.15
dkms install usb-vhci-hcd/1.15

# 使用 dkms status 看一下状态
dkms status

# 复制驱动到内核文件夹，至于为什么要这么做，可以参考 https://blog.tianjinkun.com/post/66.html
cp /lib/modules/`uname -r`/updates/dkms/usb-vhci-hcd.ko /lib/modules/`uname -r`/kernel/drivers/usb/host/
cp /lib/modules/`uname -r`/updates/dkms/usb-vhci-iocifc.ko /lib/modules/`uname -r`/kernel/drivers/usb/host/
```

安装 Agent

```bash
apt install openssh-server tshark dkms open-vm-tools-desktop python python-dbus python-gobject make gcc linux-headers-`uname -r` libelf-dev lightdm realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir

cd VMware-horizonview-agent/

./install_viewagent.sh -U no -a yes

Optional parameters
--multiple-session Install or Upgrade Linux Agent to Multiple-Session Mode. Default is Singleton Mode.
-M        yes|no Upgrade the Linux Agent to managed|un-managed agent. Default is yes.
-s        Self signed cert subject DN. By default, installer will use Blast for CN.
-j        JMS SSL keystore password. By default, installer will generate a random string.
-r        yes|no <Do|Not restart system after installation automatically>. Default is no.
-m        yes|no <Install|Bypass smartcard redirection support>. Default is no.
-F        yes|no <Install|Bypass Client Drive Redirection support>. Default is yes.
-f        yes|no <Install|Bypass FIPS mode>. Default is no.(Only support RedHat 7.x/8.x)
-a        yes|no <Install|Bypass audioin support>. Default is no.
-U        yes|no <Install|Bypass USB Redirection support>. Default is no.
-C        yes|no <Install|Bypass Clipboard Redirection support>. Default is yes.
-S        yes|no <Install|Bypass SingleSignOn support>. Default is yes.
-T        yes|no <Install|Bypass TrueSSO support>. Default is no.
```

配置默认桌面

```bash
apt install -y samba krb5-config krb5-user winbind libpam-winbind libnss-winbind

vi /etc/vmware/viewagent-custom.conf

SSODesktopType=UseKdePlasma
```

限制桌面挂载 `/etc/vmvare/config` 中的 `cdrserver.forceByAdmin=FALSE`

参考文档

- <https://blog.csdn.net/mgaofeid/article/details/131577125>
- <https://foxi.buduanwang.vip/vdi/horizon/1087.html/>

- <https://blog.csdn.net/Bksz_guest/article/details/128672998>

多用户会话，托管

```bash
./install_viewagent.sh --multiple-session -M no
```

完整参数：<https://docs.omnissa.com/zh-CN/bundle/Desktops-and-Applications-in-HorizonV2312/page/CommandlineOptionsforInstallingHorizonAgentforLinux.html>

| Parameters | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| -b         | Hostname or IP address of the Horizon Connection Server. This parameter is only supported when you install Horizon Agent in unmanaged mode. |
| -d         | Domain name of the Horizon Connection Server administrator. This parameter is only supported when you install Horizon Agent in unmanaged mode. |