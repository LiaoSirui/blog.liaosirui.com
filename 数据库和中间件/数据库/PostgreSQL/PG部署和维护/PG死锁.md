```bash
increase(pg_stat_database_deadlocks{datname!~"template.*|postgres"}[1m]) > 5
```

表示某个业务库在 1 分钟内检测到超过 5 次死锁。

PostgreSQL 会自动检测死锁，并回滚其中一个事务，因此数据库本身不会"卡死"。真正的影响在业务侧：

- 被回滚的事务报错 `ERROR: deadlock detected`（SQLSTATE `40P01`）。
- 应用如果没有重试逻辑，就会直接失败。
- 涉及的事务会先等待 `deadlock_timeout`（默认 1s）才被检测到，导致接口变慢。