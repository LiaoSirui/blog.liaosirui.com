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



## Pod DnsPolicy

None,无任何策略:表示空的DNS设置，这种方式一般用于想要自定义 DNS 配置的场景，往往需要和 dnsConfig 配合一起使用达到自定义 DNS 的目的。

Default,默认: 此种方式是让kubelet来决定使用何种DNS策略。而kubelet默认的方式，就是使用宿主机的/etc/resolv.conf文件。同时，kubelet也可以配置指定的DNS策略文件，使用kubelet参数即可，如：–resolv-conf=/etc/resolv.conf

ClusterFirst, 集群 DNS 优先:此种方式是使用kubernets集群内部中的kubedns或coredns服务进行域名解析。若解析不成功，才会使用宿主机的DNS配置来进行解析。

ClusterFistWithHostNet, 集群 DNS 优先，并伴随着使用宿主机网络:在某些场景下，我们的 POD 是用 HOST 模式启动的（HOST模式，是共享宿主机网络的），一旦用 HOST 模式，表示这个 POD 中的所有容器，都要使用宿主机的 /etc/resolv.conf 配置进行DNS查询，但如果你想使用了 HOST 模式，还继续使用 Kubernetes 的DNS服务，那就将 dnsPolicy 设置为 ClusterFirstWithHostNet

## 参考文档

- 参考：<https://cloud.tencent.com/developer/beta/article/1981388>

- <https://tinychen.com/20221107-dns-12-coredns-09-kubernetes/>