集群中 kubelet 的启动参数有

- `--cluster-dns=<dns-service-ip>`
- `--cluster-domain=<default-local-domain>`

这两个参数分别被用来设置集群 DNS 服务器的 IP 地址和主域名后缀

Pod 内的 DNS 域名解析配置文件为 `/etc/resolv.conf`，文件内容如下

```plain
nameserver xx.xx.0.10
search kube-system.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

| 参数           | 描述                                                         |
| :------------- | :----------------------------------------------------------- |
| **nameserver** | 定义DNS服务器的IP地址。                                      |
| **search**     | 设置域名的查找后缀规则，查找配置越多，说明域名解析查找匹配次数越多。ACK集群匹配有`kube-system.svc.cluster.local`、`svc.cluster.local`、`cluster.local`3个后缀，最多进行8次查询才能得到正确解析结果，因为集群里面进行IPV4和IPV6查询各四次。 |
| **options**    | 定义域名解析配置文件选项，支持多个KV值。例如该参数设置成`ndots:5`，说明如果访问的域名字符串内的点字符数量超过`ndots`值，则认为是完整域名，并被直接解析；如果不足`ndots`值，则追加**search**段后缀再进行查询。 |

## 参考文档

- <https://tinychen.com/20221107-dns-12-coredns-09-kubernetes/>