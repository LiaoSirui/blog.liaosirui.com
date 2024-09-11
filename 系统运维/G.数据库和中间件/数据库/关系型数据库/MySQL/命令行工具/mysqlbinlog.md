## 查询 binlog 信息

只查看第一个 binlog 文件的内容

```
mysql> show binlog events;
```

查看指定 binlog 文件的内容

```
mysql> show binlog events in 'mysql-bin.000002';
```

查看当前正在写入的 binlog 文件

```bash
mysql> show master status;
```

获取 binlog 文件列表

```
mysql> show binary logs;
```

## mysqlbinlog

注意:

- 不要查看当前正在写入的 binlog 文件

- 如果 binlog 格式是行模式的，请加 `-vv` 参数

```
# --base64-output=decode-rows 

mysqlbinlog \
	--no-defaults \
	--start-datetime='2023-07-21 13:00:00' \
	--stop-datetime='2023-07-21 15:00:00' \
	/bitnami/mysql/data/mysql-bin.000007

mysqlbinlog \
	--no-defaults \
	--start-position='966159' \
	--stop-position='966159' \
	/bitnami/mysql/data/mysql-bin.000007
```

