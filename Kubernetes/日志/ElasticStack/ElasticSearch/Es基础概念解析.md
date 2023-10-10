<https://liuqh.icu/categories/%E6%90%9C%E7%B4%A2%E5%BC%95%E6%93%8E/>

## 索引

一般意义上的索引是一种基于文档（数据）生成、建立的，用于快速定位指定文档的工具。

<img src=".assets/image-20230116144627579.png" alt="image-20230116144627579" style="zoom:50%;" />

而 ElasticSearch 对索引的定义有所不同，ElasticSearch 中的索引对应 MySQL 中的 Database ，也就说 ElasticSearch 中的索引更像是一种数据存储集合，即用于存储文档。

ElasticSearch 中的数据根据业务以索引为单位进行划分，Type（类型） 就像 MySQL 中的 Table 一样，用于区分同一业务中不同的数据集合，如下图：

<img src=".assets/image-20230116144741322.png" alt="image-20230116144741322" style="zoom:50%;" />

当然上图并不是指 ElasticSearch 中就真的这么存储数据，而是大概的表现方式。

不过在 6.x 版本后，就废弃了 Type ，因为设计者发现 ElasticSearch 这种与关系型数据类比的设计方式有缺陷。在关系型数据库中，每个数据表都是相互独立的，即在不同表中相同的数据域是互不关联的。而 ElasticSearch 底层所用的 Lucene 并没有关系型数据中的这种特性，在 ElasticSearch 同一个索引中，不同映射类型但是名称相同的数据域在 Lucene 中是同一个数据域，即作为同一类数据存放在一起。

ElasticSearch 6.x 版本废弃掉 Type 后，建议的是每个类型（业务）的数据单独放在一个索引中，这样其实回归到一般意义上的索引定义，索引定位文档。如下图：

<img src=".assets/image-20230116144843046.png" alt="image-20230116144843046" style="zoom:50%;" />

上图也是一种大概的表现方式，不代表 ElasticSearch 以这种方式处理文档。

> 如果 ElasticSearch 还是使用 5.x 或以下版本，建议每个索引只设置一个类型，做到一个索引存储一种数据。

## 分片

单个节点由于物理机硬件限制，存储的文档是有限的，如果一个索引包含海量文档，则不能在单个节点存储。ES 提供分片机制，同一个索引可以存储在不同分片（数据容器）中。

### 主分片和从分片

分片分为主分片 (primary shard) 以及从分片 (replica shard)。

- 主分片

主分片会被尽可能平均地 (rebalance) 分配在不同的节点上（例如你有 2 个节点，4 个主分片（不考虑备份），那么每个节点会分到 2 个分片，后来你增加了 2 个节点，那么你这 4 个节点上都会有 1 个分片，这个过程叫 relocation，ES 感知后自动完成)。

- 从分片

从分片只是主分片的一个副本，它用于提供数据的冗余副本，从分片和主分片不会出现在同一个节点上（防止单点故障），默认情况下一个索引创建 5 个主分片，每个主分片会有一个从分片 (5 primary + 5 replica = 10 个分片)。如果你只有一个节点，那么 5 个 replica 都无法被分配 (unassigned)，此时 cluster status 会变成 Yellow。

分片是独立的，对于一个 Search Request 的行为，每个分片都会执行这个 Request。每个分片都是一个 Lucene Index，所以一个分片只能存放如下这么多个 docs。

```bash
Integer.MAX_VALUE - 128 = 2,147,483,519
```

### 分片的作用

replica 的作用主要包括：

1. 容灾：primary 分片丢失，replica 分片就会被顶上去成为新的主分片，同时根据这个新的主分片创建新的 replica，集群数据安然无恙；
2. 提高查询性能：replica 和 primary 分片的数据是相同的，所以对于一个 query 既可以查主分片也可以查从分片，在合适的范围内多个 replica 性能会更优（但要考虑资源占用也会提升 [cpu/disk/heap]），另外 Index Request 只能发生在主分片上，replica 不能执行 Index Request。

**注意**：对于一个索引，除非重建索引否则不能调整主分片的数目 (number_of_shards)，但可以随时调整 replica 的数目 (number_of_replicas)。


