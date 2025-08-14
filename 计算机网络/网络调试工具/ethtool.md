`ethtool -g` 可以查看某个网卡的 ring buffer，比如下面的例子

```bash
$ ethtool -g enp3s0f0
Ring parameters for enp3s0f0:
Pre-set maximums:
RX:		4096
RX Mini:	n/a
RX Jumbo:	n/a
TX:		2048
Current hardware settings:
RX:		1024
RX Mini:	n/a
RX Jumbo:	n/a
TX:		1024
```

Pre-set 表示网卡最大的 ring buffer 值，可以使用 `ethtool -G eth0 rx 4096` 设置它的值。