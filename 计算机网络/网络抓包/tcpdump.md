## tcpdump 简介

## pcap 过滤

示例

```bash
OUTPUT_PKG_DIR=/root/output
PKG_SUFFIX="$(date -d yesterday +%Y%m%d)-06.pcap"
PKG_SLIM_SUFFIX="$(date -d yesterday +%Y%m%d)-slim-06.pcap"

tcpdump \
    -r "${OUTPUT_PKG_DIR}/sgx-38-enp23s0f0-${PKG_SUFFIX}" \
    -w "${OUTPUT_PKG_DIR}/sgx-38-enp23s0f0-${PKG_SLIM_SUFFIX}" \
    --time-stamp-precision=nano -nn -G 86400 -Z root \
    'udp dst port 2042 or udp dst port 4042 or udp dst port 12042 or udp dst port 14042'

```

参考文档

- 过滤：<https://zhuanlan.zhihu.com/p/417275080>

## 回放报文

```bash
tcpdump -r old_file -w new_files '<capture filters>'
```

## 抓包丢包现象处理

造成这种丢包的原因是由于 libcap 抓到包后，tcpdump 上层没有及时的取出，导致 libcap 缓冲区溢出，从而覆盖了未处理包。也就是说 tcpdump 使用 libcap 将在 linux 内核协议栈中的数据包文件提取出来，放到 libcap 的缓存区内，tcpdump 处理 ibcap 缓存区内数据，而但 tcpdump 处理速度跟不上时，libcap 缓冲区内容就会被覆盖，从而产生丢包现象

1. 最小化抓取过滤范围，即通过指定网卡，端口，包流向，包大小减少包数量

2. 添加 `-n` 参数，禁止反向域名解析

3. 添加 `--buffer-size=409600` 参数，加大 OS capture buffer size

4. 指定 `-s` 参数， 最好小于 1000

5. 将数据包输出到 cap 文件

6. 用 sysctl 修改 `SO_REVBUF` 参数，增加 libcap 缓冲区长度 `/proc/sys/net/core/rmem_default` 和 `/proc/sys/net/core/rmem_max`

   ```
   sysctl -w net.core.rmem_default=16777216
   sysctl -w net.core.wmem_default=16777216
   sysctl -w net.core.rmem_max=16777216
   sysctl -w net.core.wmem_max=16777216
   ```

7. `UDP buffer size` 不足

## 使用 systemd 运行 tcpdump

## 参考资料

- <https://xuqilong.top/pages/31b0ac/#%E6%98%AF%E4%BB%80%E4%B9%88>

- <https://blog.csdn.net/qq_44808875/article/details/126142700>

- <https://tonydeng.github.io/sdn-handbook/linux/tcpdump.html>