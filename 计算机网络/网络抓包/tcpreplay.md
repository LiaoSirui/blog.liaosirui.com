## tcpreplay

tcpreplay 是一款强大的网络数据包重放工具，它可以将捕获到的网络流量（通常是 pcap 格式的文件）重新重放到网络中，实现对网络通信的重现。这在网络故障排查、安全测试、性能测试、开发调试等场景下具有广泛的应用。同时，tcpreplay 不仅仅能重放 TCP 协议报文，它支持重放所有协议报文，同时支持 IPv4 和 IPv6 协议栈

将 PCAP 包重新发送，用于性能或者功能测试

## 重放报文

```bash
tcpreplay -v -i eth0 client_fix.pcap
# tcpreplay -v -t -i eth0 client_fix.pcap

# -v 参数可以看到重放的每一帧的细节
# -t 参数尽可能快的重放数据包
```

常用选项

- `-p`：指定每秒发包的个数，指定该参数，其他与速率有关的参数将被忽略

- `-t`：`<mtu>` 指定 mtu 数值，标准的 10/100M 网卡的默认 mtu 数值为 1500

- `-i`：`<网口号>` 双网卡播包必选参数，指定播放的主网口

- `-I`：`<mac>`重写主网卡发送报文的目的 MAC 地址

- `-l`：`<循环次数>` 循环播放的次数

- `-m`： `<multiple>`  指定一个倍数值，就是必默认发送速率要快多少倍的速率发送报文。 加大发送的速率后，对于 DUT 可能意味着有更多的并发连接和连接数，特别是对于 BT 报文的重放， 因为连接的超时是固定的，如果速率增大的话， 留在 session 表中的连接数量增大，还可以通过修改连接的超时时间来达到该目的
- `-w`：`<file>` 将主网卡发送的报文写到文件中去
- `-v`：每播放一个报文都以 tcpdump 格式打印出来

报文预先处理

```bash
PKG_DIR=/mnt/data-hdd/CFFEX-LV2
PKG_DATE=20250415
PKG_SLIM_SUFFIX="slim"

tcpdump \
    -r "${PKG_DIR}/${PKG_DATE}.pcap" \
    -w "${PKG_DIR}/${PKG_DATE}-${PKG_SLIM_SUFFIX}.pcap" \
    --time-stamp-precision=nano -nn -G 86400 -Z root \
    'udp dst port 20110 or udp dst port 21110 or udp dst port 22110 or udp dst port 23110'

tcprewrite \
    --pnat=172.24.18.33:192.168.152.136,172.24.19.34:192.168.152.136,172.24.22.37:192.168.152.136,172.24.23.38:192.168.152.136 \
    --infile="${PKG_DIR}/${PKG_DATE}-${PKG_SLIM_SUFFIX}.pcap" \
    --outfile="${PKG_DIR}/${PKG_DATE}-${PKG_SLIM_SUFFIX}.pcap-map"

```

然后播放

```bash
PKG_DIR=/mnt/data-hdd/CFFEX-LV2
PKG_DATE=20250415
PKG_SLIM_SUFFIX="slim"

tcpreplay -i ens37 "${PKG_DIR}/${PKG_DATE}-${PKG_SLIM_SUFFIX}.pcap-map"
# tcpreplay -v -i ens37 "${PKG_DIR}/${PKG_DATE}-${PKG_SLIM_SUFFIX}.pcap-map"

```

