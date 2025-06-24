## PTP 配置

由 `linuxptp` 软件包提供 PTP 实施，其中包含用于时钟同步的 `ptp4l` 和 `phc2sys` 程序。

- ptp4l（PTP for Linux）命令用于 PTP 同步。ptp4l 是根据适用于 Linux 的 IEEE 标准 1588 的精确时间协议（PTP）的实现，它实现了边界时钟（Boundary Clock）和普通时钟（Ordinary Clock），支持硬件时钟同步和软件时间同步（系统时钟同步）。
- phc2sys（PTP hardware clock to system）命令用于同步两个或多个时钟。最常见的用法是，将系统时钟同步到网卡上的 PTP 硬件时钟（PHC）。PHC 本身可以使用 ptp4l 同步，系统时钟被视为从属时钟，而网卡上的时钟则为主时钟。

通常是：

- ptp4l 进行时钟同步，实时网卡时钟与远端的时钟同步（比如 TSN 交换机，Time-Sensitive Networking）

- phc2sys 将网卡上的时钟同步到操作系统（以网卡上的时钟为 master）

参考文档：（注意这些资料都有点旧）

- <https://docs.redhat.com/zh-cn/documentation/red_hat_enterprise_linux/7/html/system_administrators_guide/sec-synchronizing_the_clocks>
- <https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-configuring_ptp_using_ptp4l#sec-Understanding_PTP>
- <https://docs.oracle.com/en/operating-systems/oracle-linux/6/admin/section_kpy_1gh_pp.html>
- <https://getiot.tech/linux-command/ptp4l>
- <https://getiot.tech/linux-command/phc2sys/>
- <https://getiot.tech/linux-command/phc_ctl>
- <https://getiot.tech/linux-command/pmc>

## 配置前准备

（1）确认硬件支持

需使用支持 PTP 协议的网络接口卡（NIC），且交换机（如 Cisco 3548）需启用 PTP 功能并配置为时钟源或从时钟。

示例配置（Cisco 3548）：

```bash
switch(config)# ptp clock
switch(config-ptp-clock)# priority1 128  # 设置时钟优先级（0-255）
switch(config-ptp-clock)# announce-interval 1  # 广播间隔（秒）
```

（2）网络配置

确保 Linux 系统与交换机处于同一子网，且 PTP 流量通过专用端口传输（如配置 VLAN 或 Trunk）。

（3）安装 PTP 工具

```bash
# CentOS/RHEL
dnf install -y linuxptp util-linux
```

（4）检查网卡是否支持

PTP 要求使用的内核网络驱动程序支持软件时戳或硬件时戳。此外，NIC 还必须支持物理硬件中的时戳。可以使用 `ethtool` 校验驱动程序和 NIC 时戳功能：

```bash
ethtool -T eth0

Timestamping parameters for eth0:
Capabilities:
        hardware-transmit     (SOF_TIMESTAMPING_TX_HARDWARE)
        software-transmit     (SOF_TIMESTAMPING_TX_SOFTWARE)
        hardware-receive      (SOF_TIMESTAMPING_RX_HARDWARE)
        software-receive      (SOF_TIMESTAMPING_RX_SOFTWARE)
        software-system-clock (SOF_TIMESTAMPING_SOFTWARE)
        hardware-raw-clock    (SOF_TIMESTAMPING_RAW_HARDWARE)
PTP Hardware Clock: 0
Hardware Transmit Timestamp Modes:
        off                   (HWTSTAMP_TX_OFF)
        on                    (HWTSTAMP_TX_ON)
Hardware Receive Filter Modes:
        none                  (HWTSTAMP_FILTER_NONE)
        all                   (HWTSTAMP_FILTER_ALL)
        ptpv1-l4-sync         (HWTSTAMP_FILTER_PTP_V1_L4_SYNC)
        ptpv1-l4-delay-req    (HWTSTAMP_FILTER_PTP_V1_L4_DELAY_REQ)
        ptpv2-l4-sync         (HWTSTAMP_FILTER_PTP_V2_L4_SYNC)
        ptpv2-l4-delay-req    (HWTSTAMP_FILTER_PTP_V2_L4_DELAY_REQ)
        ptpv2-l2-sync         (HWTSTAMP_FILTER_PTP_V2_L2_SYNC)
        ptpv2-l2-delay-req    (HWTSTAMP_FILTER_PTP_V2_L2_DELAY_REQ)
        ptpv2-event           (HWTSTAMP_FILTER_PTP_V2_EVENT)
        ptpv2-sync            (HWTSTAMP_FILTER_PTP_V2_SYNC)
        ptpv2-delay-req       (HWTSTAMP_FILTER_PTP_V2_DELAY_REQ)
```

