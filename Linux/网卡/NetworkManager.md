列出当前活动的以太网卡

```bash
> nmcli connection

NAME             UUID                                  TYPE      DEVICE
eth0             0ac14f31-aefe-3540-be09-32ece613f1d0  ethernet  eth0
br-81a2d4f77acf  d691fd00-dad0-4dfd-ae93-ae6461164bf5  bridge    br-81a2d4f77acf
docker0          45fb9025-88be-4628-8dde-85daf487a485  bridge    docker0
```

## 配置

分配静态 IP

```bash
 nmcli connection modify <interface_name> ipv4.address  <ip/prefix>
```

为了简化语句，在 `nmcli` 命令中，我们通常用 `con` 关键字替换 `connection`，并用 `mod` 关键字替换 `modify`。

将 IPv4 地址 (192.168.1.4) 分配给 `enp0s3` 网卡上

```bash
nmcli con mod enp0s3 ipv4.addresses 192.168.1.4/24
```

使用下面的 `nmcli` 命令设置网关

```bash
nmcli con mod enp0s3 ipv4.gateway 192.168.1.1
```

设置手动配置（从 dhcp 到 static）

```bash
nmcli con mod enp0s3 ipv4.method manual
```

设置 DNS 值为 “8.8.8.8”

```bash
 nmcli con mod enp0s3 ipv4.dns "8.8.8.8"
```

要保存上述更改并重新加载，请执行如下 `nmcli` 命令

```bash
 nmcli con up enp0s3
```

以上命令显示网卡 `enp0s3` 已成功配置。使用 `nmcli` 命令做的那些更改都将永久保存在文件  `/etc/sysconfig/network-scripts/ifcfg-enp0s3` 里。

关闭 dns 自动配置

```bash
nmcli connection modify eth0 ipv4.ignore-auto-dns yes

nmcli device modify eth0 ipv4.ignore-auto-dns yes
```
