官方文档：<http://www.postgres.cn/docs/14/app-pgresetwal.html>

解决问题，遇到如下错误：

```plain
PostgreSQL Database directory appears to contain a database; Skipping initialization
2023-02-24 14:00:47.430 CST [1] LOG:  starting PostgreSQL 13.4 (Debian 13.4-1.pgdg100+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit
2023-02-24 14:00:47.431 CST [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2023-02-24 14:00:47.431 CST [1] LOG:  listening on IPv6 address "::", port 5432
2023-02-24 14:00:47.433 CST [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2023-02-24 14:00:47.440 CST [25] LOG:  database system was shut down at 2023-02-24 13:56:42 CST
2023-02-24 14:00:47.440 CST [25] LOG:  invalid primary checkpoint record
2023-02-24 14:00:47.440 CST [25] PANIC:  could not locate a valid checkpoint record
2023-02-24 14:00:47.891 CST [1] LOG:  startup process (PID 25) was terminated by signal 6: Aborted
2023-02-24 14:00:47.891 CST [1] LOG:  aborting startup due to startup process failure
2023-02-24 14:00:47.935 CST [1] LOG:  database system is shut down
```

`pg_resetwal` 会清除预写式日志（WAL）并且有选择地重置存储在 `pg_control` 文件中的一些其他控制信息。如果这些文件已经被损坏，某些时候就需要这个功能。当服务器由于这样的损坏而无法启动时，这只应该被用作最后的手段。

这个工具只能被安装服务器的用户运行，因为它要求对数据目录的读写访问。

出于安全原因，必须在命令行中指定数据目录。`pg_resetwal` 不使用环境变量 `PGDATA`。

```bash
# 执行前先停止数据库
pg_resetwal -f /var/lib/postgresql/data
```
