开源 Burst Buffer 文件系统（如 BeeOND、GekkoFS）

Alluxio 在核心理念上与 Burst Buffer 非常相似，但它的定位和应用场景更广，通常被称为数据编排平台（Data Orchestration Platform）或分布式虚拟文件系统

| Butst buffer 类型 | 磁盘类型                    | 文件系统 | POSIX 支持性 | 典型超算或机构                    |
| ----------------- | --------------------------- | -------- | ------------ | --------------------------------- |
| cray DATAWARP     | 专用 SSD 集群               | 分布式   | 支持         | NERSC                             |
| Spectral          | 计算节点本地 NVME 盘        | 非分布式 | 不支持       | summit                            |
| GekkoFS           | 计算节点本地 NVME 盘        | 分布式   | 支持         | BSC                               |
| BurstFS           | 计算节点本地 NVME 盘 + DRAM | 分布式   | 支持         | Florida State University、LLNL    |
| Gfarm/BB          | 计算节点本地 NVME 盘        | 分布式   | 支持         | Center for Computational Sciences |

Burst Buffer 主要通过以下两种工作模式来支持和实现缓存功能：

（1）缓存模式（Cache Mode / Transparent Caching）

在这种模式下，Burst Buffer 充当计算节点与底层并行文件系统（PFS，如 Lustre、GPFS）之间的透明缓存层

- 读缓存（Read Cache）： 当计算节点需要读取大量数据（如 AI 训练的数据集、模拟实验的输入文件）时，数据会被预先或在首次读取时缓存到 Burst Buffer 的 NVMe SSD 中，后续重复读取直接命中闪存，大幅减少对底层慢速存储的访问
- 写缓存（Write Cache）： 应用程序产生的临时数据或检查点（Checkpoint）会先以极高的带宽写入 Burst Buffer，随后由后台调度软件（如 Cray DataWarp）异步地将数据刷新（Flush）到后端的持久化并行文件系统中。对用户程序而言，整个缓存和同步过程是完全透明的，无需修改代码

（2）暂存模式（Scratch / Stage Mode）

除了作为传统意义上的透明缓存，它还支持显式的缓存管理：

- 数据预展（Stage-in）： 在作业（Job）启动前，调度器自动将并行文件系统中的数据 “缓存/预加载” 到 Burst Buffer 中
- 数据回写（Stage-out）： 在作业结束时，将有价值的计算结果异步刷回后端，并清空 Burst Buffer 空间

## 参考资料

- <https://blog.csdn.net/qq_31910613/article/details/128281735>