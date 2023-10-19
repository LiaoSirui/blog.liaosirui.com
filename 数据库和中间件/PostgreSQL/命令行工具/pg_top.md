## 编译安装

pg_top 是 PostgreSQL 的’top’。它源自 Unix Top。与 top 类似，pg_top 允许您监控 PostgreSQL 进程：

- 查看进程当前正在运行的 SQL 语句
- 查看当前正在运行的 SELECT 语句的查询计划
- 查看进程持有的锁
- 查看每个进程的 I/O 统计信息
- 查看下游节点的复制统计信息

GitLab地址：<https://gitlab.com/pg_top/pg_top>

编译：

```bash
tar -xvJf pg_top-4.0.0.tar.xz -C .
cd pg_top-4.0.0
cmake -DCMAKE_INSTALL_PREFIX=/opt/pgsql14.1/ CMakeLists.txt
```

安装：

```bash
make install
```

## pg_top 使用

通过 pg_top 可以监控主机的负载情况。包括 CPU、内存、SWAP 交换分区。以及 PG 进程信息。
监控时，我们可以关注主机的负载情况，也可以看进程的一些信息（XTIME/QTIME/LOCKS等信息）
这是一个动态的展示过程

load avg: 0.00, 0.01, 0.05;

### 进程数

10 processes: 6 other background task(s), 2 idle, 2 active

进程数量：10 ，后台进程：6 ，idle进程：2 ，活动进程：2

### 系统 CPU 情况

CPU states: 0.0% user, 0.0% nice, 0.0% system, 100% idle, 0.0% iowait

### 系统内存情况

Memory: 2933M used, 7047M free, 0K shared, 3664K buffers, 1572M cached

### SWAP 情况

Swap: 0K used, 2044M free, 0K cached, 0K in, 0K out

### PG进程信息

| 列名     | 信息            |
| -------- | --------------- |
| PID      | 进程的 pid      |
| USERNAME | 用户名          |
| SIZE     | 进程使用内存    |
| RES      | 常驻内存大小    |
| STATE    | 状态            |
| XTIME    | 事务时间        |
| QTIME    | query 执行时间  |
| `%CPU`   | 占用 CPU 百分比 |
| LOCKS    | 持有锁数量      |
| COMMAND  | 操作命令        |

## 远程监控

监控 remote 主机的信息时，需要对 remote 主机上安装 pg_proctab 插件，只有安装插件才能在 remote 主机上进行 pg_top 命令的使用

## 参考资料

- <https://www.modb.pro/db/251500>
