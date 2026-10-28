## Kerberos

Kerberos 是一种计算机网络认证协议，它允许某实体在非安全网络环境下通信，向另一个实体以一种安全的方式证明自己的身份。具体请参考 <https://web.mit.edu/kerberos>。

AD（Active Directory），即活动目录。您可以将 AD 简单理解成一个数据库，其存储有关网络对象的信息，方便管理员和用户查找所需信息。

SPN（Service Principal Name），即服务主体名称。是服务实例的唯一标识符。

在 Kerberos 认证过程中，使用 SPN 将服务实例与服务登录账号关联。所以，必须在内置计算机账户或用户账户下为服务器注册 SPN。对于内置账户，SPN 会自动注册。如果需要在域用户账户下运行服务，必须要为使用的账户手动注册 SPN。

## 参考资料

- <https://support.huaweicloud.com/bestpractice-oneaccess/oneaccess_05_0137.html>

## Kerberos 使用

### klist

klist 命令用于列出 Kerberos 凭据缓存中保存的 Kerberos 主体和票据，或者列出密钥表文件中保存的密钥

（1）列出当前用户凭据缓存中的票据：

```text
klist
```

该命令将显示当前用户在凭据缓存中保存的 Kerberos 票据的详细信息，如票据有效期、加密类型和服务主体。

（2）列出密钥表文件中的密钥：

```text
klist -k
```

该命令将显示密钥表文件中保存的所有密钥的详细信息，包括加密类型、版本号和主体名称。

（3）查看凭据缓存中票据的加密类型：

```text
klist -e
```

该命令将显示凭据缓存中每个票据的加密类型，以及与之关联的会话密钥的加密类型。

（4）列出缓存集合中的所有缓存：

```text
klist -l
```

如果系统中有多个凭据缓存可用，该命令将显示一个表格，总结所有缓存的信息。

（5）列出缓存集合中所有缓存的内容：

```text
klist -A
```

如果系统中有多个凭据缓存可用，该命令将显示每个缓存的详细内容，包括票据的有效期、加密类型和服务主体。

（6）显示缓存凭证

```bash
klist -ef
```

## FAST

在 Active Directory 域控制器 (DC) 上启用和配置支持 FAST (Flexible Authentication Secure Tunneling) 身份验证，可以按照以下步骤进行。FAST 是 Kerberos 协议的一项增强功能，通过保护认证数据的完整性和保密性，提高了 Kerberos 身份验证的安全性。

在 PowerShell 中运行以下命令，查看域和林功能级别：

```bash
Get-ADDomain | Select-Object Name, DomainMode
Get-ADForest | Select-Object ForestMode
```

