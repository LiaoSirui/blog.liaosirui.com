## postgres_exporter

使用 Postgres_exporter 可以将 PostgreSQL 的监控指标导出到 Prometheus 中，从而进行可视化展示和告警。Postgres_exporter 监控的指标包括：连接数、CPU 使用率、锁、表空间使用、索引使用、表大小、活跃进程数等

## 指标

### 连接数

连接数是指当前与 PostgreSQL 数据库建立的连接数，这是一个重要的指标，因为连接数过高可能导致性能下降和资源浪费。

以下是一些与连接数有关的指标：

- `pg_stat_activity_count`：当前活跃的连接数。

- `pg_stat_activity_waiting_count`：当前等待中的连接数。

- `pg_stat_activity_idle_count`：当前空闲的连接数。

### CPU 使用率

CPU 使用率指的是 PostgreSQL 实例使用 CPU 的百分比。如果 CPU 使用率过高，可能会导致性能问题。

以下是一些与 CPU 使用率有关的指标：

- `process_cpu_seconds_total`

- `cpu_system_seconds_total`：PostgreSQL 进程在内核态运行的总时间。

- `cpu_user_seconds_total`：PostgreSQL 进程在用户态运行的总时间。

### 锁

由于 PostgreSQL 的锁机制非常复杂，因此锁是一个重要的性能指标。

以下是一些与锁有关的指标：

- `pg_locks_count`：当前所有锁的数量。

- `pg_locks_blocks_total`：所有等待锁的进程数。

### 表空间使用

表空间使用率指的是 PostgreSQL 表空间的使用情况，包括表和索引的大小。

以下是一些与表空间使用有关的指标：

- `pg_table_size_bytes`：每个表的大小。

- `pg_indexes_size_bytes`：每个索引的大小。

- `pg_total_relation_size_bytes`：每个数据库中所有表和索引的总大小。

### 索引使用

索引使用指的是索引在 PostgreSQL 中的使用情况。

以下是一些与索引使用有关的指标：

- `pg_stat_user_indexes_scan_count`：用户索引扫描的次数。

- `pg_stat_user_indexes_tup_read`：用户索引扫描期间读取的元组数。

### 表大小和活跃进程数

表大小和活跃进程数也是重要的指标。表大小指的是某个表或索引的大小，活跃进程数指的是 PostgreSQL 当前的工作进程数量。

以下是一些与表大小和活跃进程数有关的指标：

- `pg_table_size_bytes`：每个表的大小。

- `pg_indexes_size_bytes`：每个索引的大小。

- `pg_stat_database_numbackends`：当前活跃的进程数。