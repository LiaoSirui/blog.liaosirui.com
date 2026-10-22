## LDAP 协议

LDAP 是轻量目录访问协议（Lightweight Directory Access Protocol）

主要用于查询和修改目录服务提供者（如 Active Directory）中的项目，它以树状结构存储数据库，读的性能高，但写入性能差，在企业中被广泛用于管理用户、组织结构以及权限等（不经常变更的数据）

此外，AD（Active Directory）是微软实现的支持 LDAP 协议的数据库

## LDAP 基础概念

DN（Distinguished Name），专有名称，LDAP中对象的唯一路径，一般而言由下面的几部分组成：

- DC（Domain component）一般为公司名，域组件，可以理解为域名的组成部分，LDAP中至少有一个DC。如 `mydomain.org` 可以表示为 `dc=mydomain,dc=org`
- OU（Organisation Unit）组织单元，类比公司中的部门，最多可以有四级，每级最长 32 个字符，可以为中文
- CN（Common Name）代表一个具体实例，即具体用户的名称（非路径），为用户名或者服务器名，最长可以到 80 个字符，可以为中文

![img](./.assets/LDAP/dit.png)

### LDAP 解析

举例，如果张三在 A 公司（hello.org）的 IT 部门，那么张三的 DN 为`CN=ZhangSan,OU=ITDepartment,DC=hello,DC=org`，查找顺序则由 DC 到 CN，即：

1. DC=org
2. DC=hello
3. OU=ITDepartment
4. CN=ZhangSan

此外，如果 A 公司还有子公司，假如李四在子公司（subdomain.hello.org）的销售部，那么李四的 DN 为`CN=LiSi,OU=SaleDepartment,DC=subdomain,DC=hello,DC=org`，查找顺序也是由 DC 到 CN，即：

1. DC=org
2. DC=hello
3. DC=subdomain
4. OU=SaleDepartment
5. CN=LiSi

## LDAP 搜索

通过查询目录，可以直接收集到要求的数据。查询目录需要指定两个要素

- BaseDN
- 过滤规则

比如指定 BaseDN 为 `DC=test.DC=local` 就是以 `DC=test.DC=local`为根往下搜索

LDAP 搜索过滤器语法有以下子集：

- 用与号 (`&`) 表示的 AND 运算符
- 用竖线 (`|`) 表示的 OR 运算符
- 用感叹号 (`!`) 表示的 NOT 运算符
- 用名称和值表达式的等号 (`=`) 表示的相等比较
- 用名称和值表达式中值的开头或结尾处的星号 (`*`) 表示的通配符

工具 ldapsearch

## LDAP 加密

- LDAP over SSL（即 ldaps）

Ldap 默认不加密情况下使用 389 端口，当使用 ldaps 的时候使用 636 端口

连接方式

```bash
ldapsearch -H ldaps://127.0.0.1
```

- LDAP over TLS（即 ldap + TLS）StartTLS

LDAP over TLS 可以简单理解为 ldaps 的升级；它默认使用 389 端口，但是会通讯的时候加密；客户端连接 LDAP 时，需要指明通讯类型为 TLS

连接方式

```bash
ldapsearch -ZZ -H ldap://127.0.0.1
```

建议关闭 ldaps 方式，仅开启 LDAP over TLS

## URLlist

| **URL**      | **Protocol**          | **Transport**            |
| ------------ | --------------------- | ------------------------ |
| `ldap:///`   | LDAP                  | TCP port 389             |
| `pldap:///`  | proxied LDAP          | TCP port 389             |
| `ldaps:///`  | LDAP over SSL         | TCP port 636             |
| `pldaps:///` | proxied LDAP over SSL | TCP port 636             |
| `ldapi:///`  | LDAP                  | IPC (Unix-domain socket) |

## 参考文档

- <https://wiki.eryajf.net/pages/ea10fa/>

OpenLDAP

参考文档：<https://notes.lzwang.ltd/DevOps/Docker/DeployService/docker_deploy_ldap/#_3>

<https://hebye.com/docs/ldap/ldap-1d9caupabevnc>