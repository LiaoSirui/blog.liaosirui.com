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
