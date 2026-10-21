## Nmap 扫描

默认主机发现扫描

```bash
nmap 192.168.0.1-255
```

Nmap 会发送一个 ICMP echo 请求，一个 TCP SYN 包给 443 端口，一个 TCP ACK 包给 80 端口和一个 ICMP 时间戳请求

## 参考资料

- <https://wiki.wgpsec.org/knowledge/tools/nmap.html>