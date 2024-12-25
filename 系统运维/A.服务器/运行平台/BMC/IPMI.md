## IPMItool

IPMItool 用于访问 IPMI 的功能 - 智能平台管理接口，该系统接口管理和监视带外计算机系统。它是一个命令提示符，用于控制和配置 IPMI 支持的设备。

IPMItool 是一种可用在 linux 系统下的命令行方式的 ipmi 平台管理工具，它支持 ipmi 1.5 规范（最新的规范为 ipmi 2.0）.IPMI 是一个开放的标准，监控，记录，回收，库存和硬件实现独立于主 CPU，BIOS，以及操作系统的控制权。 服务处理器（或底板管理控制器，BMC）的背后是平台管理的大脑，其主要目的是处理自主传感器监控和事件记录功能。

## IPMItool 使用

连接远端

### channel 参数

```
ipmitool channel info
```

- channel setaccess：这是 ipmitool 中的一个命令，用于设置 IPMI 通道的访问权限。
- 1：表示要设置的通道号，这个命令中是通道号为 1。
- 5：表示要设置的用户 ID，这个命令中是用户 ID 为 5。
- `callin=off`：表示禁止该通道的用户通过 IPMI 远程呼叫进行访问。
- `ipmi=on`：表示允许该通道的用户通过 IPMI 进行访问。
- `privilege=4`：表示设置用户的权限等级为 4，即操作员级别权限。

### 修改 IP

```bash
# 打印当前 ipmi 地址配置信息
ipmitool lan print 1

# 设置 id 1 为静态 IP 地址
ipmitool lan set 1 ipsrc static

# 设置 IPMI 地址
ipmitool lan set 1 ipaddr 192.168.17.253

# 设置 IPMI 子网掩码
ipmitool lan set 1 netmask 255.255.255.0

# 设置 IPMI 网关
ipmitool lan set 1 defgw ipaddr 192.168.17.254
```

### 修改账号

```bash
# 显示 IPMI 用户列表
ipmitool user list
# 创建用户，一般服务器有默认的超级用户（root,admin,ADMIN）
ipmitool user set name 2 root
# 创建密码
ipmitool user set password 2 calvin
# 开权限
ipmitool channel setaccess 1 2 callin=on ipi=on link=on privilege=4
# 查看 chanenel 1 的用户信息
ipmitool user list 1

# 可以直接修改超级用户的密码，不用重新创建
# 修改用户 id 1 的密码 为 abc-123
ipmitool user set password 1 abc-123
```



## 参考文档

- <https://www.cnblogs.com/HByang/p/16127044.html>
- <https://cloud.tencent.com/developer/article/2422636>

## 其他问题

Using JNLP file after installing Oracle Java v. 8 Update 351

Open the "java.security" file available in the following directory: `[installation_path]\server\java\jre\lib\security\java.security`

Locate the "jdk.certpath.disabledAlgorithms" property and set it to the following value:

```java
MD2, MD5, SHA1 jdkCA & usage TLSServer, \
RSA keySize < 1024, DSA keySize < 1024, EC keySize < 224, \
include jdk.disabled.namedCurves
```

Java 控制台添加例外站点无效 错误：请求无限制访问系统

```
# 注释以 jdk.jar 开头的行
# jdk.jar.disabledAlgorithms=MD2, MD5, RSA keySize < 1024, \
# DSA keySize < 1024, include jdk.disabled.namedCurves,  \
# SHA1 denyAfter 2019-01-01
```

