关闭 dns 自动配置

```bash
nmcli connection modify eth0 ipv4.ignore-auto-dns yes

nmcli device modify eth0 ipv4.ignore-auto-dns yes
```
