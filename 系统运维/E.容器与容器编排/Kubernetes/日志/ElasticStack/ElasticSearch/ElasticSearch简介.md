## 集群

节点通过设置集群名称，在同一网络中发现具有相同集群名称的节点，组成集群；每个集群都有一个 cluster name 作为标识，默认的集群名称为 elasticsearch

如果在同一网络中只有一个节点，则这个节点成为一个单节点集群

### 集群状态

- Green

所有主分片和从分片都准备就绪（分配成功），即使有一台机器挂了（假设一台机器一个实例），数据都不会丢失，但会变成 Yellow 状态

- Yellow

所有主分片准备就绪，但存在至少一个主分片（假设是 A）对应的从分片没有就绪，此时集群属于警告状态，意味着集群高可用和容灾能力下降，如果刚好 A 所在的机器挂了，而从分片还处于未就绪状态，那么 A 的数据就会丢失（查询结果不完整），此时集群进入 Red 状态

- Red

至少有一个主分片没有就绪（直接原因是找不到对应的从分片成为新的主分片），此时查询的结果会出现数据丢失（不完整）

### 节点

一个 ES 节点就是一个运行的 ES 实例，可以实现数据存储并且搜索的功能

每个节点都有一个唯一的名称作为身份标识，如果没有设置名称，默认使用 UUID 作为名称

> 最好给每个节点都定义上有意义的名称，在集群中区分出各个节点

一个机器可以有多个实例，所以并不能说一台机器就是一个 node，大多数情况下每个 node 运行在一个独立的环境或虚拟机上

常用的角色有如下：

- Master Node：主节点，该节点不和应用创建连接，每个节点都保存了集群状态，master 节点不占用磁盘 IO 和 CPU，内存使用量一般
- Master eligible nodes：合格节点，每个节点部署后不修改配置信息，默认就是一个 eligible 节点，该节点可以参加选主流程，成为 Mastere 节点。该节点也保存了集群节点的状态。eligible 节点比 Master 节点更节省资源，因为它还未成为 Master 节点，只是有资格成功 Master 节点
- Data Node：数据节点，该节点和索引应用创建连接、接收索引请求，该节点真正存储数据，ES 集群的性能取决于该节点的个数（每个节点最优配置的情况下），data 节点会占用大量的 CPU、IO 和内存
- Coordinating Node：协调节点，该节点和检索应用创建连接、接受检索请求，但其本身不负责存储数据，可当负责均衡节点，该节点不占用 io、cpu 和内存
- Ingest Node：ingest 节点可以看作是数据前置处理转换的节点，支持 pipeline 管道设置，可以使用 ingest 对数据进行过滤、转换等操作
- machine learning：机器学习节点

Node roles <https://www.elastic.co/guide/en/elasticsearch/reference/8.16/modules-node.html>

- `master`
- `data`
- `data_content`
- `data_hot`
- `data_warm`
- `data_cold`
- `data_frozen`
- `ingest`
- `ml`
- `remote_cluster_client`
- `transform`

## 插件

Elasticsearch 集成插件列表。

- [elasticsearch-analysis-ik](https://github.com/medcl/elasticsearch-analysis-ik)
- [elasticsearch-analysis-pinyin](https://github.com/medcl/elasticsearch-analysis-pinyin)
- repository-s3
- analysis-icu
- analysis-kuromoji
- analysis-phonetic
- Ingest-attachment
- ingest-geoip 
- ingest-user-agent
- mapper-murmur3
- mapper-size

## 参考文档

- <https://www.tizi365.com/archives/590.html>

- <https://www.cnblogs.com/buchizicai/p/17093719.html>

- <https://blog.csdn.net/weixin_40364776/article/details/135856042>

- <https://github.com/gm19900510/docker-es-cluster>

索引自动清理：<https://blog.csdn.net/qq_41631365/article/details/109773675>

<https://docs.shanhe.com/v6.1/bigdata/elk/es_manual/elk_all_cn/>