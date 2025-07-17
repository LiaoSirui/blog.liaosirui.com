## 数据库连接池耗尽的原因

（1）连接未正确释放

应用程序在使用完数据库连接后，如果没有正确地关闭或释放连接，会导致连接一直被占用，从而逐渐耗尽连接池中的可用连接。

（2）并发请求过高

在高并发场景下，如果请求创建连接的速度超过了连接池回收和复用连接的速度，可能会导致连接池中的连接被迅速耗尽。

（3）连接池配置不当

连接池的配置参数设置不合理，例如连接池大小过小、连接超时时间过长等，可能无法满足应用程序的实际需求，进而导致连接池耗尽。

（4）慢查询或长时间事务

某些查询语句执行时间过长或者事务长时间未提交/回滚，会使相关的连接被阻塞，长时间占用连接资源，最终导致连接池耗尽。

## PG 最大连接数

PostgreSQL 数据库最大连接数是系统允许的最大连接数，当数据库并发用户超过该连接数后，会导致新连接无法建立或者连接超时。

最大连接数 `max_connections` 默认值为 100。

当前总共正在使用的连接数

```sql
select count(1) from pg_stat_activity;
```

显示系统允许的最大连接数，此数值包含为超级用户预留的连接数

```sql
show max_connections;
```

显示系统保留的用户数 superuser_reserved_connections

此参数为数据库为超级用户预留的连接数，默认值为 3。当数据库的连接数达到（`max_connections - superuser_reserved_connections`）时，只有超级用户才能建立新的数据库连接，普通用户连接时将会返回错误信息“FATAL: sorry, too many clients already.”或者“FATAL: remaining connection slots are reserved for non-replication superuser connections”，登录数据库查询。

```sql
show superuser_reserved_connections;
```

按照用户分组查看

```sql
select usename, count(*) from pg_stat_activity group by usename order by count(*) desc;
```

按照客户端 IP 查看

```sql
SELECT
    datname AS "数据库名",
    usename AS "用户名",
    client_addr AS "客户端IP",
    state AS "状态",
    COUNT(*) AS "连接数"
FROM pg_stat_activity
GROUP BY datname, usename, client_addr, state;
```

清理连接

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE 1 = 1
--     and datname = 'instrument'
-- and usename = 'marketdata_ro'
--   and client_addr = '192.168.16.120'
and state = 'idle'
;

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'instrument'
and usename = 'marketdata_ro'
and client_addr = '11.11.11.49'
and query_start <= '2024-05-17 01:00:00'
;

SET idle_in_transaction_session_timeout = '10min';
SET statement_timeout = '5min';
```

## 最大连接数修改

### 连接数

（1）通过 `postgresql.conf` 文件来修改 postgresql 的最大连接数

查看配置文件路径

```sql
show config_file;
```

修改

```ini
max_connections = 1000
```

修改完要重启 PostgreSQL

（2）直接执行修改

```bash
alter system set max_connections=1000;
```

### 缓冲区调整

PostgreSQL 数据库有一些参数可以用来配置数据库的内存使用和缓存策略。这些参数包括：

- `shared_buffers`：这个参数决定了 PostgreSQL 用于缓存数据和索引的内存大小。一般来说，这个参数应该设置为系统内存的 10% 到 25% 之间，但是不要超过系统内存的 40%。

- `work_mem`：这个参数决定了每个排序或哈希操作可以使用的内存大小。如果这个参数设置得太小，可能会导致排序或哈希操作使用临时文件，从而降低性能。如果设置得太大，可能会导致系统内存不足，从而触发交换或 OOM（内存溢出）。一般来说，这个参数可以根据系统内存的 25% 除以最大连接数来计算。

- `effective_cache_size`：这个参数是一个估计值，用来告诉 PostgreSQL 规划器操作系统可以用于缓存文件的内存大小。这个参数并不分配实际的内存，而是影响查询优化器的成本计算。一般来说，这个参数可以设置为系统内存的 50% 到 75% 之间。

### 内核共享参数调整

`kernel.shmmax` 是一个内核参数，它定义了一个 Linux 进程可以在其虚拟地址空间中分配的单个共享内存段的最大字节数。这个参数会影响到数据库系统（如Oracle）的性能，因为数据库系统会使用共享内存来存储 SGA（共享全局区）。如果 `kernel.shmmax` 设置得太小，可能会导致数据库无法分配足够的共享内存，从而出现错误信息。如果 `kernel.shmmax` 设置得太大，可能会导致系统的内存压力增加，从而影响其他进程的运行。因此，`kernel.shmmax` 应该根据系统的内存大小和数据库的需求来合理设置。

设置 `kernel.shmmax` 内核参数没有一个固定的标准，它取决于系统的内存大小和数据库的需求。一般来说，可以参考以下几个原则：

- 对于 64 位服务器，您可以使用内存的一半作为 kernel.shmmax 的值

- `kernel.shmmax` 应该略大于数据库的 SGA（共享全局区）的大小

- `kernel.shmmax` 不应该超过系统内存的 40%，以免影响其他进程的运行

## 连接数优化

PostgreSQL 的最大连接数合适值

```bash
used_connections / max_connections = 在85%左右
```

最大连接数设置上限是根据机器的配置相关，良好硬件上的 PostgreSQL 一次可以支持几百个连接。如果先设置数千个，考虑使用连接池软件来减少连接开销。

客户应该是通过应用程序访问的数据库，应用程序到数据库的访问连接数，很多都可以从连接池中利用连接。

## pg_bouncer

如果应用需要大量的连接，可以考虑使用 pg_bouncer 等工具来进行连接池管理。

