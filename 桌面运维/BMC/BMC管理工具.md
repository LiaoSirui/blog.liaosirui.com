IPMItool 用于访问 IPMI 的功能 - 智能平台管理接口，该系统接口管理和监视带外计算机系统。它是一个命令提示符，用于控制和配置 IPMI 支持的设备。

IPMItool 是一种可用在 linux 系统下的命令行方式的 ipmi 平台管理工具，它支持 ipmi 1.5 规范（最新的规范为 ipmi 2.0）.IPMI 是一个开放的标准，监控，记录，回收，库存和硬件实现独立于主 CPU，BIOS，以及操作系统的控制权。 服务处理器（或底板管理控制器，BMC）的背后是平台管理的大脑，其主要目的是处理自主传感器监控和事件记录功能。

## 参考文档

- <https://www.cnblogs.com/HByang/p/16127044.html>

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

