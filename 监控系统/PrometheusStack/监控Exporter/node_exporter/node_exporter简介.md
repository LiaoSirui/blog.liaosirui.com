## node-exporter

node-exporter 是 Prometheus 官方提供的 exporter，主要用来采集 Linux 类型节点的相关信息和运行指标，包括主机的 CPU、内存、Load、Filesystem、Network 等

官方：<https://github.com/prometheus/node_exporter>

下载 Node Exporter：<https://github.com/prometheus/node_exporter/releases>

运行：

```bash
./node_exporter \
  --web.listen-address=:9100
```

### 使用 systemd 管理

- `/usr/lib/systemd/system/node_exporter.service`

node_exporter 启动一个http服务，当请求metrics返回的数据比较多的时候，会消耗一定的cpu，通过systemd的CPUQuota限制cpu的使用

内存：node_exporter 对指标收集的时候会消耗一定的内存，通过systemd的MemoryLimit限制内存的使用，内存占用超限是发生OOM

```ini
[Unit]
Description=Node Exporter
Requires=node_exporter.socket

[Service]
User=root
EnvironmentFile=/etc/sysconfig/node_exporter
ExecStart=/usr/sbin/node_exporter --web.systemd-socket $OPTIONS
MemoryLimit=300M
CPUQuota=100%

[Install]
WantedBy=multi-user.target
```

- `/usr/lib/systemd/system/node_exporter.socket`

```ini
[Unit]
Description=Node Exporter

[Socket]
ListenStream=9100

[Install]
WantedBy=sockets.target
```

- `/etc/sysconfig/node_exporter`

```bash
# OPTIONS="--collector.textfile.directory /var/lib/node_exporter/textfile_collector"
OPTIONS="--log.level=error"
```

### Docker 部署

官方不建议通过 Docker 方式部署 node-exporter，因为它需要访问主机系统。 通过 docker 部署的方式，需要把任何非根安装点都绑定到容器中，并通过 `--path.rootfs` 参数指定。

```bash
docker run -d \
--net="host" \
--pid="host" \
-v "/:/host:ro,rslave" \
prom/node-exporter \
--path.rootfs=/host
```

## 参数

由于 systemd 指标较多，可以用 `--collector.systemd.unit-include` 参数配置只收集指定的服务，减少无用数据，该参数支持正则表达式匹配

```bash
--collector.systemd.unit-include="(docker|sshd).service"
```

如果只想启用需要的收集器，其他的全部禁用，可用如下格式配置

```bash
--collector.disable-defaults --collector.<name>
```

其他参数

```bash
--collector.diskstats.ignored-devices=^(ram|loop|fd)\d+$
--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run)($|/) 
```

限制资源

```bash
--runtime.gomaxprocs=1
```

node_exporter 默认通过系统rsyslog的日志级别写入messages日志，可以通过调节日志级别 --log.level=error 来减少磁盘的消耗

## Textfile 收集器

textfile 通过扫描指定目录中的文件，提取所有符合 Prometheus 数据格式的字符串，然后暴露它们给到 Prometheus 进行抓取。

创建指标文件保存目录 `mkdir /opt/prom`

```bash
$ cat <<EOF | tee /opt/prom/metadata.prom 
# HELP alex_test this is a test
# TYPE alex_test gauge
alex_test{server="test",idc="bj"} 1
EOF
```

启用 textfile： `./node_exporter --collector.textfile.directory="/opt/prom"`

## 抓取指标

在 Prometheus 配置关于 node-exporter 节点的 target，即可抓取相关节点指标数据。

```yaml
scrape_configs:
  - job_name: dev-nas
    honor_timestamps: true
    scrape_interval: 15s
    scrape_timeout: 10s
    metrics_path: /metrics
    scheme: http
    basic_auth:
      username: prometheus
      password: <secret>
    follow_redirects: true
    static_configs:
      - targets:
          - 10.244.244.3:9100
```

或者在 k8s 中

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: dev-nas
  namespace: monitoring
spec: {}


```

## 主动 push 指标

```bash
#!/bin/bash

PUSHGATEWAY_SERVER=https://PUSHGATEWAY.EXAMPLE.COM
NODE_NAME=`hostname`

