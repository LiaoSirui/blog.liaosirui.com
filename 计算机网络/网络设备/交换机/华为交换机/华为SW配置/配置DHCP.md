查看 IP Pool

```bash
[HW-SW-01]display ip pool
```

创建 IP Pool

```bash
[HW-SW-01]ip pool dhcp25
[HW-SW-01-ip-pool-dhcp25]network 172.31.25.0 mask 24
[HW-SW-01-ip-pool-dhcp25]gateway-list 172.31.25.254
[HW-SW-01-ip-pool-dhcp25]dns-list 8.8.8.8
```

开启 DHCP

```bash
[HW-SW-01]interface Vlanif 25
[HW-SW-01-Vlanif25]dhcp select global
```

查看指定 IP 池的使用情况

```bash
<HW-SW-01>display ip pool name dhcp25 used
```

