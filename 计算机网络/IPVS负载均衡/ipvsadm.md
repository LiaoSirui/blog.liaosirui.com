## ipvsadm

ipvsadm 是一个工具，同时它也是一条命令，用于管理 LVS 的策略规则

## 命令语法、子命令和选项

语法：

```bash
ipvsadm -A|E -t|u|f <集群服务地址> [-s <调度算法>] [-p <超时时间>] [-M <掩码>] [-b <标志>]

ipvsadm -D -t|u|f <集群服务地址>

ipvsadm -C

ipvsadm -R

ipvsadm -S [-n]

ipvsadm -a|e -t|u|f <集群服务地址> -r <真实服务器地址> [选项]

ipvsadm -d -t|u|f <集群服务地址> -r <真实服务器地址>

ipvsadm -L|l [options]

ipvsadm -Z [-t|u|f <集群服务地址>]

ipvsadm --set <超时时间>

ipvsadm --start-daemon <主或备> [--mcast-interface <组播接口>] [--syncid <SID>]

ipvsadm --stop-daemon <主或备>

ipvsadm -h

```

子命令：

```bash
--add-service     -A        添加一个集群服务，需要使用选项

--edit-service    -E        编辑一个集群服务，需要使用选项

--delete-service  -D        删除指定集群服务，需要使用选项

--clear           -C        删除所有集群服务，包括真实服务器转发策略规则

--restore         -R        从标准输入中恢复策略规则

--save            -S        保存策略规则到标准输出

--add-server      -a        添加一个真实服务器，需要使用选项

--edit-server     -e        编辑一个真实服务器，需要使用选项

--delete-server   -d        删除一个真实服务器，需要使用选项

--list            -L|-l     查看集群服务列表，包括真实服务器转发策略规则

--zero            -Z        计数器清零。清除连接数、包转发等数量统计信息

--set <超时时间>            设置TCP、TCPFIN（TCP关闭连接状态）、UDP连接超时时间，用于

                            会话保持。一般情况下TCP和UDP超时时间保持默认就好，TCPFIN

                            可以根据情况设定，指定它则用户请求连接关闭，该连接则会变

                            为非活跃（InActive）空闲等待状态，在空闲等待时间内，如果

                            来自同一源IP的请求，则还会转发给后端的同一台真实服务器上

--start-daemon              开启连接同步守护进程。在选项后面指定自己是Master（主）还

                            是backup（备），主负载调度器会同步所有策略及连接状态到备

                            负载调度器，当主故障，备可以接替其工作

--stop-daemon               停止连接同步守护进程

--help            -h        显示帮助信息

```

选项：

```bash
--tcp-service  -t  <集群服务地址>   允许集群服务使用的传输协议为TCP。<IP:Port>

--udp-service  -u <集群服务地址>    允许集群服务使用的传输协议为UDP。<IP:Port>

--fwmark-service  -f <防火墙标识>   使用一个整数值来防火墙标识集群服务，而不是地址、

                                    端口和协议使用它，我们可以通过结合IPtables将多

                                    个以调度器为目标的端口定义成一个防火墙标识，由

                                    ipvsdam通过此项关联标识，则可以实现对一个IP多

                                    端口调度，即实现后端服务器可以开放多个服务

--scheduler    -s scheduler         指定集群服务使用的调度算法：rr|wrr|lc|wlc|lblc

                                    |lblcr|dh|sh|sed|nq，默认为wlc

--persistent   -p <超时时间>        开启持久化服务，开启它则表示在指定时间内，来自同

                                    一IP的请求都会转发到后端同一台真实服务器上

--netmask      -M <网络掩码>        使用网络掩码来屏蔽持久化来源IP的地址范围，默认值

                                    为255.255.255.255，即所有来源IP请求都会享受持久

                                    化服务

--real-server  -r <真实服务器地址>  指定真实服务器的主机IP与端口

--gatewaying   -g                   指定真实服务器转发工作模式，使用DR模式，默认

--ipip         -i                   指定真实服务器转发工作模式，使用TUN模式

--masquerading -m                   指定真实服务器转发工作模式，使用NAT模式

--weight       -w <权重值>          指定真实服务器的权重值

--u-threshold  -x <上阀值>          设置转发请求的最大上连接阀值，范围为0~65535，当

                                    当连接数超过指定上限时，LVS则不会转发请求                                   

--l-threshold  -y <下阀值>          设置转发请求的下连接阀值，范围为0~65535，当连接

                                    数降低至指定值时，LVS则继续提供服务，默认值为0

--mcast-interface interface         设置用于连接同步守护进程的组播接口

--syncid sid                        设置连接同步守护进程的SID号，用于标识，范围0~255

--connection   -c                   显示连接信息，一般与"-l"连用

--timeout                           显示TCP、TCPFIN、UDP超时时间信息，一般与"-l"连用

--daemon                            显示连接同步守护信息，一般与"-l"连用

--stats                             显示统计信息，一般与"-l"连用

--rate                              显示转发速率信息，一般与"-l"连用

--exact                             显示数据包和字节计数器的确切值，扩大字符长度

--thresholds                        显示阀值信息，一般与"-l"连用

--persistent-conn                   显示持久化连接信息，一般与"-l"连用

--numeric      -n                   地址和端口以数字格式显示，一般与"-l"连用

--sched-flags  -b <标识>            设置调度算法的范围标识，用于SH算法，有两个标识：

                                    sh-fallback，如果真实服务器不可用，则将其转发到

                                    其他真实服务器上。

                                    sh-port,将源地址的端口号也添加到散列键=值中
```

## 集群服务管理

对集群服务条目的增删查改

查看

```bash
> ipvsadm -ln

IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
```

添加一个集群服务

```bash
pvsadm -A -t 192.168.1.100:80 -s rr
```

修改一个集群服务

```bash
ipvsadm -E -t 192.168.1.100:80 -s wlc
```

删除一个集群服务

```bash
ipvsadm -D -t 192.168.1.100:80
```

删除所有集群服务

```bash
ipvsadm -C
```

## 真实服务器管理

对要转发的真实服务器条目的增删查改。绑定集群服务、指定 LVS 转发的工作模式

往集群服务中添加一个真实服务器

```bash
ipvsadm -a -t 192.168.1.100:80 -r 172.16.16.2:80 -m -w 1

ipvsadm -a -t 192.168.1.100:80 -r 172.16.16.3:80 -m -w 1
```

修改集群服务中的一个真实服务器

修改集群服务中的一个真实服务器的权重值

```bash
ipvsadm -e -t 192.168.1.100:80 -r 172.16.16.2:80 -m -w 2
```

删除集群服务中的一个真实服务器

```bash
ipvsadm -d -t 192.168.1.100:80 -r 172.16.16.2:80
```

清空转发请求计数器

```bash
ipvsadm -Z
```

