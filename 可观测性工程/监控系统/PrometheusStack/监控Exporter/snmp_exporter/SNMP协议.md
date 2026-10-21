## SNMP 协议

SNMP 协议是指简单网络管理协议（Simple Network Management Protocol），在原文语境中，指用于网络设备管理的标准化协议，通过 RFC 文档定义规范，支持网络管理系统（NMS）与被管理设备（如路由器、交换机）间的信息交互，实现设备状态监控、配置管理及故障告警等功能，具体可参考华为相关介绍及 RFC 文档（如 RFC 3410 - 3418 定义 SNMPv3 框架）。

参考：

- <https://support.huawei.com/enterprise/zh/doc/EDOC1100087025/5d668861>
- <https://zhuanlan.zhihu.com/p/675276335>

## SNMP 的组织结构

SNMP 由三部分组成： SNMP内核 、 管理信息结构SMI 和 管理信息库MIB 。

SNMP 内核负责协议结构分析，根据分析结果完成网管动作； SMI 是一种通用规则，用来命名对象和定义对象类型，以及把对象和对象的值进行编码的规则； MIB 在被管理的实体中创建命名对象，也就是一个实例。 SMI 规定游戏规则，在规则基础上由 MIB 实现实例化，而 SNMP 则是实例化的终极执行 BOSS 。

## snmpwalk

```
snmpwalk -v 2c -c 123456 100.200.1.254
snmpwalk -v 2c -c 123456 172.18.48.5 1.3.6.1.2.1.47.1.1.1.1.7
snmpwalk -v3 -u sysadmin -a MD5 -A rootuser -x DES -X rootuser -l authPriv 100.200.1.24

```

-v 表示的是 snmp 的版本，-c 表示团体名，之后就是 ip，最后是 oid

## snmptranslate

``` bash
```

## MIB 模块

- <https://mibbrowser.online/mibdb_search.php>

## 参考资料

- <https://luanxinchen.github.io/2021/01/18/snmp-custom-metrics/>

- <https://telemetry-compass.com/2023/10/13/prometheus-snmp-exporter-part-1/>