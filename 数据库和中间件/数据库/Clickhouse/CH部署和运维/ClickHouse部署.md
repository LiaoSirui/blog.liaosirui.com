## 运行单机服务端（docker）

Clickhouse 官方有提供 docker 镜像

```bash
docker.io/clickhouse/clickhouse-server:25.2.1
```

想有更多的控制项，需要先将默认的配置拷贝出来

```bash
docker run -it \
    --rm --entrypoint=/bin/bash \
    -v "${PWD}/ch_config:/work" \
    --privileged=true \
    --user=root \
    docker.io/clickhouse/clickhouse-server:25.2.1 \
    -c '/usr/bin/cp -rpf /etc/clickhouse-server/* /work/'
```

再运行

```yaml
services:
  clickhouse-server:
    container_name: clickhouse-server
    image: docker.io/clickhouse/clickhouse-server:25.2.1
    restart: unless-stopped
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    cap_add:
      - SYS_NICE
      - NET_ADMIN
      - IPC_LOCK
    ports:
      - "18123:8123" # http_port
      - "18443:8443" # https_port
      - "19000:9000" # tcp_port
      - "19440:9440" # tcp_port_secure
      - "19004:9004" # mysql_port
      - "19005:9005" # postgresql_port
      - "19363:9363" # prometheus
    environment:
      - CLICKHOUSE_DB=my_database
      - CLICKHOUSE_USER=username
      - CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1
      - CLICKHOUSE_PASSWORD=changeme
    volumes:
      - ./ch_config:/etc/clickhouse-server
      - ./ch_data:/var/lib/clickhouse
      - ./ch_logs:/var/log/clickhouse-server
    networks:
      - clickhouse-server
networks:
  clickhouse-server:
    ipam:
      driver: default
      config:
        - subnet: 172.28.1.0/24
          ip_range: 172.28.1.0/24
          gateway: 172.28.1.254

```

启动服务后安装客户端工具进行连接

```bash
pipx install clickhouse-cli
```

连接到 HTTP / HTTPS 端口

```bash
clickhouse-cli --host 192.168.16.2 --port 18123 --user username --password
```

## 官方提供的部署建议

<https://clickhouse.com/docs/zh/install#recommendations-for-self-managed-clickhouse>

- ClickHouse 通常在大量核心的低频率下比在少量内核的高频率下更高效
- 所需的 RAM 量通常取决于：（建议在生产环境中禁用操作系统的交换文件）
  - 查询的复杂性
  - 在查询中处理的数据量

- 对于分布式 ClickHouse 部署（集群），建议至少使用 10G 级别的网络连接