## CDC

变更数据捕获（Change Data Capture，简称 CDC）

常见的数据库 CDC（Change Data Capture，变更数据捕获）软件包括：

1. DataX：DataX 是阿里云 DataWorks 数据集成 的开源版本，在阿里巴巴集团内被广泛使用的离线数据同步工具 / 平台。DataX 实现了包括 MySQL、Oracle、OceanBase、SqlServer、Postgre、HDFS、Hive、ADS、HBase、TableStore (OTS)、MaxCompute (ODPS)、Hologres、DRDS, databend 等各种异构数据源之间高效的数据同步功能。
2. Debezium：一个 RedHat 开源的 CDC 平台，支持多种数据库，包括 MySQL、PostgreSQL、MongoDB、SQL Server、Oracle 等。它能够实时捕获数据库中的变化，并通过 Apache Kafka 主题将这些变化传递给消费者。
3. Oracle GoldenGate：一款高性能的数据复制和整合软件平台，支持多种数据库系统。它提供了直观的图形界面，便于配置和管理数据复制任务。
4. Apache NiFi：虽然最初不是设计来作为 CDC 工具的，但 NiFi 的处理器可以定制各种各样的数据处理和变更数据捕获任务，具有强大的灵活性和易用性。
5. IBM InfoSphere Data Replication：一种支持数据复制和同步的软件解决方案，不仅是一个 CDC 工具，还能在数据复制的同时进行数据的转换和清洗。
6. Flink CDC：基于 Apache Flink 的扩展，通过集成 Debezium 来捕获数据库的变更数据，并作为流数据处理，适用于大规模、低延迟的数据处理场景。
7. ETLCloud CDC：一款免费且易用的 CDC 工具，支持多种数据库类型，能够实时捕获数据变化，并提供直观易用的管理界面。
8. Maxwell：专注于 MySQL 的 CDC 工具，能够将 MySQL 的数据变化捕获并以 JSON 格式发送到 Kafka、Kinesis 或其他流处理平台。
9. Canal：阿里巴巴开源的 MySQL 和 MariaDB binlog 增量订阅 & 消费组件，支持高效解析 MySQL binlog，提供增量数据的实时订阅服务。

## 参考资料

- <https://blog.csdn.net/ClickHouseDB/article/details/138186444>
