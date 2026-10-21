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
```

加入域

```bash
# 加入域，并且需要 administrator 的密码
realm join xxx.com

# 如果不是 administrator 用户，是其他用户，可以添加一个参数
realm join -U username xxx.com 
```

加入后验证一下

```bash
# 验证一下
id administrator@xxx.com

# 输出如下，即可
# uid=404200500(administrator) gid=404200513(domain users) 组=404200513(domain users),404200572(denied rodc password replication group),404200512(domain admins),404200518(schema admins),404200519(enterprise admins),404200520(group policy creator owners)
```

修改 sssd.conf，使域账号登录不用输入 `@` 后缀

```bash
vim /etc/sssd/sssd.conf

fallback_homedir = /home/%u
use_fully_qualified_names = False
```

同时赋予 sssd.conf 600 权限和变更所有者为 root，否则重启后进程会启动失败

```bash
chmod 600 /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf

systemctl restart sssd
```

再次查看用户 id

```
id sirui.liao
uid=404201230(sirui.liao) gid=404200513(domain users) 组=404200513(domain users),404200512(domain admins)
```

第一次使用域账号登录时，自动创建用户目录

```
pam-auth-update --enable mkhomedir
```

赋予域账号sudo权限

```bash
VISUAL="vim" ; export VISUAL
EDITOR="$VISUAL" ; export EDITOR
sudo -E visudo
```

添加如下配置

```bash
sirui\.liao ALL=(ALL)      ALL
# %domain\ users  ALL=(ALL)      ALL
```

## 故障处理整理

（1）GSSAPI Error: Unspecified GSS failure. Minor code may provide more information (Server not found in Kerberos database)

```bash
vim /etc/krb5.conf

[libdefaults]
default_realm = xxx.com
rdns = false
```

（2）add `dyndns_update = false` to `sssd.conf`

[`https://sssd.io/design-pages/active_directory_dns_updates.html`](https://sssd.io/design-pages/active_directory_dns_updates.html)

（3）关闭对 FAST (Flexible Authentication Secure Tunneling) 的强制校验

```ini
[libdefaults]
armor_ccache = false
canonicalize = false
```

- **`armor_ccache = false`**：禁用用于 FAST 的缓存（Armor Cache）。
- **`canonicalize = false`**：阻止客户端自动使用 FAST 重定向身份验证。

修改 Kerberos 配置后，重启依赖 Kerberos 的服务以应用更改。例如：

```bash
sudo systemctl restart sssd
```

验证 Kerberos 是否正常工作且不再使用 FAST

```bash
kinit user@DOMAIN.COM
klist
```

