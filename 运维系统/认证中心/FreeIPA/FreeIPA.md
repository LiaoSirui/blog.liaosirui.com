## FreeIPA

FreeIPA 是一个信息安全管理集成解决方案，它结合了 Linux（基于 Fedora）、389 目录服务器、MIT Kerberos、NTP、DNS 以及 Dogtag 证书系统等多种组件。并且为用户提供了网页界面和命令行两种管理方式。

多个 FreeIPA 服务器可以轻松配置在同一个 FreeIPA 域中，以实现数据的冗余备份和系统的横向扩展。389 Directory Server 是 FreeIPA 的核心数据库，提供完整的多主 LDAPv3 目录服务。MIT Kerberos KDC 则负责实现单点登录（Single-Sign-on）功能。Dogtag 项目的集成证书颁发机构（CA）则进一步增强了认证能力。可选地，FreeIPA 还可借助内置的 ISC Bind 服务器来管理域名服务（DNS）。

关于访问控制、权限分配和其他网络管理任务，FreeIPA 允许管理员通过网页界面或 ipa 命令行工具进行集中管理，大大简化了日常运维的流程。

## 部署

FreeIPA 需要 DNS 服务器提供域名解析功能，可以使用 CoreDNS 服务器来承担域名解析的任务。  

Zone（本地区域）：`ipa.lan`

```bash
# 安装 FreeIPA
dnf install -y ipa-server
```

执行初始化：

```bash
ipa-server-install
```

初始化过程示例：

```bash
# 安装日志存放位置
The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.
Version 4.12.2
# 安装包含的组件，默认 * 星号都是要安装的
This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Configure the NTP client (chronyd)
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure SID generation
  * Configure the KDC to enable PKINIT
# 按回车键，开始安装
To accept the default shown in brackets, press the Enter key.
# 是否配置集群的 bind DNS，由于使用外部的 CoreDNS，所以使用默认设置 no
Do you want to configure integrated DNS (BIND)? [no]: 

Enter the fully qualified domain name of the computer
on which you''re setting up server software. Using the form
<hostname>.<domainname>
Example: master.example.com

# 设置服务器主机名，采用默认设置
Server host name [ldap-001.ipa.lan]: 
The domain name has been determined based on the host name.

# 域名配置，使用 CoreDNS 上配置的 Zone
Please confirm the domain name [ipa.lan]: 

# kerberos 域名设置，采用默认的大写
The kerberos protocol requires a Realm name to be defined.
This is typically the domain name converted to uppercase.
Please provide a realm name [IPA.LAN]: 

# 设置 LDAP 目录管理员密码（与 Windows Active Directory 还原目录密码类似）
Certain directory server operations require an administrative user.
This user is referred to as the Directory Manager and has full access
to the Directory for system management tasks and will be added to the
instance of directory server created for IPA.
The password must be at least 8 characters long.
Directory Manager password: 
Password (confirm): 

# 设置 IPA 服务器管理员 admin 的密码
The IPA server requires an administrative user, named 'admin'.
This user is a regular system account used for IPA server administration.
IPA admin password: 
Password (confirm): 

# IPv6 不可用，忽略
Invalid IP address fe80::42:27ff:fe50:c16 for ldap-001.ipa.lan: cannot use link-local IP address fe80::42:27ff:fe50:c16
Invalid IP address fe80::486a:e224:31e4:d1fc for ldap-001.ipa.lan: cannot use link-local IP address fe80::486a:e224:31e4:d1fc
Trust is configured but no NetBIOS domain name found, setting it now.

# 设置 NetBIOS 域名
Enter the NetBIOS name for the IPA domain.
Only up to 15 uppercase ASCII letters, digits and dashes are allowed.
Example: EXAMPLE.
NetBIOS domain name [IPA]: 

# 配置是否启用 chrony 服务器，如果有单独的 chrony 时间服务器这里使用默认 no
Do you want to configure chrony with NTP server or pool address? [no]: 

# 输出前面的设置，并确认没有问题后，输入 yes，开始安装
The IPA Master Server will be configured with:
Hostname:       ldap-001.ipa.lan
IP address(es): 192.168.1.3
Domain name:    ipa.lan
Realm name:     IPA.LAN

The CA will be configured with:
Subject DN:   CN=Certificate Authority,O=IPA.LAN
Subject base: O=IPA.LAN
Chaining:     self-signed

Continue to configure the system with these values? [no]: yes

# 开始安装，整体过程需要几分钟
The following operations may take some minutes to complete.
Please wait until the prompt is returned.
.....（略）

# 出现以下信息，说明安装成功
Next steps:
        # 1. 需要配置防火墙开启以下端口
        1. You must make sure these network ports are open:
                TCP Ports:
                  * 80, 443: HTTP/HTTPS
                  * 389, 636: LDAP/LDAPS
                  * 88, 464: kerberos
                  * 53: bind
                UDP Ports:
                  * 88, 464: kerberos
                  * 53: bind
                  * 123: ntp
        # 2. 可以通过 ipa 命令或者 WebUI 进行用户、组、计算机等管理
        2. You can now obtain a kerberos ticket using the command: 'kinit admin'
           This ticket will allow you to use the IPA tools (e.g., ipa user-add)
           and the web user interface.

Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
The ipa-server-install command was successful
```

如果在安装过程中，出现任何异常问题，可以使用以下命令卸载，再重装安装

```bash
ipa-server-install --uninstall
```

升级

```bash
ipa-server-upgrade
```

Rocky Linux 提供了 freeipa-4 防火墙服务，用于开启 FreeIPA 所需的相关端口，包括：http、https、kerberos、kpasswd、ldap、ldaps 等。具体端口信息可参考：/usr/lib/firewalld/services/freeipa-4.xml。此外，也可以根据实际需求，单独设置某个服务端口，例如：freeipa-ldap 或 freeipa-ldaps。
