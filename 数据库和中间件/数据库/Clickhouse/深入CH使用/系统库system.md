## 系统表

系统表提供的信息如下:

- 服务器的状态、进程以及环境。
- 服务器的内部进程。

系统表:

- 存储于 `system` 数据库。
- 仅提供数据读取功能。
- 不能被删除或更改，但可以对其进行分离(detach)操作。

## `system.parts`

```bash
`partition`（String）-- 分区名称。
`name`（String）-- 数据部分的名称。
`part_type`（String）-- 数据部分的存储格式。
`active`（UInt8）-- 指示数据部分是否处于活动状态的标志。如果数据部分处于活动状态，则会在表中使用它。否则，将其删除。合并后，不活动的数据部分仍然保留。
`marks`（UInt64）-- 标记数。要获得数据部分中的大约行数，请乘以marks索引粒度（通常为8192）（此提示不适用于自适应粒度）。
`rows`（UInt64）-- 行数。
`bytes_on_disk`（UInt64）-- 所有数据片段的总大小（以字节为单位）。
`data_compressed_bytes`（UInt64）-- 数据片段中压缩数据的总大小。不包括所有辅助文件（例如，带标记的文件）。
`data_uncompressed_bytes`（UInt64）-- 数据片段中未压缩数据的总大小。不包括所有辅助文件（例如，带标记的文件）。
`marks_bytes`（UInt64）-- 带标记的文件的大小。
`modification_time`（DateTime） --包含数据片段的目录被修改的时间。这通常对应于数据零件创建的时间。
`remove_time`（DateTime）-- 数据片段变为非活动状态的时间。
`refcount`（UInt32）-- 使用数据片段的位置数。大于2的值表示在查询或合并中使用了数据部分。
`min_date`（Date）-- 数据片段中日期键的最小值。
`max_date`（Date） -- 数据片段中日期键的最大值。
`min_time`（DateTime）-- 数据片段中日期和时间键的最小值。
`max_time`（DateTime）-- 数据片段中日期和时间键的最大值。
`partition_id`（String）-- 分区的ID。
`min_block_number`（UInt64）-- 合并后组成当前部分的数据片段的最小数量。
`max_block_number`（UInt64）-- 合并后组成当前部分的最大数据片段数。
`level`（UInt32）-- 合并树的深度。零表示当前零件是通过插入而不是通过合并其他零件来创建的。
`data_version`（UInt64）-- 用于确定应将哪些突变应用于数据部分（版本高于的突变data_version）的编号。
`primary_key_bytes_in_memory`（UInt64）-- 主键值使用的内存量（以字节为单位）。
`primary_key_bytes_in_memory_allocated`（UInt64）-- 为主键值保留的内存量（以字节为单位）。
`is_frozen`（UInt8）-- 显示分区数据备份存在的标志。1，备份存在。0，备份不存在。有关更多详细信息，请参见“冻结分区”。
`database`（String）-- 数据库的名称。
`table`（String）-- 表的名称。
`engine`（String）-- 不带参数的表引擎的名称。
`path`（字符串）-- 包含数据零件文件的文件夹的绝对路径。
`disk`（字符串）-- 存储数据部分的磁盘的名称。
`hash_of_all_files`（字符串）-- 压缩文件的sipHash128。
`hash_of_uncompressed_files`（String）-- 未压缩文件（带有标记的文件，索引文件等）的sipHash128。
`uncompressed_hash_of_compressed_files`（String）-- 压缩文件中的数据的sipHash128，就好像它们是未压缩的一样。
`delete_ttl_info_min`（DateTime）-- TTL DELETE规则的日期和时间键的最小值。
`delete_ttl_info_max`（DateTime）-- TTL DELETE规则的日期和时间键的最大值。
`move_ttl_info.expression`（Array（String））-- 表达式数组。每个表达式定义一个TTL MOVE规则。
`move_ttl_info.min`（Array（DateTime））-- 日期和时间值的数组。每个元素都描述了TTL MOVE规则的最小键值。
`move_ttl_info.max`（Array（DateTime））-- 日期和时间值的数组。每个元素都描述了TTL MOVE规则的最大键值。
`bytes`（UInt64）-- bytes_on_disk的别名。
`marks_size`（UInt64）-- marks_bytes的别名。
```

查看数据库总体容量、行数、压缩率

```sql
SELECT
    sum(rows) AS `总行数`,
    formatReadableSize(sum(data_uncompressed_bytes)) AS `原始大小`,
    formatReadableSize(sum(data_compressed_bytes)) AS `压缩大小`,
    round((sum(data_compressed_bytes) / sum(data_uncompressed_bytes)) * 100, 0) AS `压缩率`
FROM system.parts
```

查看数据表容量、行数、压缩率

```sql
SELECT
    table AS `表名`,
    sum(rows) AS `总行数`,
    formatReadableSize(sum(data_uncompressed_bytes)) AS `原始大小`,
    formatReadableSize(sum(data_compressed_bytes)) AS `压缩大小`,
    round((sum(data_compressed_bytes) / sum(data_uncompressed_bytes)) * 100, 0) AS `压缩率`
FROM system.parts
WHERE table IN ('label')
GROUP BY table
```

## 参考资料

- <https://www.cnblogs.com/zhoujinyi/p/14926578.html>

- <https://www.cnblogs.com/johnnyzen/p/18932535>