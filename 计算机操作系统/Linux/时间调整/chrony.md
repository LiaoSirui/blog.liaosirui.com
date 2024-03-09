## NTP

网络时间协议 (Network Time Protocol, NTP) 是通过 RFC-1305 定义的时间同步协议，该协议基于 UDP 协议，使用端口号为 123；该协议用于在时间服务器和客户端之间同步时间，从而使网络内所有设备的时钟保持一致

NTP 时间同步是按照层级分发时间的

![053007eb75245ba9be6c459b9d68c9c2.png](.assets/chrony/053007eb75245ba9be6c459b9d68c9c2.png)

chrony 默认使用 323 UDP 端口

## chrony server

`vi /etc/chrony.conf`

注释掉默认的 ntp.org 时钟源，添加一个 NTP 服务器时钟源，例如添加 ntp.aliyun.com

然后设置 NTP 客户端的允许IP地址范围

```bash
allow 10.20.0.0/16
```

查看服务端监听端口

```bash
ss -tlunp | grep chrony
# 查看监听端口
# 123 和 323 端口
```

如果没有上游 ntp ，需要进行如下设置

local 指令启用本地参考模式，该模式允许 chronyd 作为 NTP 服务器运行，看起来与实时同步（从轮询客户端的角度来看），即使它从未同步或上次时钟更新发生了很长时间前。

该指令通常用在隔离网络中，其中计算机需要彼此同步，但不一定是实时的。 通过手动输入，服务器可以保持与实时的模糊一致。

```
local stratum 10 orphan distance 0.1
```

## chrony

安装 chrony 服务

```bash
dnf install -y chrony

# 启动 chrony 服务 /设置开机自启
systemctl enable --now chronyd

# 查看 chrony 服务状态
systemctl status chronyd
```

可参考修改 ntp 服务器地址，但不是必要的

```bash
# 修改 /etc/chrony.conf 配置文件

# 1、编辑 /etc/chrony.conf 配置文件
vim /etc/chrony.conf

# 2、配置阿里云的 ntp 服务
# * 注释掉默认的 ntp 服务器，因为该服务器同步时间略慢
# pool 2.pool.ntp.org iburst
# server 2.pool.ntp.org iburst

# 格式为：server 服务器ip地址 iburst 
# 添加阿里云的 ntp 服务器，可以多写几个 ntp 服务器，防止第一个服务器宕机，备用的其他 ntp 服务器可以继续进行时间同步
# ip 地址为服务器 ip 地址，iburst 代表的是快速同步时间 
pool ntp1.aliyun.com iburst
pool ntp2.aliyun.com iburst
pool ntp3.aliyun.com iburst
```

在服务器端查看有哪些客户端通过此NTP服务器进行时钟同步

```bash
chronyc clients

Hostname                      NTP   Drop Int IntL Last     Cmd   Drop Int  Last

172.16.11.188                 275      0  10   -  1076       0      0   -     -
```

验证系统时间是否已使用 chrony 同步

```bash
chronyc tracking
```

客户端查看同步状态

```bash
chronyc sources -v  # 查看同步状态
```

手动同步系统时钟

```bash
chronyc -a makestep
```

就像`ntpdate`命令一样，我们可以使用`chronyd`命令手动将Linux服务器的时间与远程NTP服务器进行同步。

```bash
chronyd -q 'server 172.16.11.141 iburst'
```

## 问题记录

Using chronyc tracking, get:

```
Reference ID    : 00000000 ()
Stratum         : 0
Ref time (UTC)  : Thu Jan 01 00:00:00 1970
System time     : 0.000000000 seconds fast of NTP time
Last offset     : +0.000000000 seconds
RMS offset      : 0.000000000 seconds
Frequency       : 0.000 ppm slow
Residual freq   : +0.000 ppm
Skew            : 0.000 ppm
Root delay      : 1.000000000 seconds
Root dispersion : 1.000000000 seconds
Update interval : 0.0 seconds
Leap status     : Not synchronised
```

Running chronyc sources, get:

```
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^? 192.168.0.5                   0   7     0     -     +0ns[   +0ns] +/-    0ns
```


Running chronyc activity, get:

```
200 OK
1 sources online
0 sources offline
0 sources doing burst (return to online)
0 sources doing burst (return to offline)
8 sources with unknown address
```

最终调试为 server 端未指定：

```
local stratum 10 orphan distance 0.1
```

client 端需要给 chronyd 增加 `-4` 参数，因为关闭了 ipv6
