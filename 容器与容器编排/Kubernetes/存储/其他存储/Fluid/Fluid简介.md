官方仓库地址：<https://github.com/fluid-cloudnative/fluid>

Fluid 通过定义数据集资源，实现如下图所示的功能：

![img](.assets/p233036.png)

- 数据集抽象原生支持：将数据密集型应用所需基础支撑能力功能化，实现数据高效访问并降低多维管理成本。
- 云上数据预热与加速：Fluid 通过使用分布式缓存引擎（Alluxio/JindoFS）为云上应用提供数据预热与加速，同时可以保障缓存数据的可观测性、可迁移性和自动化的水平扩展。
- 数据应用协同编排：在云上调度应用和数据时，同时考虑两者特性与位置，实现协同编排，提升性能。
- 多命名空间管理支持：您可以创建和管理不同 Namespace 的数据集。
- 异构数据源管理：一次性统一访问不同来源的底层数据（对象存储，HDFS 和 Ceph 等存储），适用于混合云场景。
