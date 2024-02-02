## 查看给 MySQL 分配的内存

MySQL 内部主要内存可通过下面语句查出：

```sql
SET @giga_bytes = 1024 * 1024 * 1024;

SELECT (@@key_buffer_size + @@query_cache_size + @@tmp_table_size + @@innodb_buffer_pool_size + @@innodb_additional_mem_pool_size + @@innodb_log_buffer_size + (
		SELECT count(HOST)
		FROM information_schema.processlist
	) * (@@read_buffer_size + @@read_rnd_buffer_size + @@sort_buffer_size + @@join_buffer_size + @@binlog_cache_size + @@thread_stack)) / @giga_bytes AS MAX_MEMORY_GB;
```



https://www.51cto.com/article/675479.html