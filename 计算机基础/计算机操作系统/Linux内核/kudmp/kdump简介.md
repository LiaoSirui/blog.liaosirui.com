## Kdump 简介

Kdump 是一个用于收集系统崩溃、死锁或死机时内核参数的一个服务。举例来说，如果有一天系统崩溃了，在这时 Kdump 服务就会开始工作，将系统的运行状态和内核数据收集到一个“dump core”的文件中，便于后续让运维人员分析找出问题所在

Kdump 配置文件存放在 `/etc/kdump.conf` 配置文件中配置了一些相关信息，包括系统崩溃时，dump 的路径，默认情况下是放在 `/var/crash` 目录下面

## 参考文档

- <https://blog.csdn.net/heshuangzong/article/details/126906923>