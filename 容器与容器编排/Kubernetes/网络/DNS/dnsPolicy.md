None,无任何策略:表示空的DNS设置，这种方式一般用于想要自定义 DNS 配置的场景，往往需要和 dnsConfig 配合一起使用达到自定义 DNS 的目的。

Default,默认: 此种方式是让kubelet来决定使用何种DNS策略。而kubelet默认的方式，就是使用宿主机的/etc/resolv.conf文件。同时，kubelet也可以配置指定的DNS策略文件，使用kubelet参数即可，如：–resolv-conf=/etc/resolv.conf

ClusterFirst, 集群 DNS 优先:此种方式是使用kubernets集群内部中的kubedns或coredns服务进行域名解析。若解析不成功，才会使用宿主机的DNS配置来进行解析。

ClusterFistWithHostNet, 集群 DNS 优先，并伴随着使用宿主机网络:在某些场景下，我们的 POD 是用 HOST 模式启动的（HOST模式，是共享宿主机网络的），一旦用 HOST 模式，表示这个 POD 中的所有容器，都要使用宿主机的 /etc/resolv.conf 配置进行DNS查询，但如果你想使用了 HOST 模式，还继续使用 Kubernetes 的DNS服务，那就将 dnsPolicy 设置为 ClusterFirstWithHostNet

- 参考：<https://cloud.tencent.com/developer/beta/article/1981388>