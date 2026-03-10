## Keepalived 简介

Keepalived 是运行在 lvs 之上，是一个用于做双机热备（HA）的软件，它的主要功能是实现真实机的故障隔离及负载均衡器间的失败切换，提高系统的可用性

官方：

- 文档：<https://keepalived.readthedocs.io/en/latest/introduction.html>

### 运行原理

keepalived 通过选举（看服务器设置的权重）挑选出一台热备服务器做 MASTER 机器，MASTER 机器会被分配到一个指定的虚拟 IP，外部程序可通过该 IP 访问这台服务器，如果这台服务器出现故障（断网，重启，或者本机器上的 keepalived crash 等），keepalived 会从其他的备份机器上重选（还是看服务器设置的权重）一台机器做 MASTER 并分配同样的虚拟 IP，充当前一台 MASTER 的角色

### 选举策略

选举策略是根据 VRRP 协议，完全按照权重大小，权重最大（0～255）的是 MASTER 机器，下面几种情况会触发选举

1. keepalived 启动的时候
2. master 服务器出现故障（断网，重启，或者本机器上的 keepalived crash 等，而本机器上其他应用程序 crash 不算）
3. 有新的备份服务器加入且权重最大
