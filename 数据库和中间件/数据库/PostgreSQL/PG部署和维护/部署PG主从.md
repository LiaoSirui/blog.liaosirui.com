## 部署主节点

容器启动服务

作为主服务器需要修改如下配置

```bash
# 记录足够的信息以支持常见的备库用途，包括流复制和热备
wal_level = replica

# 归档模式
archive_mode = on
archive_command = 'cp -rpf %p /var/lib/postgresql/wal/%f'
archive_timeout = 1800

# max_wal_senders 设置最大 WAL 发送进程数量
max_wal_senders = 10

# wal_keep_size 设置主节点上保留的 WAL 日志的最小大小，单位 MB
wal_keep_size = 128

# 监听的 IP 地址
listen_addresses = '*'

# 增加 connection 数量
max_connections = 2000
```

注意将 wal 的持久化目录授予对应的权限，否则容器中无法写入

修改`pg_hba.conf`文件，配置从节点连接主节点的权限

- `<YOUR_USER>`替换为从节点账号
- `<从节点私网IP/网段>`需替换为从节点的私网IP/网段

```bash
echo "host replication repl 0.0.0.0/0 md5" | sudo tee -a pg_hba.conf
```

创建复制用户

- `<YOUR_USER>`替换为从节点账号
- `<YOUR_PASSWORD>`替换为要设置的密码

```bash
psql -c "CREATE USER <YOUR_USER> REPLICATION LOGIN CONNECTION LIMIT 30 PASSWORD '<YOUR_PASSWORD>';"
```

## 部署从节点

容器启动服务，初始时设置为 sleep 命令，禁止初始化

使用`pg_basebackup`基础备份工具创建主库的基础备份

- `<YOUR_USER>`替换为主库账号
- `<YOUR_PASSWORD>`替换为主库密码
- `<主节点私网IP>`替换为主节点私网IP

```bash
su postgres
export PGPASSWORD=<YOUR_PASSWORD>
pg_basebackup -h <主节点私网IP> -U <YOUR_USER> -P -w -v --wal-method=stream -D /var/lib/postgresql/data
```

配置从库的 `postgresql.conf` 文件

```bash
# hot_standby = on 开启备用服务器的只读模式
hot_standby = on

# 设置 hot_standby_feedback = on 
# 控制备用服务器是否会向主服务器发送关于自己的复制状态和进度的信息
hot_standby_feedback = on
```

设置主库的连接信息。

- `<主节点私网IP>`需替换为主库私网 IP
- `<YOUR_USER>`替换为主库用户名
- `<YOUR_PASSWORD>`需替换为主库密码

```bash
primary_conninfo = 'application_name=pgslave host=<主节点私网IP> port=5432 user=<YOUR_USER> password=<YOUR_PASSWORD> sslmode=disable sslcompression=1'
```

设置从库可以接入主库

带有 `.signal` 扩展名的信号文件用于触发服务器的特定操作模式，`standby.signal` 表示待命模式

```bash
touch /var/lib/postgresql/data/standby.signal
chmod 777 /var/lib/postgresql/data/standby.signal
```

回到主库进行配置如下

```bash
# ANY 1 表示有任意一台备库进行同步之后即可返回，可根据需要修改，目前只有一个备库所以这么写
# 括号里写备库刚刚在 postgresql.auto.conf 配置的 application_name
synchronous_standby_names = 'ANY 1 (pgslave)'

synchronous_commit = on
hot_standby_feedback = true
```

## 验证 PostgreSQL 主从架构

在主节点中进入 PostgreSQL 交互终端，输入以下 SQL 语句，在主库中查看从库状态

```sql
select * from pg_stat_replication;
```

## 参考资料

- <https://magodo.github.io/postgresql-tips/>