软件时戳需要以下参数：

```
SOF_TIMESTAMPING_SOFTWARE
SOF_TIMESTAMPING_TX_SOFTWARE
SOF_TIMESTAMPING_RX_SOFTWARE
```

硬件时戳需要以下参数：

```
SOF_TIMESTAMPING_RAW_HARDWARE
SOF_TIMESTAMPING_TX_HARDWARE
SOF_TIMESTAMPING_RX_HARDWARE
```

`ethtool` 打印的PTP 硬件时钟值是 PTP 硬件时钟的索引。它与 `/dev/ptp*` 设备的命名相对应。第一个 PHC 的索引为 0

## ptp4l

### ptp4l 参数

延迟机制选项

- `-A`：自动模式，自动选择 E2E 延迟机制，当收到对等延迟请求时切换到 P2P。
- `-E`：E2E 模式，请求应答延迟机制（默认）。注意：单个 PTP 通信路径上的所有时钟必须使用相同的机制。
- `-P`：P2P 模式，对等延迟机制。

网络传输选项

- `-2`：IEEE 802.3
- `-4`：UDP IPv4（默认）
- `-6`：UDP IPv6

时间戳选项

- `-H`：硬件时间戳（默认）
- `-S`：软件模拟时间戳
- `-L`：老的硬件时间戳，LEGACY HW 需要配合 PHC 设备使用。

其他选项

- `-f [file]`：从指定文件 file 中读取配置，默认情况下不读取任何配置文件。
- `-i [dev]`：选择 PTP 接口设备，例如 eth0（可多次指定），必须至少使用此选项或配置文件指定一个端口。
- `-p [dev]`：此选项用于在旧 Linux 内核上指定要使用的 PHC 设备（例如 `/dev/ptp0` 时钟设备），默认为 auto，忽略软件 / LEGACY HW 时间戳。
- `-s`：从时钟模式（Slave only mode），将覆盖配置文件。
- `-t`：透明时钟模式。
- `-l [num]`：将日志记录级别设置为 num，默认为 6。
- `-m`：将消息打印到 stdout。
- `-q`：不打印消息到 syslog。
- `-h`, `--help` ：显示帮助信息并退出。
- `-V`, `--version` ：显示版本信息并退出。

### ptp4l 示例

对于支持硬件时间戳的主机，可通过以下命令运行主时钟

```bash
ptp4l -m -H -i eth0
```

运行 slave 时钟

```bash
ptp4l -i eth0 -m -H -s
```

若主机不支持硬件时间戳，可通过以下命令启用 PTP 软件时间戳

```bash
ptp4l -m -S -i eth0          # 主时钟
ptp4l -m -S -s -i eth0       # 从时钟
```

### 配置 ptp4l

修改 `/etc/sysconfig/ptp4l` 中关于网卡的配置

`ptp4l` 默认使用硬件时戳。

需要使用 `-i` 选项指定支持硬件时戳的网络接口。

`-s` 作为 slave 向外界同步（以其他时钟的时间为准）

`-A` 见延迟测量

```bash
# cat /etc/sysconfig/ptp4l 
OPTIONS="-f /etc/ptp4l.conf -i eth0 -m -H -s -A -4 --step_threshold=1.0 --summary_interval=10"
# -2 视情况，部分不支持数据链路层
```

修改 `/etc/ptp4l.conf` 配置

`ptp4l` 通常会频繁写入消息。可以使用 `summary_interval` 指令降低该频率。其值的表达式为 2 的 N 次幂。例如，要将输出频率降低为每隔 1024（等于 2^10）秒，需要更改 `summary_interval` 为 10。

需要可以提高进程的实时性和绑定 CPU 核心，可以使用 chrt 和 taskset

```bash
[Unit]
Description=Precision Time Protocol (PTP) service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/ptp4l
# ExecStart=/usr/sbin/ptp4l $OPTIONS
ExecStart=/usr/bin/taskset -c 0 /usr/bin/chrt 90 /usr/sbin/ptp4l $OPTIONS

[Install]
WantedBy=multi-user.target

```

如果使用 UDP 且需要调整防火墙，则需要执行

```bash
iptables -I INPUT -p udp -m udp --dport 319 -j ACCEPT
iptables -I INPUT -p udp -m udp --dport 320 -j ACCEPT
```

