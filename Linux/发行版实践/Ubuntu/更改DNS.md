修改 `/etc/systemd/resolved.conf` 文件

```bash
vi /etc/systemd/resolved.conf
```

设置这些参数：

```bash
# 指定 DNS 服务器，以空白分隔，支持 IPv4 或 IPv6 位置
DNS=8.8.8.8 114.114.115.115
```

启 systemd-resolved 服务

```bash
systemctl restart systemd-resolved
```