## netstat 简介

`netstat` 命令用于显示网络连接、路由表、接口统计等网络信息。它是一个非常有用的工具，可以帮助用户监控网络状态，排查网络问题

## 使用

查看当前所有 TCP 端口

```
netstat -ntlp
```

查看当前所有 UDP 端口

```
netstat -nulp
```

显示系统所有端口

```
netstat -anp
```

## 排查报文错误

当链路层由于缓冲区溢出等原因导致网卡丢包时，Linux 会在网卡收发数据的统计信息中记录下收发错误的次数。可以通过 ethtool 或者 netstat ，来查看网卡的丢包记录。

```bash
netstat -i
```

RX-OK、RX-ERR、RX-DRP、RX-OVR ，分别表示接收时的总包数、总错误数、进入 Ring Buffer 后因其他原因（如内存不足）导致的丢包数以及 Ring Buffer 溢出导致的丢包数。

执行 netstat -s 命令，可以看到协议的收发汇总，以及错误信息：

```bash
netstat -s
#输出
Ip:
    Forwarding: 1          //开启转发
    31 total packets received    //总收包数
    0 forwarded            //转发包数
    0 incoming packets discarded  //接收丢包数
    25 incoming packets delivered  //接收的数据包数
    15 requests sent out      //发出的数据包数
Icmp:
    0 ICMP messages received    //收到的ICMP包数
    0 input ICMP message failed    //收到ICMP失败数
    ICMP input histogram:
    0 ICMP messages sent      //ICMP发送数
    0 ICMP messages failed      //ICMP失败数
    ICMP output histogram:
Tcp:
    0 active connection openings  //主动连接数
    0 passive connection openings  //被动连接数
    11 failed connection attempts  //失败连接尝试数
    0 connection resets received  //接收的连接重置数
    0 connections established    //建立连接数
    25 segments received      //已接收报文数
    21 segments sent out      //已发送报文数
    4 segments retransmitted    //重传报文数
    0 bad segments received      //错误报文数
    0 resets sent          //发出的连接重置数
Udp:
    0 packets received
    ...
TcpExt:
    11 resets received for embryonic SYN_RECV sockets  //半连接重置数
    0 packet headers predicted
    TCPTimeouts: 7    //超时数
    TCPSynRetrans: 4  //SYN重传数
  ...
```

netstat 汇总了 IP、ICMP、TCP、UDP 等各种协议的收发统计信息。

可以看到，只有 TCP 协议发生了丢包和重传，分别是：

- 11 次连接失败重试（11 failed connection attempts）
- 4 次重传（4 segments retransmitted）
- 11 次半连接重置（11 resets received for embryonic SYN_RECV sockets）
- 4 次 SYN 重传（TCPSynRetrans）
- 7 次超时（TCPTimeouts）