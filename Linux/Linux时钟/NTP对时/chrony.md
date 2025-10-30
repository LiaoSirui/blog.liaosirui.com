## chrony 作为时间服务器

`vi /etc/chrony.conf`

注释掉默认的 ntp.org 时钟源，添加一个 NTP 服务器时钟源，例如添加 `ntp.aliyun.com`

然后设置 NTP 客户端的允许 IP 地址范围

```bash
allow 0/0
allow ::0/0
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

```bash
local stratum 10 orphan distance 0.1
```

## chrony 同步时间

### chronyc 守护进程

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

### chronyc

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

### 非守护进程同步时间

就像`ntpdate`命令一样，可以使用`chronyd`命令手动将Linux服务器的时间与远程NTP服务器进行同步。

```bash
chronyd -q 'server 172.16.11.141 iburst'
```

也可以从配置文件读取 NTP Server

```bash
chronyd -4 -t 10 -q -f /etc/chrony.conf

# -4 Use IPv4 addresses only
# -t timeout
# -q Set clock and exit
# -f <FILE> Specify configuration file (/etc/chrony.conf)
```

### 参考时钟

`chronyd` 依赖使用其他程序（例如 `gpsd`）通过特定驱动程序来访问计时数据。在 `/etc/chrony.conf` 中使用 `refclock` 指令可指定要用作时间源的硬件参考时钟。它有两个必填参数：驱动程序名称和驱动程序特定的参数。这两个参数后面跟着零个或多个 `refclock` 选项。`chronyd` 包含以下驱动程序：    

- PPS

内核 pulse per second API 的驱动程序

```bash
refclock PPS /dev/pps0 lock NMEA refid GPS
```

- SHM

NTP 共享内存驱动程序

```bash
refclock SHM 0 poll 3 refid GPS1
refclock SHM 1:perm=0644 refid GPS2
```

- SOCK

Unix 域套接字驱动程序

```bash
refclock SOCK /var/run/chrony.ttyS0.sock
```

- PHC

PTP 硬件时钟驱动程序

```bash
refclock PHC /dev/ptp0 poll 0 dpoll -2 offset -37
refclock PHC /dev/ptp1:nocrossts poll 3 pps
```

## chronyc 命令

### `chronyc sources`

查看时钟源授时时间偏差值

```bash
# chronyc sources -v

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current best, '+' = combined, '-' = not combined,
| /             'x' = may be in error, '~' = too variable, '?' = unusable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
#* PHC0                          0   0   377     1     +2ns[  +10ns] +/-   20ns
^- a.chl.la                      2  10   377   28m  -4308us[-4366us] +/-  101ms
^- 111.230.189.174               2  10   377   102  -2486us[-2487us] +/-   58ms
^- time.cloudflare.com           3  10   375   572    +14ms[  +14ms] +/-   96ms
^- 119.28.206.193                2  10   377   662    +37us[  +33us] +/-   37ms
```

| 列名              | 含义                                            | 具体说明                                                     |
| ----------------- | ----------------------------------------------- | ------------------------------------------------------------ |
| `M`               | 表示授时时钟源                                  | `^` 表示服务器，`=` 表示二级时钟源 ，`#` 表示本地连接的参考时钟 |
| `S`               | 指示源的状态                                    | `*` 当前同步的源，`+` 表示其他可接受的源，`?` 表示连接丢失的源，`x` 表示一个认为是 falseticker 的时钟（即它的时间与大多数其他来源不一致），`~` 表示其时间似乎具有太多可变性的来源 |
| `Name/IP address` | 表示源的名称或 IP 地址，或者参考时钟的 refid 值 | 无                                                           |
| `Stratum`         | 表示源的层级                                    | 层级 1 表示本地连接的参考时钟，第 2 层表示通过第 1 层级计算机的时钟实现同步，依此类推。 |
| `Poll`            | 表示源轮询的频率                                | 以秒为单位，值是基数 2 的对数，例如值 6 表示每 64 秒进行一次测量，chronyd 会根据当时的情况自动改变轮询频率 |
| `Reach`           | 表示源的可达性的锁存值（八进制数值）            | 该锁存值有 8 位，并在当接收或丢失一次时进行一次更新，值 377 表示最后八次传输都收到了有效的回复 |
| `LastRx`          | 表示从源收到最近的一次的时间                    | 通常是几秒钟，字母 m，h，d 或 y 分别表示分钟，小时，天或年，值 10 年表示从未从该来源收到时间同步信息 |
| `Last sample`     | 表示本地时钟与上次测量时源的偏移量              | 方括号中的数字表示实际测量的偏移值，这可以以 ns（表示纳秒），us（表示微秒），ms（表示毫秒）或 s（表示秒）为后缀；方括号左侧的数字表示原始测量值，这个值是经过调整以允许应用于本地时钟的任何偏差；方括号右侧表示偏差值，`+/-` 指示器后面的数字表示测量中的误差范围，+ 偏移表示本地时钟快过源 |

