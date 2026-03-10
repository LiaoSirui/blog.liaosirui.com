Keepalived 是运行在 lvs 之上，它的主要功能是实现 RealServer (真实服务器) 的故障隔离及 Director (负载均衡器) 间的 FailOver (失败切换).

1. keepalived 是 lvs 的扩展项目，因此它们之间具备良好的兼容性
2. 对 RealServer 的健康检查，实现对失效机器 / 服务的故障隔离
3. 负载均衡器之间的失败切换 failover

## 全局定义

全局配置又包括两个子配置

1. 全局定义(global definition)
2. 静态路由配置(static ipaddress/routes)

```config
# 全局定义(global definition) 
global_defs {                      
   notification_email {      
   acassen@firewall.loc     
   failover@firewall.loc
   sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc   
   smtp_server 192.168.200.1                         
   smtp_connect_timeout 30                                  
   router_id LVS_DEVEL     
}
notification_email: 表示keepalived在发生诸如切换操作时需要发送email通知以及email发送给哪些邮件地址邮件地址可以多个每行一个
notification_email_from admin@example.com: 表示发送通知邮件时邮件源地址是谁
smtp_server 127.0.0.1: 表示发送email时使用的smtp服务器地址这里可以用本地的sendmail来实现
smtp_connect_timeout 30: 连接smtp连接超时时间
router_id node1: 机器标识，通常配置主机名

# 静态地址和路由配置范例
static_ipaddress {
    192.168.1.1/24 brd + dev eth0 scope global
    192.168.1.2/24 brd + dev eth1 scope global
}
static_routes {
    src $SRC_IP to $DST_IP dev $SRC_DEVICE
    src $SRC_IP to $DST_IP via $GW dev $SRC_DEVICE
}
这里实际上和系统里面命令配置IP地址和路由一样例如
192.168.1.1/24 brd + dev eth0 scope global 相当于: ip addr add 192.168.1.1/24 brd + dev eth0 scope global
就是给eth0配置IP地址路由同理,一般这个区域不需要配置
这里实际上就是给服务器配置真实的IP地址和路由的在复杂的环境下可能需要配置一般不会用这个来配置我们可以直接用vi /etc/sysconfig/network-script/ifcfg-eth1来配置切记这里可不是VIP不要搞混淆了切记切记

```

## VRRPD配置

包括三个类:

1. VRRP同步组(synchroization group)
2. VRRP实例(VRRP Instance)
3. VRRP脚本

```config
# VRRP同步组(synchroization group)配置范例
vrrp_sync_group VG_1 {   //注意vrrp_sync_group  后面可自定义名称如lvs_httpd ,httpd
group {
http
mysql
}
notify_master /path/to/to_master.sh
notify_backup /path_to/to_backup.sh
notify_fault "/path/fault.sh VG_1"
notify /path/to/notify.sh
smtp_alert 
}
其中http和mysql是实例名和下面的实例名一致
notify_master /path/to/to_master.sh //表示当切换到master状态时要执行的脚本
notify_backup /path_to/to_backup.sh //表示当切换到backup状态时要执行的脚本
notify_fault "/path/fault.sh VG_1"  // keepalived出现故障时执行的脚本
notify /path/to/notify.sh  
smtp_alert           //表示切换时给global defs中定义的邮件地址发送邮件通知

# VRRP实例(instance)配置范例
vrrp_instance http {  //注意vrrp_instance 后面可自定义名称如lvs_httpd ,httpd
state MASTER
interface eth0
dont_track_primary
track_interface {
eth0
eth1
}
mcast_src_ip <IPADDR>
garp_master_delay 10
virtual_router_id 51
priority 100
advert_int 1
authentication {
auth_type PASS
autp_pass 1234
}
virtual_ipaddress {
#<IPADDR>/<MASK> brd <IPADDR> dev <STRING> scope <SCOPT> label <LABEL>
192.168.200.17/24 dev eth1
192.168.200.18/24 dev eth2 label eth2:1
}
virtual_routes {
# src <IPADDR> [to] <IPADDR>/<MASK> via|gw <IPADDR> dev <STRING> scope <SCOPE> tab
src 192.168.100.1 to 192.168.109.0/24 via 192.168.200.254 dev eth1
192.168.110.0/24 via 192.168.200.254 dev eth1
192.168.111.0/24 dev eth2
192.168.112.0/24 via 192.168.100.254
}
nopreempt
preemtp_delay 300
debug
}
```

state: state 指定 instance (Initial) 的初始状态就是说在配置好后这台 服务器的初始状态就是这里指定的但这里指定的不算还是得要通过竞选通过优先级来确定里如果这里设置为 master 但如若他的优先级不及另外一台 那么这台在发送通告时会发送自己的优先级另外一台发现优先级不如自己的高那么他会就回抢占为 master

interface: 实例绑定的网卡因为在配置虚拟 VIP 的时候必须是在已有的网卡上添加的

dont track primary: 忽略 VRRP 的 interface 错误

track interface: 跟踪接口设置额外的监控里面任意一块网卡出现问题都会进入故障 (FAULT) 状态例如用 nginx 做均衡器的时候内网必须正常工作如果内网出问题了这个均衡器也就无法运作了所以必须对内外网同时做健康检查

mcast src ip: 发送多播数据包时的源 IP 地址这里注意了这里实际上就是在那个地址上发送 VRRP 通告这个非常重要一定要选择稳定的网卡端口来发送这里相当于 heartbeat 的心跳端口如果没有设置那么就用默认的绑定的网卡的 IP 也就是 interface 指定的 IP 地址

garp master delay: 在切换到 master 状态后延迟进行免费的 ARP (gratuitous ARP) 请求，默认 5s

virtual router id: 这里设置 VRID 这里非常重要相同的 VRID 为一个组他将决定多播的 MAC 地址

priority 100: 设置本节点的优先级优先级高的为 master

advert int: 设置 MASTER 与 BACKUP 负载均衡之间同步即主备间通告时间检查的时间间隔，单位为秒，默认 1s

virtual ipaddress: 这里设置的就是 VIP 也就是虚拟 IP 地址他随着 state 的变化而增加删除当 state 为 master 的时候就添加当 state 为 backup 的时候删除这里主要是有优先级来决定的和 state 设置的值没有多大关系这里可以设置多个 IP 地址

virtual routes: 原理和 virtual ipaddress 一样只不过这里是增加和删除路由

lvs sync daemon interface: lvs syncd 绑定的网卡，类似 HA 中的心跳检测绑定的网卡

authentication: 这里设置认证

auth type: 认证方式可以是 PASS 或 AH 两种认证方式

auth pass: 认证密码

nopreempt: 设置不抢占 master，这里只能设置在 state 为 backup 的节点上而且这个节点的优先级必须别另外的高，比如 master 因为异常将调度圈交给了备份 serve，master serve 检修后没问题，如果不设置 nopreempt 就会将调度权重新夺回来，这样就容易造成业务中断问题

preempt delay: 抢占延迟多少秒，即延迟多少秒后竞选 master

debug：debug 级别

notify master：和 sync group 这里设置的含义一样可以单独设置例如不同的实例通知不同的管理人员 http 实例发给网站管理员 mysql 的就发邮件给 DBA

## 参考文档

- <https://wsgzao.github.io/post/keepalived/>
