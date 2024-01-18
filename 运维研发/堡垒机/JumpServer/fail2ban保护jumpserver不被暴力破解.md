## fail2ban 简介

官方：

- GitHub 仓库：<https://github.com/fail2ban/fail2ban>

## fail2ban 自定义过滤器

- fail2ban自带了很多常见服务的过滤器，但是jumpserver不在其中，于是乎自己弄一个吧
- fai2ban支持基于正则表达式的过滤，因此可以先用正则表达式匹配一下登录失败的日志

```
fail2ban-regex /opt/koko/data/logs/koko.log 'Failed password for [A-Za-z0-9]+ from <HOST>'
```

- 命令运行之后会显示结果
  - `Failregex: 8234 total`代表有8234条记录被匹配
  - `Date template hits`指该日志中有满足格式的日期

```
Running tests
=============

Use   failregex line : Failed password for [A-Za-z0-9]+ from <HOST>
Use         log file : /opt/koko/data/logs/koko.log
Use         encoding : UTF-8


Results
=======

Failregex: 8234 total
|-  #) [# of hits] regular expression
|   1) [8234] Failed password for [A-Za-z0-9]+ from <HOST>
`-

Ignoreregex: 0 total

Date template hits:
|- [# of hits] date format
|  [27451] {^LN-BEG}ExYear(?P<_sep>[-/.])Month(?P=_sep)Day(?:T|  ?)24hour:Minute:Second(?:[.,]Microseconds)?(?:\s*Zone offset)?
`-

Lines: 27451 lines, 0 ignored, 8234 matched, 19217 missed
[processed in 1.62 sec]

Missed line(s): too many to print.  Use --print-all-missed to print all 19217 lines
```

- 既然正则匹配已经ok了，那么就可以配置自定义过滤器了

```
vi /etc/fail2ban/filter.d/jms-koko.conf
```

- 添加如下内容

```
[Definition]
failregex = Failed password for [A-Za-z0-9]+ from <HOST>
ignoreregex =
```

## 配置fail2ban服务

### 添加fail2ban配置

```
vim /etc/fail2ban/jail.local
[DEFAULT]
# 默认禁止IP地址15天，单位是秒:
bantime = 1296000
# ban的动作使用iptables-multiport
banaction = iptables-multiport
# 忽略IP，注意加上自己的IP，不然被误封就麻烦了
ignoreip = 127.0.0.1/8 192.168.0.0/24
[jms-koko]
# 直接所有协议drop包，覆盖上面的banaction
action  = iptables-allports[protocol=all,blocktype=DROP]
enabled = true
# filter指定刚才配置的自定义过滤器
filter = jms-koko
# koko端口默认是2222
port    = 2222
# koko的日志路径，请修改成自己的路径地址
logpath = /opt/koko/data/logs/koko.log
# 最大重试次数
maxretry = 5
# 禁止12小时，这里会覆盖上面default定义的bantime
bantime = 43200
```

### 检查配置

```
fail2ban-client -t
```

- 输出示例

```
OK: configuration test is successful
```

- 可以通过加`-v`或者`-d`输出详细日志

```
fail2ban-client -t -v
fail2ban-client -t -d
```

### 启动fail2ban

```
systemctl enable --now fail2ban.service
```

### 查看fail2ban的状态

```
fail2ban-client status jms-koko
```

- 根据输出结果可以看到`172.105.86.202`已经被ban了

```
Status for the jail: jms-koko
|- Filter
|  |- Currently failed:	1
|  |- Total failed:	24
|  `- File list:	/opt/koko/data/logs/koko.log
`- Actions
   |- Currently banned:	1
   |- Total banned:	1
   `- Banned IP list:	172.105.86.202
```

### 查看fail2ban日志

- /var/log/fail2ban.log

```
2020-08-30 20:25:33,924 fail2ban.server         [1346]: INFO    --------------------------------------------------
2020-08-30 20:25:33,924 fail2ban.server         [1346]: INFO    Starting Fail2ban v0.11.1
2020-08-30 20:25:33,924 fail2ban.observer       [1346]: INFO    Observer start...
2020-08-30 20:25:33,931 fail2ban.database       [1346]: INFO    Connected to fail2ban persistent database '/var/lib/fail2ban/fail2ban.sqlite3'
2020-08-30 20:25:33,933 fail2ban.database       [1346]: WARNING New database created. Version '4'
2020-08-30 20:25:33,975 fail2ban.filter         [1346]: INFO      maxRetry: 5
2020-08-30 20:25:33,975 fail2ban.filter         [1346]: INFO      encoding: UTF-8
2020-08-30 20:25:33,976 fail2ban.filter         [1346]: INFO      findtime: 600
2020-08-30 20:25:33,976 fail2ban.actions        [1346]: INFO      banTime: 1296000
2020-08-30 20:25:33,976 fail2ban.jail           [1346]: INFO    Creating new jail 'jms-koko'
2020-08-30 20:25:33,977 fail2ban.jail           [1346]: INFO    Jail 'jms-koko' uses poller {}
2020-08-30 20:25:33,978 fail2ban.jail           [1346]: INFO    Initiated 'polling' backend
2020-08-30 20:25:33,979 fail2ban.filter         [1346]: INFO      maxRetry: 5
2020-08-30 20:25:33,980 fail2ban.filter         [1346]: INFO      encoding: UTF-8
2020-08-30 20:25:33,980 fail2ban.filter         [1346]: INFO      findtime: 600
2020-08-30 20:25:33,980 fail2ban.actions        [1346]: INFO      banTime: 43200
2020-08-30 20:25:33,980 fail2ban.filter         [1346]: INFO    Added logfile: '/opt/koko/data/logs/koko.log' (pos = 0, hash = f52047cfc39a7880f2301858f7172d30)
2020-08-30 20:25:33,987 fail2ban.jail           [1346]: INFO    Jail 'jms-koko' started
2020-08-30 22:32:23,861 fail2ban.filter         [1346]: INFO    [jms-koko] Found 172.105.86.202 - 2020-08-30 22:32:23
2020-08-30 22:33:17,912 fail2ban.filter         [1346]: INFO    [jms-koko] Found 172.105.86.202 - 2020-08-30 22:33:17
2020-08-30 22:34:05,961 fail2ban.filter         [1346]: INFO    [jms-koko] Found 172.105.86.202 - 2020-08-30 22:34:05
2020-08-30 22:34:58,023 fail2ban.filter         [1346]: INFO    [jms-koko] Found 172.105.86.202 - 2020-08-30 22:34:57
2020-08-30 22:35:49,282 fail2ban.filter         [1346]: INFO    [jms-koko] Found 172.105.86.202 - 2020-08-30 22:35:49
2020-08-30 22:35:49,374 fail2ban.actions        [1346]: NOTICE  [jms-koko] Ban 172.105.86.202
....
```

### 查看防火墙规则

```
iptables -t filter -L -n -v
```

- 输出如下
  - 被ban的ip会提示端口不可达

```
Chain INPUT (policy ACCEPT 779K packets, 71M bytes)
 pkts bytes target     prot opt in     out     source               destination
 8516  498K f2b-jms-koko  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            multiport dports 2222

<此处忽略很多行>

Chain f2b-jms-koko (1 references)
 pkts bytes target     prot opt in     out     source               destination
   30  1800 REJECT     all  --  *      *       172.105.86.202       0.0.0.0/0            reject-with icmp-port-unreachable
 8461  495K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

## 解封操作

- 说不准有时候会有倒霉蛋输错密码导致IP被ban，可以通过用`fail2ban-client`命令解封IP地址
- JumpServer账号锁定的话要在JumpServer里面解锁账号

```
fail2ban-client set jms-koko unbanip IP地址
```