## Kerberos

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

