## Wireshark

- CaptureFilters <https://wiki.wireshark.org/CaptureFilters>

- DisplayFilters <https://wiki.wireshark.org/DisplayFilters>

## 命令行 tshark

```bash
//打印http协议流相关信息
tshark -s 512 -i eth0 -n -f 'tcp dst port 80' -R 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l | tr -d '\t'
　　注释：
　　　　-s: 只抓取前512字节；
　　　　-i: 捕获eth0网卡；
　　　　-n: 禁止网络对象名称解析;
　　　　-f: 只捕获协议为tcp,目的端口为80;
　　　　-R: 过滤出http.host和http.request.uri;
　　　　-T,-e: 指的是打印这两个字段;
　　　　-I: 输出到命令行界面; 
//实时打印当前mysql查询语句
tshark -s 512 -i eth0 -n -f 'tcp dst port 3306' -R 'mysql.query' -T fields -e mysql.query
　　　注释:
　　　　-R: 过滤出mysql的查询语句;
//导出smpp协议header和value的例子
tshark -r test.cap -R '(smpp.command_id==0x80000004) and (smpp.command_status==0x0)' -e smpp.message_id -e frame.time -T fields -E header=y >test.txt
　　　注释:
　　　　-r: 读取本地文件，可以先抓包存下来之后再进行分析;
　　　　-R: smpp...可以在wireshark的过滤表达式里面找到，后面会详细介绍;
　　　　-E: 当-T字段指定时，设置输出选项，header=y意思是头部要打印;
　　　　-e: 当-T字段指定时，设置输出哪些字段;
　　　　 >: 重定向;
//统计http状态
tshark -n -q -z http,stat, -z http,tree
　　　注释:
　　　　-q: 只在结束捕获时输出数据，针对于统计类的命令非常有用;
　　　　-z: 各类统计选项，具体的参考文档，后面会介绍，可以使用tshark -z help命令来查看所有支持的字段;
　　　　　　 http,stat: 计算HTTP统计信息，显示的值是HTTP状态代码和HTTP请求方法。
　　　　　　 http,tree: 计算HTTP包分布。 显示的值是HTTP请求模式和HTTP状态代码。
//抓取500个包提取访问的网址打印出来
tshark -s 0 -i eth0 -n -f 'tcp dst port 80' -R 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l -c 500
　　　注释: 
　　　　-f: 抓包前过滤；
　　　　-R: 抓包后过滤；
　　　　-l: 在打印结果之前清空缓存;
　　　　-c: 在抓500个包之后结束;
//显示ssl data数据
tshark -n -t a -R ssl -T fields -e "ip.src" -e "ssl.app_data"

//读取指定报文,按照ssl过滤显示内容
tshark -r temp.cap -R "ssl" -V -T text
　　注释: 
　　　　-T text: 格式化输出，默认就是text;
　　　　-V: 增加包的输出;//-q 过滤tcp流13，获取data内容
tshark -r temp.cap -z "follow,tcp,ascii,13"

//按照指定格式显示-e
tshark -r temp.cap -R ssl -Tfields -e "ip.src" -e tcp.srcport -e ip.dst -e tcp.dstport

//输出数据
tshark -r vmx.cap -q -n -t ad -z follow,tcp,ascii,10.1.8.130:56087,10.195.4.41:446 | more
　　注释:
　　　　-t ad: 输出格式化时间戳;
//过滤包的时间和rtp.seq
tshark  -i eth0 -f "udp port 5004"  -T fields -e frame.time_epoch -e rtp.seq -o rtp.heuristic_rtp:true 1>test.txt
　　注释:
　　　　-o: 覆盖属性文件设置的一些值;

//提取各协议数据部分
tshark -r H:/httpsession.pcap -q -n -t ad -z follow,tcp,ascii,71.6.167.142:27017,101.201.42.120:59381 | more
```

## wireshark-cli

Wireshark，是最受欢迎的 GUI 嗅探工具，实际上它带了一套非常有用的命令行工具集。其中包括 editcap 与 mergecap。

- editcap 是一个万能的 pcap 编辑器，它可以过滤并且能以多种方式来分割 pcap 文件。

- mergecap 可以将多个 pcap 文件合并为一个。

