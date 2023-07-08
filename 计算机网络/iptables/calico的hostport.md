hostport  查看：

```bash
iptables -t nat -nvL CNI-HOSTPORT-DNAT
```

删除错误的规则

```bash
iptables -t nat -D CNI-HOSTPORT-DNAT 1
```