如果开启 SELinux，则需要 <https://man.linuxreviews.org/man8/ptp4l_selinux.8.html>

```bash
semanage permissive -a ptp4l_t
# can be used to make the process type ptp4l_t permissive
```

启动 ptp4l 服务

```bash
systemctl enable --now ptp4l

# 查看状态
systemctl status ptp4l
```

`ptp4l` 输出示例：

```bash
tp4l[352.361]: port 1: INITIALIZING to LISTENING on INITIALIZE
ptp4l[352.361]: port 0: INITIALIZING to LISTENING on INITIALIZE
ptp4l[353.210]: port 1: new foreign master 00a069.eefe.0b442d-1
ptp4l[357.214]: selected best master clock 00a069.eefe.0b662d
ptp4l[357.214]: port 1: LISTENING to UNCALIBRATED on RS_SLAVE
ptp4l[359.224]: master offset       3304 s0 freq      +0 path delay      9202
ptp4l[360.224]: master offset       3708 s1 freq  -28492 path delay      9202
ptp4l[361.224]: master offset      -3145 s2 freq  -32637 path delay      9202
ptp4l[361.224]: port 1: UNCALIBRATED to SLAVE on MASTER_CLOCK_SELECTED
ptp4l[362.223]: master offset       -145 s2 freq  -30580 path delay      9202
ptp4l[363.223]: master offset       1043 s2 freq  -28436 path delay      8972
[...]
ptp4l[371.235]: master offset        285 s2 freq  -28511 path delay      9199
ptp4l[372.235]: master offset        -78 s2 freq  -28788 path delay      9204
```

主偏移值是与主偏移量测得的偏移量（以纳秒为单位）。

`s0`、`s1`、`s2` 字符串表示不同的时钟伺服状态：s0 表示未锁定，s1 表示正在同步，s2 表示锁定，锁定状态表示不会再发生阶跃行同步，只是缓慢调整；所以正常情况下，两台设备间只有初次 PTP 同步的时候时间才会大幅度调整，再之后若调整主设备时间，则从设备时间不会调整。

`freq` 值是以十亿分之一 （ppb） 为单位的时钟频率调整。

路径延迟值是从主服务器发送的同步消息的估计延迟（以纳秒为单位）。

端口 0 是用于本地 `PTP` 管理的 Unix 域套接字。端口 1 是 `eth0` 接口（基于上面的示例）。

INITIALIZING、LISTENING、UNCALIBRATED 和 SLAVE 是一些可能的端口状态，这些状态会在 INITIALIZE、RS_SLAVE MASTER_CLOCK_SELECTED 事件中发生变化。在最后一条状态更改消息中，端口状态从 UNCALIBRATED 更改为 SLAVE，表示与 `PTP` 主时钟同步成功。

### 延迟测量

`ptp4l` 通过两种方法测量时间延迟：对等式 (P2P) 或端到端 (E2E)。

- P2P

  此方法使用 `-P` 指定。它可以更快地对网络环境中的更改做出反应，并可更准确地测量延迟。仅在每个端口都会与另一个端口交换 PTP 消息的网络中才会使用此方法。P2P 需受到通讯路径中所有硬件的支持。

- E2E

  此方法使用 `-E` 指定。此为默认设置。

- 自动选择方法

  此方法使用 `-A` 指定。自动选项以 E2E 模式启动 `ptp4l`，如果收到了对等延迟请求，则会切换为 P2P 模式。

单个 PTP 通讯路径上的所有时钟必须使用相同的方法来测量时间延迟。如果在使用 E2E 机制的端口上收到了对等延迟请求，或者在使用 P2P 机制的端口上收到了 E2E 延迟请求，则会列显警告。

## phc2sys

### phc2sys 参数

自动配置：

- `-a`：开启自动配置。
- `-r`：同步系统（实时）时钟，重复 `-r` 将其也视为时间源。

手动配置：

- `-c [dev|name]`：从时钟（CLOCK_REALTIME）。
- `-d [dev]`：主 PPS 设备。
- `-s [dev|name]`：主时钟。
- `-O [offset]`：从主时间偏移量，默认为 0。
- `-w`：等待 ptp4l。

通用选项：

