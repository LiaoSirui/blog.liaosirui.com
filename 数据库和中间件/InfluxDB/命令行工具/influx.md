如果已经安装运行了 InfluxDB，就可以直接使用 `influx` 命令行，执行 `influx` 连接到 InfluxDB 实例上。

输出就像下面这样：

```bash
> influx
Connected to http://localhost:8086 version 1.8.9
InfluxDB shell version: 1.8.9
```

连接外部的 Influx

```bash
influx -host 10.24.110.200 -port 8428 -database beegfs_mon -path-prefix /influx
```

## 常用查询语句

- 查看所有表

```bash
show measurements;
```



### 数据库管理

```bash
CREATE DATABASE "beegfs_mon" WITH DURATION 30d REPLICATION 1 SHARD DURATION 1h
```

