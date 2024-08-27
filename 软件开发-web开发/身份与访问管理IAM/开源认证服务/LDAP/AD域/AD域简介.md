## AD 域简介

会用到的连接端口：

- Microsoft-DS traffic : 445/TCP 445/UDP

- Kerberos : 88/TCP 88/UDP
- LDAP ： 389/TCPAK 636/TCP(如果使用SSL)

- LDAP ping : 389/UDP

- DNS : 53/TCP 53/UDP

访问 AD 的工具

- ADSI 编辑器 微软自带，输入 `adsiedit.msc` 可访问
- ADExplorer ，<https://docs.microsoft.com/en-us/sysinternals/downloads/adexplorer>

## 操作域

### 客户端查看

查看域控所有域用户（管理员）：

```powershell
net user /domain
```

查看当前域指定用户（管理员）：

```powershell
net user zhangsan /domain
```

查看域控用户组（管理员）：

```powershell
net group /domain
```

查看当前域指定组详细信息（管理员）：

```powershell
net group "domain users" /domain
```

查看域控时间：

```powershell
net time /domain
```

### 服务端查看

查看域控域所有域用户详细信息：

```powershell
dsquery user
```

查看域控域指定用户详细信息：

```powershell
dsquery user -name "UserName"
```

查看所有域控制器：

```powershell
dsquery server
```

查看域控组织单元：

```powershell
dsquery ou
```

查看域控计算机：

```powershell
dsquery computer
```

查询最近1周没有活动的用户：

```powershell
dsquery user -inactive 1
```

查询最近1周没有活动的计算机：

```powershell
dsquery computer -inactive 1
```

查询30天未变更密码的计算机：

```powershell
dsquery computer -stalepwd 30
```

禁用最近4周没有活动的计算机：

```powershell
dsquery computer -inactive 4 | dsmod computer -disable yes
```

禁用最近4周没有登陆的用户：

```powershell
dsquery user -inactive 4 | dsmod user -disabled yes
```

### 加入 AD 域

把计算机 `zhangsan-pc`，加入到 `msh.local` 域，30秒后重启

```powershell
netdom join zhangsan-pc /domain:msh.local /UserD:sh.it /PasswordD:P@ssw0rd /reboot:30
```

计算机退出域（默认会立即重启计算机）

```powershell
netdom remove %computername% /domain:domain /UserD:user /PasswordD:password
```

## LDAP

检查使用域账号 bind 是否正常

```bash
ldapsearch -H ldap://xxx.xxx.xxx.xxx:389 -x -D "cn=德哥,ou=digoal,ou=SKYMOBI,dc=sky-mobi,dc=com" -W
```

![img](./.assets/AD域简介/20210312220711462.png)

微软将 Active Directory 划分为若干个分区(这个分区我们称为 Naming Context，简称 NC)，每个 Naming Context 都有其自己的安全边界

微软自定义了的三个预定义的 Naming Context

- Configuration NC(Configuration NC)
- Schema NC(Schema NC)
- Domain NC(DomainName NC)

Configuration NC 内存储的主要是配置信息，关站点，服务，分区和 Active DirectorySchema 的信息，处于根域之下，并复制到林中的每个域控中。

Schema NC 存储的 Active Directory 中存储的对象的定义，个人感觉类似 Mysql 中的元数据库的概念，包含 Schema 信息，定义了 Active Directory 中使用的类和属性。

Domain NC 每个域都有一个域 Naming Context，不同的域内有不同的域 Naming Context，其中包含特定于域的数据。之前我们说过，域内的所有计算机，所有用户的具体信息都存在 Active Directory 底下