- `-E [pi|linreg]`：时钟伺服，默认为 pi。
- `-P [kp]`：比例常数，默认为 0.7。
- `-I [ki]`：积分常数，默认为 0.3。
- `-S [step]`：设置步阈值，默认不开启。
- `-F [step]`：仅在开始时设置步阈值，默认为 0.00002。
- `-R [rate]`：以 HZ 为单位的从属时钟更新率，默认为 1 HZ。
- `-N [num]`：每次更新的主时钟读数数量，默认为 5。
- `-L [limit]`：以 ppb 为单位的健全频率限制，默认为 200000000。
- `-M [num]`：NTP SHM 段号，默认为 0。
- `-u [num]`：摘要统计中的时钟更新次数，默认为 0。
- `-n [num]`：域编号（domain number），默认为 0。
- `-x`：通过伺服而不是内核应用闰秒。
- `-z [path]`：UDS 的服务器地址（/var/run/ptp4l）。
- `-l [num]`：将日志记录级别设置为 num，默认为 6。
- `-t [tag]`：为日志消息添加标记（tag）。
- `-m`：将消息打印到标准输出（stdout）。
- `-q`：不要将消息打印到系统日志（syslog）。
- `-v`：显示版本信息并退出。
- `-h`：显示帮助信息并退出。

### phc2sys 示例

phc2sys 实现网卡上的时钟同步到操作系统（以网卡上的时钟为 master）

将系统时钟同步到网卡上的 PTP 硬件时钟（PHC），使用 `-s` 可按设备或网络接口指定主时钟，使用 `-w` 可等待直到 `ptp4l` 进入已同步状态：

```bash
phc2sys -s eth0 -w
```

PTP 按国际原子时（TAI）运行，而系统时钟使用的是协调世界时（UTC）。如果不指定 `-w` 来等待 `ptp4l` 同步，可以使用 `-O` 来指定 TAI 与 UTC 之间的偏差（以秒为单位）

TAI 和 UTC 时间刻度之间的当前偏移量为 36 秒。当插入或删除闰秒时，偏移量会发生变化，这通常每隔几年发生一次。当不使用 `-w` 时，需要使用 `-O` 选项手动设置此偏移量，如下所示：

```bash
phc2sys -s eth0 -O -36
# phc2sys -s eth0 -O -35
```

### 配置 phc2sys

使用 phc2sys 可将系统时钟同步到网卡上的 PTP 硬件时钟 (PHC)。系统时钟被视为从属时钟，而网卡上的时钟则为主时钟。PHC 本身将与 ptp4l 同步。

使用 `-s` 可按设备或网络接口指定主时钟。使用 `-w` 等待 `ptp4l` 进入同步状态。`-w` 选项等待正在运行的 ptp4l 应用程序同步 `PTP` 时钟，然后从 ptp4l 检索 TAI 到 UTC 的偏移量。

配置文件

```bash
# cat /etc/sysconfig/phc2sys

# OPTIONS="-a -r"
OPTIONS="-s eth0 -c CLOCK_REALTIME -m --step_threshold=1.0 -w -u 600"
```

`-a` 选项使 phc2sys 从 ptp4l 应用程序读取要同步的时钟。它将跟随 `PTP` 端口状态的变化，相应地调整 NIC 硬件时钟之间的同步。除非还指定了 `-r` 选项，否则系统时钟不会同步。`-a -r` 会自动寻找当前运行的 ptp4l 程序，利用它的时钟，同步给操作系统时钟，操作系统时钟是 slave。

第二种用法中的 `-s eth0 -c CLOCK_REALTIME -w` 写的更清楚一点。`-s` 指定 master clock；`-c` 指定 slave clock 或 (CLOCK_REALTIME)，CLOCK_REALTIME 指的是操作系统的时钟。

`--step_threshold=1.0` 在 master 时钟发生突变时，slave 不是一下就跟过去，而是一步步跟过去，避免时钟跳变。

也可以使用 `-u SUMMARY-UPDATES` 选项降低 `phc2sys` 命令的更新频率，单位为秒。

为了防止 `PTP` 时钟频率的快速变化，可以通过使用较小的 `P` （比例） 和 `I` （积分）常数来避免时间跳变：

```bash
phc2sys ... -P 0.01 -I 0.0001
```

需要可以提高进程的实时性和绑定 CPU 核心，可以使用 chrt 和 taskset

```bash
[Unit]
Description=Synchronize system clock or PTP hardware clock (PHC)
After=ntpdate.service ptp4l.service

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/phc2sys
# ExecStart=/usr/sbin/phc2sys $OPTIONS
ExecStart=/usr/bin/taskset -c 0 /usr/bin/chrt 89 /usr/sbin/phc2sys $OPTIONS

[Install]
WantedBy=multi-user.target
```