除此之外，还有其它的相关工具，如 [reordercap](https://www.wireshark.org/docs/man-pages/reordercap.html) 用于将数据包重新排序，[text2pcap](https://www.wireshark.org/docs/man-pages/text2pcap.html) 用于将 pcap 文件转换为文本格式， [pcap-diff](https://github.com/isginf/pcap-diff) 用于比较 pcap 文件的异同，等等

Debian 系列：

```bash
apt install wireshark-common
```

RHEL 系列：

```bash
dnf install wireshark-cli
```

## editcap

editcap 是一个万能的 pcap 编辑器，它可以过滤并且能以多种方式来分割 pcap 文件

- <https://www.wireshark.org/docs/man-pages/editcap.html>

editcap 是一个从文件读取部分或所有捕获数据包的程序，可选地以各种方式转换它们，并将结果数据包写入输出文件。缺省情况下，它从输入文件中读取所有数据包，并以 pcapng 文件格式写进输出文件。

editcap 的几个常见功能：

- 可以按时间、长度等截取数据包。
- 可以用来删除重复的数据包，可用来控制用于重复比较的包窗口或相对时间窗口。
- 可以用来编辑数据帧的描述。
- 可以检测、读取和写入 Wireshark 支持的相同捕获文件。
- 可以用几种输出格式编写文件。

### pcap 文件过滤

通过 editcap， 能以很多不同的规则来过滤 pcap 文件中的内容，并且将过滤结果保存到新文件中。

以“起止时间”来过滤 pcap 文件。 -A 和 -B 选项可以过滤出在这个时间段到达的数据包（如，从 2:30 ～ 2:35）。时间的格式为 "YYYY-MM-DD HH:MM:SS"。

```bash
editcap -A '2014-12-10 10:11:01' -B '2014-12-10 10:21:01' input.pcap output.pcap
```

也可以从某个文件中提取指定的 N 个包。下面的命令行从 input.pcap 文件中提取100个包（从 401 到 500）并将它们保存到 output.pcap 中：

```bash
editcap input.pcap output.pcap 401-500
```

使用 "`-D <dup-window>`" （dup-window 可以看成是对比的窗口大小，仅与此范围内的包进行对比）选项可以提取出重复包。每个包都依次与它之前的 `<dup-window> - 1` 个包对比长度与 MD5 值，如果有匹配的则丢弃。

```bash
editcap -D 10 input.pcap output.pcap
```

也可以将 `<dup-window>` 定义成时间间隔。使用"`-w <dup-time-window>`"选项，对比 `<dup-time-window>` 时间内到达的包。

```bash
editcap -w 0.5 input.pcap output.pcap 
```

### 分割 pcap 文件

当需要将一个大的 pcap 文件分割成多个小文件时，editcap 也能起很大的作用。

将一个 pcap 文件分割成数据包数目相同的多个文件

```bash
editcap -c <packets-per-file> <input-pcap-file> <output-prefix>
```

输出的每个文件有相同的包数量，以 `<output-prefix >-NNNN` 的形式命名。

以时间间隔分割 pcap 文件

```bash
editcap -i <seconds-per-file> <input-pcap-file> <output-prefix>
```

## mergecap

### 合并 pcap 文件

如果想要将多个文件合并成一个，用 mergecap 就很方便。

当合并多个文件时，mergecap 默认将内部的数据包以时间先后来排序。

```bash
mergecap -w output.pcap input.pcap input2.pcap [input3.pcap ...]
```

如果要忽略时间戳，仅仅想以命令行中的顺序来合并文件，那么使用 `-a` 选项即可。

例如，下列命令会将 `input.pcap` 文件的内容写入到 `output.pcap`, 并且将 `input2.pcap` 的内容追加在后面。

```bash
mergecap -a -w output.pcap input.pcap input2.pcap
```

## capinfos

不带任何选项参数，以默认方式显示 pcap 文件的所有基本信息：

```bash
$ capinfos 2023-09-26-14-31-42-30s.pcap
File name:           2023-09-26-14-31-42-30s.pcap
File type:           Wireshark/tcpdump/... - pcap
File encapsulation:  Ethernet
File timestamp precision:  microseconds (6)
Packet size limit:   file hdr: 65535 bytes
Number of packets:   300 k
File size:           261 MB
Data size:           256 MB
Capture duration:    30.096327 seconds
First packet time:   2023-09-26 14:33:25.555011
Last packet time:    2023-09-26 14:33:55.651338
Data byte rate:      8,512 kBps
Data bit rate:       68 Mbps
Average packet size: 854.00 bytes
Average packet rate: 9,967 packets/s
SHA256:              4cd82ce1b8fd3d498794d14e2ada82a3acbafca64f1e699574e58a6deec600cc
RIPEMD160:           347128fa0c6a4aeabcdeb71b1e6cdaf94d100999
SHA1:                a800fa328b3e65af40d2b783b37e0a2b5d80591f
Strict time order:   True
Number of interfaces in file: 1
Interface #0 info:
                     Encapsulation = Ethernet (1 - ether)
                     Capture length = 65535
                     Time precision = microseconds (6)
                     Time ticks per second = 1000000
                     Number of stat entries = 0
                     Number of packets = 300000
```

显示 pcap 文件的总大小：

```bash
$ capinfos -s 2023-09-26-14-31-42-30s.pcap
File name:           2023-09-26-14-31-42-30s.pcap
File size:           261 MB
```

显示 pcap 文件的时间长度：

```bash
$ capinfos -u 2023-09-26-14-31-42-30s.pcap
File name:           2023-09-26-14-31-42-30s.pcap
Capture duration:    30.096327 seconds
```

显示 pcap 文件的数据包总量：

```bash
$ capinfos -c 2023-09-26-14-31-42-30s.pcap
File name:           2023-09-26-14-31-42-30s.pcap
Number of packets:   300 k
```

## 参考资料

- <https://www.cnblogs.com/liun1994/p/6142505.html>

- <https://cloud.tencent.com/developer/article/2462400>

- <https://www.cnblogs.com/hyacinthLJP/p/18078481>

- <https://juejin.cn/post/7222141882515030071>

- <https://getiot.tech/linux-command/editcap/>

- <https://getiot.tech/linux-command/capinfos/#%E4%BB%8B%E7%BB%8D>
