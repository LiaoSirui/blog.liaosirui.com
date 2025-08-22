## 提高磁盘 IO 性能

ETCD 对磁盘写入延迟非常敏感，对于负载较重的集群建议磁盘使用 SSD 固态硬盘。可以使用 diskbench 或 fio 测量磁盘实际顺序 IOPS

## 提高 ETCD 的磁盘 IO 优先级

由于 ETCD 必须将数据持久保存到磁盘日志文件中，因此来自其他进程的磁盘活动可能会导致增加写入时间，结果导致 ETCD 请求超时和临时 leader 丢失。当给定高磁盘优先级时，ETCD 服务可以稳定地与这些进程一起运行:

```bash
sudo ionice -c2 -n0 -p $(pgrep etcd)
```

## 提高存储配额

默认 ETCD 空间配额大小为 2G，超过 2G 将不再写入数据。通过给 ETCD 配置 `--quota-backend-bytes` 参数增大空间配额，最大支持 8G。

```bash
# 6GB
--quota-backend-bytes=6442450944
```

## 分离 events 存储

集群规模大的情况下，集群中包含大量节点和服务，会产生大量的 event，这些 event 将会对 etcd 造成巨大压力并占用大量 etcd 存储空间，为了在大规模集群下提高性能，可以将 events 存储在单独的 ETCD 集群中。

配置 kube-apiserver：

```bash
--etcd-servers="http://etcd1:2379,http://etcd2:2379,http://etcd3:2379"
--etcd-servers-overrides="/events#http://etcd4:2379,http://etcd5:2379,http://etcd6:2379"
```

## 减小网络延迟

如果有大量并发客户端请求 ETCD leader 服务，则可能由于网络拥塞而延迟处理 follower 对等请求。在 follower 节点上的发送缓冲区错误消息：

```bash
dropped MsgProp to 247ae21ff9436b2d since streamMsg's sending buffer is full
dropped MsgAppResp to 247ae21ff9436b2d since streamMsg's sending buffer is full
```

可以通过在客户端提高 ETCD 对等网络流量优先级来解决这些错误。在 Linux 上，可以使用 tc 对对等流量进行优先级排序：

```bash
$ tc qdisc add dev eth0 root handle 1: prio bands 3
$ tc filter add dev eth0 parent 1: protocol ip prio 1 u32 match ip sport 2380 0xffff flowid 1:1
$ tc filter add dev eth0 parent 1: protocol ip prio 1 u32 match ip dport 2380 0xffff flowid 1:1
$ tc filter add dev eth0 parent 1: protocol ip prio 2 u32 match ip sport 2379 0xffff flowid 1:1
$ tc filter add dev eth0 parent 1: protocol ip prio 2 u32 match ip dport 2379 0xffff flowid 1:1
```

## 历史版本清理

ETCD 会存储多版本数据，随着写入的主键增加，历史版本将会越来越多，并且 ETCD 默认不会自动清理历史数据。数据达到 `--quota-backend-bytes` 设置的配额值时就无法写入数据，必须要压缩并清理历史数据才能继续写入。

所以，为了避免配额空间耗尽的问题，在创建集群时候建议默认开启历史版本清理功能。

可以通过 `--auto-compaction-mode` 设置压缩模式，可以选择 `revision` 或者 `periodic` 来压缩数据，默认为 `periodic`。

```bash
#  自动压缩并保留 72 小时窗口
--auto-compaction-mode=periodic
--auto-compaction-retention=72h
```

## Raft 日志保留

`--snapshot-count` 指定有多少条事务(transaction)被提交时，触发快照保存到磁盘。在存盘之前，Raft 条目将一直保存在内存中。从 v3.2 版本开始，`--snapshot-count` 条数从 10000 改为 100000，因此这将占用很大一部分内存资源。

如果节点总内存资源不多，或者是单 etcd 实例运行，则可以把 `--snapshot-count` 适当的缩减，比如设置为 `--snapshot-count=50000`