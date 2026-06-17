## etcd 调优概述

etcd 的核心架构基于 Raft 一致性协议，通过 WAL（Write-Ahead Log）日志保证数据持久性，底层使用 BoltDB 进行数据存储。这个设计虽然保证了强一致性，但也带来了几个关键性能瓶颈：

- 磁盘 I / O 是主要瓶颈：每次写入都要先写 WAL 日志，然后提交到 BoltDB，这要求磁盘必须有很低的延迟。SSD / NVMe 是必须的，但仅有 SSD 还不够。

- 内存压力：etcd 需要将整个数据集加载到内存中进行快速查询，当集群规模扩大时，内存消耗会显著增加。

- 碎片问题：频繁的写入删除操作会导致 BoltDB 内部产生大量碎片，影响读写性能。

## 提高磁盘 IO 性能

etcd 对磁盘写入延迟非常敏感

- 磁盘延迟：etcd 对延迟极其敏感，WAL 日志的 fsync 操作必须快速完成。如果磁盘延迟超过 10ms，etcd 性能就会明显下降。

- IOPS 不是关键：etcd 的写入模式是顺序写 + 随机读，对 IOPS 要求不高，但对延迟要求很高。

- 磁盘隔离：生产环境中, etcd 的数据盘应该独立，避免与其他高 I / O 应用共享磁盘。监控关键指标：disk_wal_fsync_duration 应该保持在 10ms 以内，db_size 增长过快可能意味着需要压缩。

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

# 8GB
--quota-backend-bytes=8589934592
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
# 自动压缩并保留 72 小时窗口
# 其他可选，比如 6h、12h、24h
--auto-compaction-mode=periodic
--auto-compaction-retention=72h
```

## Raft 日志保留

`--snapshot-count` 指定有多少条事务(transaction)被提交时，触发快照保存到磁盘。在存盘之前，Raft 条目将一直保存在内存中。从 v3.2 版本开始，`--snapshot-count` 条数从 10000 改为 100000，因此这将占用很大一部分内存资源。

如果节点总内存资源不多，或者是单 etcd 实例运行，则可以把 `--snapshot-count` 适当的缩减，比如设置为 `--snapshot-count=50000`

## apiserver 缓存机制

Kubernetes apiserver 内置了 watch-cache 机制，可以显著减少对 etcd 的直接访问。

工作原理：

1. apiserver 在内存中维护资源的全量缓存

2. 客户端 LIST 请求直接从缓存返回，不访问 etcd

3. WATCH 请求通过缓存的事件流提供，减少 etcd 的 watch 连接数

```bash
# kube-apiserver 启动参数
--watch-cache-sizes=node#1000,pod#5000,service#500,secret#1000
```

这个配置的含义是：

- node 资源缓存 1000 条记录
- pod 资源缓存 5000 条记录
- service 资源缓存 500 条记录
- secret 资源缓存 1000 条记录

## 监控

### 性能指标

`etcd_disk_wal_fsync_duration_seconds`：WAL 同步延迟

`etcd_server_leader_changes_seen_total`：Leader 切换次数

`etcd_debugging_mvcc_db_total_size_in_bytes`：数据库大小

### 健康检查

定期执行 `etcdctl endpoint health`

监控节点间网络延迟

### 容量规划

根据 `db_size` 增长预测存储需求

监控 `etcd_server_quota_backend_bytes` 使用率

## 特定场景调优

### 大规模集群 LIST 性能优化

问题：5000 节点集群，kubectl get pods 响应缓慢

分析：大量 LIST 请求直接打到 etcd

解决：

1. 增大 apiserver `--watch-cache-sizes` 中 pod 的缓存大小
2. 启用 apiserver 的 `--enable-aggregator-routing` 分散请求压力
3. 客户端使用 `--chunk-size` 分批获取

### 频繁的 Leader 切换

问题：etcd 集群不稳定，频繁切换 Leader

分析：网络延迟或磁盘 I / O 不稳定

解决：

1. 调整 `--heartbeat-interval` 和 `--election-timeout`
2. 确保 etcd 节点时钟同步（NTP）
3. 检查网络 QoS 配置，保证 etcd 流量优先级

### 存储空间快速增长

问题：etcd 数据库大小每周增长 10GB

分析：大量短期 pod 创建删除导致碎片

解决：

1. 设置更激进的压缩策略：`--auto-compaction-retention=30m`
2. 定期执行在线碎片整理
3. 考虑使用 etcd 3.5+ 的 `--experimental-compaction-batch-limit`