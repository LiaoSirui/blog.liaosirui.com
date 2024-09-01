## Rocky Linux

安装需要的软件包

```bash
dnf install -y krb5-workstation realmd sssd \
adcli \
oddjob oddjob-mkhomedir \
samba samba-common samba-common-tools
```

确定 DNS 解析正常

将 Linux 机器加入域

## Ubuntu

将 ubuntu 加入 AD 域，使用的是 realm

```bash
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