### `chronyc sourcestats`

主要偏移率及每个时钟源的偏移评估值

```bash
# chronyc sourcestats
Name/IP Address            NP  NR  Span  Frequency  Freq Skew  Offset  Std Dev
==============================================================================
PHC0                        6   3     5     +0.001      0.012     +1ns     6ns
a.chl.la                   64  27   18h     +0.151      0.099  -1526us  4414us
111.230.189.174            16  10  258m     -0.051      0.233  -1327us  1145us
time.cloudflare.com        24  14  414m     +0.182      0.459  +6852us  4326us
119.28.206.193             18   9  293m     -0.103      0.185  -1710us   973us
```

| 列名              | 含义                                                         |
| ----------------- | ------------------------------------------------------------ |
| `Name/IP address` | 表示源的名称或 IP 地址，或者参考时钟的 refid 值              |
| `NP`              | 这是当前为服务器保留的采样点数，通过这些点执行线性回归方法来估算出偏移值 |
| `NR`              | 这是在最后一次回归之后具有相同符号的偏差值的运行次数。如果此数字相对于样本数量开始变得太小，则表明直线不再适合数据。如果运行次数太少，则 chronyd 丢弃旧样本并重新运行回归，直到运行次数变得可接受为止 |
| `Span`            | 这是最旧和最新样本之间的间隔。如果未显示任何单位，则该值以秒为单位 |
| `Frequency`       | 这是服务器的估算偏差值的频率，单位为百万分之一               |
| `Freq Skew`       | 这是 Freq 的估计误差范围（ppm）                              |
| `Offset`          | 这是源的估计偏移量                                           |
| `Std Dev`         | 这是估计的样本标准偏差                                       |

## 问题记录

Using chronyc tracking, get:

```bash
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

```bash
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^? 192.168.0.5                   0   7     0     -     +0ns[   +0ns] +/-    0ns
```

Running chronyc activity, get:

```bash
200 OK
1 sources online
0 sources offline
0 sources doing burst (return to online)
0 sources doing burst (return to offline)
8 sources with unknown address
```

最终调试为 server 端未指定：

```bash
local stratum 10 orphan distance 0.1
```

client 端需要给 chronyd 增加 `-4` 参数，因为关闭了 ipv6

对端是 win ，客户端需要修改

A common issue with Windows NTP servers is that they report a very large root dispersion (e.g. three seconds or more), which causes `chronyd` to ignore the server for being too inaccurate. The `sources` command might show a valid measurement, but the server is not selected for synchronisation. You can check the root dispersion of the server with the `chronyc`'s `ntpdata` command.

The `maxdistance` value needs to be increased in `chrony.conf` to enable synchronisation to such a server. For example:

```bash
# 如果不改，可能会出现与 windows 同步失败
maxdistance 16.0
```

## 参考文档

- <https://chrony-project.org/faq.html>
