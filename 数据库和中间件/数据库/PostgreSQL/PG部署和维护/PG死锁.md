```bash
increase(pg_stat_database_deadlocks{datname!~"template.*|postgres"}[1m]) > 5
```

表示某个业务库在 1 分钟内检测到超过 5 次死锁。

PostgreSQL 会自动检测死锁，并回滚其中一个事务，因此数据库本身不会"卡死"。真正的影响在业务侧：

- 被回滚的事务报错 `ERROR: deadlock detected`（SQLSTATE `40P01`）。
- 应用如果没有重试逻辑，就会直接失败。
- 涉及的事务会先等待 `deadlock_timeout`（默认 1s）才被检测到，导致接口变慢。

进入 PG 进行查询

```sql
SELECT deadlocks FROM pg_stat_database
  WHERE datname = current_database();
```

当两个或多个事务都锁定了资源，并试图获取已被其他事务锁定的资源时，就会发生死锁。在正常情况下，事务 A 锁定资源 A，事务 B 锁定资源 B。在死锁情况下，事务 A 将尝试锁定资源 B。这反过来又使其进入等待模式，因为事务 B 已经锁定了资源 B。这样，两个事务都会锁定彼此的资源。当发生死锁时，PostgreSQL 会取消其中一个涉及的事务，并将其从等待队列中删除，以让其他事务继续其工作。

通常，死锁的出现，意味着应用程序存在设计错误，一般的建议是，修复导致死锁的应用程序逻辑。一个推荐的实践是在 postgresql.conf 中启用 `log_lock_waits` 选项，重新加载配置，并不时地检查日志。当发生死锁时，将会在日志中记录有关冲突查询的额外信息。

```sql
ALTER SYSTEM SET log_lock_waits to 'ON';
ALTER SYSTEM SET deadlock_timeout = '1s';
ALTER SYSTEM SET log_temp_files to '100MB'
SELECT pg_reload_conf();

SHOW log_lock_waits;
SHOW deadlock_timeout;
SHOW log_temp_files;
```

