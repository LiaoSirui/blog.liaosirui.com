集群规模较大并发较高的情况下对 DNS 进行优化

官方文档：

- Using NodeLocal DNSCache in Kubernetes Clusters <https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/>
- NodeLocal AddOn <https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml>

在 Kubernetes 中可以使用 CoreDNS 来进行集群的域名解析，但是如果在集群规模较大并发较高的情况下我们仍然需要对 DNS 进行优化，典型的就是大家比较熟悉的 CoreDNS 会出现超时 5s 的情况。