启动 phc2sys 服务

```bash
systemctl enable --now phc2sys

# 查看状态
systemctl status phc2sys
```

## 校验时间同步

当 PTP 时间同步正常工作并且使用了硬件时戳时，`ptp4l` 和 `phc2sys` 会定期向系统日志输出包含时间偏差和频率调节的消息。

`ptp4l` 输出示例：

```bash
tp4l[352.361]: port 1: INITIALIZING to LISTENING on INITIALIZE
ptp4l[352.361]: port 0: INITIALIZING to LISTENING on INITIALIZE
ptp4l[353.210]: port 1: new foreign master 00a069.eefe.0b442d-1
ptp4l[357.214]: selected best master clock 00a069.eefe.0b662d
ptp4l[357.214]: port 1: LISTENING to UNCALIBRATED on RS_SLAVE
ptp4l[359.224]: master offset       3304 s0 freq      +0 path delay      9202
ptp4l[360.224]: master offset       3708 s1 freq  -28492 path delay      9202
ptp4l[361.224]: master offset      -3145 s2 freq  -32637 path delay      9202
ptp4l[361.224]: port 1: UNCALIBRATED to SLAVE on MASTER_CLOCK_SELECTED
ptp4l[362.223]: master offset       -145 s2 freq  -30580 path delay      9202
ptp4l[363.223]: master offset       1043 s2 freq  -28436 path delay      8972
[...]
ptp4l[371.235]: master offset        285 s2 freq  -28511 path delay      9199
ptp4l[372.235]: master offset        -78 s2 freq  -28788 path delay      9204
```

其中 master offset 就是 master、slave 设备之间的时间偏移量，单位：ns

`phc2sys` 输出示例：

```bash
phc2sys[1118350.191]: CLOCK_REALTIME rms  147 max  179 freq  -2393 +/-  36 delay   531 +/-   0
phc2sys[1118352.192]: CLOCK_REALTIME rms  129 max  183 freq  -2548 +/-  64 delay   521 +/-   0
phc2sys[1118354.192]: CLOCK_REALTIME rms   53 max   60 freq  -2425 +/-  14 delay   526 +/-   5
phc2sys[1118356.192]: CLOCK_REALTIME rms   67 max   82 freq  -2380 +/-  24 delay   531 +/-   0
```

输出包括：

- 偏移均方根（rms）
- 最大绝对误差（最大值）
- 频率偏移（freq）：其平均值和标准偏差
- 路径延迟（delay）：其含义和标准偏差

## PTP 管理客户端

文档：<<https://docs.redhat.com/zh-cn/documentation/red_hat_enterprise_linux/7/html/system_administrators_guide/sec-using_the_ptp_management_client>>

可以使用 `pmc` 客户端获取有关 `ptp` 的更详细信息。pmc 从标准输入或命令行读取按名称和管理 ID 指定的操作。然后通过选定的传输方式发送操作，并列显收到的任何答复。pmc 支持以下三个操作：`GET` 可检索指定的信息，`SET` 可更新指定的信息，`CMD`（或 `COMMAND`）可发起指定的事件。

默认情况下，管理命令会在所有端口上寻址。可以使用 `TARGET` 命令为后续消息选择特定的时钟和端口。

```bash
pmc -u -b 0 'GET TIME_STATUS_NP'

pmc -u -b 0 'GET CURRENT_DATA_SET'
```

`-b` 选项指定所发送消息中的边界跃点值。将此选项设置为 0 会将边界限制为本地 `ptp4l` 实例。如果将该值设置得更高，则还会检索距离本地实例更远的 PTP 节点发出的消息。返回的信息可能包括：

- stepsRemoved

超级主时钟的通讯节点数。

- offsetFromMaster、master_offset

该时钟与主时钟之间上次测得的偏差（纳秒）。

- meanPathDelay

从主时钟发送的同步消息的预计延迟（纳秒）。

- gmPresent

如果为 `true`，则表示 PTP 时钟已同步到主时钟；本地时钟不是超级主时钟。

- gmIdentity

此为超级主时钟身份。

## 参考资料

- <https://docs.redhat.com/zh-cn/documentation/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/chrony-with-hw-timestamping_configuring-time-synchronization>

- <https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/configuring-time-synchronization_configuring-basic-system-settings#chrony-with-hw-timestamping_configuring-time-synchronization>

- <https://tsn.readthedocs.io/timesync.html>