curl -s localhost:9100/metrics | curl -u USERNAME:PASSWORD --data-binary @- $PUSHGATEWAY_SERVER/metrics/job/node-exporter/instance/$NODE_NAME
```

定时执行上述脚本

```bash
# added by ADMIN to push node stats to Prometheus Pushgateway every minute
*/1 * * * * /root/push_node_exporter_metrics.sh &> /dev/null
```

## 常用查询指标

- 内存

| 指标名称                   | 类型  | 含义                           |
| -------------------------- | ----- | ------------------------------ |
| node_memory_MemTotal_bytes | Gauge | 节点总内存大小（单位：字节）   |
| node_memory_MemFree_bytes  | Gauge | 节点空闲内存大小（单位：字节） |
| node_memory_Buffers_bytes  | Gauge | 节点缓存大小（单位：字节）     |
| node_memory_Cached_bytes   | Gauge | 节点页面缓存大小（单位：字节） |

- 磁盘

| 指标名称                         | 类型    | 含义                                                       |
| -------------------------------- | ------- | ---------------------------------------------------------- |
| node_filesystem_avail_bytes      | Gauge   | 分区用户剩余空间（单位：字节），表示用户拥有的剩余可用空间 |
| node_filesystem_size_bytes       | Gauge   | 分区空间总容量（单位：字节）                               |
| node_filesystem_free_bytes       | Gauge   | 分区物理剩余空间（单位：字节），表示物理层的可用空间       |
| node_disk_read_bytes_total       | Counter | 分区读总字节数（单位：字节）                               |
| node_disk_written_bytes_total    | Counter | 分区写总字节数（单位：字节）                               |
| node_disk_reads_completed_total  | Counter | 分区读总次数                                               |
| node_disk_writes_completed_total | Counter | 分区写总次数                                               |

- 网络

| 指标名称                            | 类型    | 含义                           |
| ----------------------------------- | ------- | ------------------------------ |
| node_network_receive_bytes_total    | Counter | 接收流量总字节数（单位：字节） |
| node_network_transmit_bytes_total   | Counter | 发送流量总字节数（单位：字节） |
| node_network_receive_packets_total  | Counter | 接收流量总包数（单位：包）     |
| node_network_transmit_packets_total | Counter | 发送流量总包数（单位：包）     |
| node_network_receive_drop_total     | Counter | 接收流量总丢包数（单位：包）   |
| node_network_transmit_drop_total    | Counter | 发送流量总丢包数（单位：包）   |

## Grafana Dashboard

- <https://grafana.com/grafana/dashboards/1860-node-exporter-full/>

## 监控接口添加认证

先生成密码

```bash
htpasswd -nBC 12 '' | tr -d ':\n'

# 写入到文件
# /etc/sysconfig/node_exporter_web_config.yaml
basic_auth_users:
  prometheus: $2y$12$y4PaNc0UM0Jzi07jJf6zcuRFyp2GlH6F5rUKcE.xk3Aug2khcqa7m
```

现在让 export 引用这个配置文件

```bash
vim /usr/lib/systemd/system/node_exporter.service

--web.config.file=/etc/sysconfig/node_exporter_web_config.yaml
```


## 参考文档

- <https://mafeifan.com/DevOps/Prometheus/10.%E4%B8%BB%E6%9C%BA%E7%9B%91%E6%8E%A7%E6%8C%87%E6%A0%87.html>
- Node Exporter 常用查询 <https://song-jia-yang.gitbook.io/prometheus/exporter/nodeexporter_query>
- <https://song-jia-yang.gitbook.io/prometheus>
- <https://flashcat.cloud/blog/prometheus-performance-and-cardinality-in-practice/>
- 硬件分析：<https://www.cnblogs.com/wuzhengc/p/16123077.html>
- 内存计数不准的问题，由于 buffer cache 的存在：<https://cloud.tencent.com/developer/article/1637682>
- <https://mafeifan.com/DevOps/Prometheus/10.%E4%B8%BB%E6%9C%BA%E7%9B%91%E6%8E%A7%E6%8C%87%E6%A0%87.html>
