ProFTPd（Pro FTP daemon）也是一款开源 FTP 服务器，类似于 Vsftpd，但高度可定制和可扩展。它提供了广泛的高级功能，如虚拟主机、SSL/TLS 加密和 LDAP 认证，旨在成为一个高度功能丰富的 FTP 服务器

主动和被动

```
# 禁止主动模式访问
<Limit PORT>
  DenyAll
</Limit>

# 禁止被动模式访问
<Limit PASV>
  DenyAll
</Limit>
```

权限设置

```
umask 000 
 此目录下所有用户上传的掩码都是000,这样新文件权限是666,新文件夹是777,这样做是为了保证member传的文件,其他人也可以删,默认掩码是022 
  
<Limit DELE RMD> 
    DenyGroup kefu 
此目录下对于DELE(删除文件)RMD(删除目录)操作加以限制,对kefu组是拒绝,也就保证了kefu组成员无法执行删除操作.如果需要对单个用户(例如member)限制就用 DenyUser member 
 其实就是无法执行(DELE ,RMD)这两个ftp指令  
ProFTP下的参数说明：

CWD：Change Working Directory 改变目录

MKD：MaKe Directory 建立目录的权限

RNFR： ReName FRom 更改目录名的权限

DELE：DELETE 删除文件的权限

RMD：ReMove Directory 删除目录的权限

RETR：RETRieve 从服务端下载到客户端的权限

STOR：STORe 从客户端上传到服务端的权限

READ：可读的权限，不包括列目录的权限，相当于RETR，STAT等

WRITE：写文件或者目录的权限，包括MKD和RMD

DIRS：是否允许列目录，相当于LIST，NLST等权限，还是比较实用的

ALL：所有权限

LOGIN：是否允许登陆的权限
```

接入 AD 域：

```
RequireValidShell     off

<IfModule mod_ldap.c>
# Connection information
LDAPServer ldap://dc01.domain.com/??sub
LDAPAttr uid sAMAccountName
LDAPAuthBinds on

# User information
LDAPBindDN "cn=UserWithBindRights,cn=users,dc=domain,dc=com" "PasswordForUserWithBindRights"
LDAPUsers DC=domain,DC=com (sAMAccountName=%u)

# ID's to use when not using the ones from AD
LDAPDefaultGID    1111
LDAPDefaultUID    1111

# Override the use of AD id's with the default values set.
# Handy when using this setup with a web server that needs read and write
# access to the files and directories uploaded.
LDAPForceDefaultGID on
LDAPForceDefaultUID on

# Switch on the functionality to generate user homes.
LDAPGenerateHomedir on 0775
CreateHome on 0775
# Overide homedir values from AD
LDAPGenerateHomedirPrefix /place/to/generate/user/homes
LDAPForceGeneratedHomedir on

</IfModule>

```

只有当查询通过 OU 进行过滤时，Proftpd 查询才会起作用。这些查询在 LDAP 根级别不起作用，参考：<https://unix.stackexchange.com/questions/79049/configuring-proftpd-and-mod-ldap-c-query-not-working-any-ideas>

其他参考文档：

- <https://blog.csdn.net/jeccisnd/article/details/126341820>
- <https://www.cnblogs.com/tongh/p/16190626.html#%E6%9D%83%E9%99%90%E7%AE%A1%E6%8E%A7>
- <http://vsftpd.beasts.org/vsftpd_conf.html>

创建虚拟用户

```
/usr/bin/ftpasswd \
--passwd --name=ftpuser1 \
--uid=2000 \
--home=/usr/local/proftpd/virtual_user_home/ftpuser1 \
--shell=/bin/bash \
--file=/usr/local/proftpd/etc/passwd
```

