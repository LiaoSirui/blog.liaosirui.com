## QuestDB 简介

QuestDB 是一款针对时序数据实时处理优化的关系型列存数据库

官方：

- GitHub 仓库地址：<https://github.com/questdb/questdb>
- 官网：<https://questdb.io/>

## 部署 QuestDB

- 9000 - REST API and Web Console
- 9009 - InfluxDB line protocol
- 8812 - Postgres wire protocol
- 9003 - Min health server

```yaml
networks:
  questdb:
    ipam:
      driver: default
      config:
        - subnet: 172.28.8.0/24
          ip_range: 172.28.8.0/24
          gateway: 172.28.8.254
services:
  questdb:
    image: questdb/questdb:8.1.4
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - "./questdb-data:/var/lib/questdb"
    restart: always
    networks:
      - questdb
    ports:
      - 9000:9000
      - 9009:9009
      - 8812:8812
      - 9003:9003
    deploy:
      resources:
        limits:
          cpus: '4'
    cpuset: '0-3'
```



## 参考资料

- <https://zhuanlan.zhihu.com/p/434424288>