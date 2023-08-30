hostport  查看：

```bash
iptables -t nat -nvL CNI-HOSTPORT-DNAT
```

删除错误的规则

```bash
iptables -t nat -D CNI-HOSTPORT-DNAT 1
```

nodeport

```bash
iptables -t nat -nvL KUBE-NODEPORTS
```

`iptables -t nat -L KUBE-NODEPORT | grep my-service` -> follow the chain. Normally load balancing is configured which can be seen in the `KUBE-SVC-<random>` rule, where the traffic should split to (in your case) 3 `KUBE-SEP-<random>` endpoint chains and DNATed to the 3 pod ips in the end
