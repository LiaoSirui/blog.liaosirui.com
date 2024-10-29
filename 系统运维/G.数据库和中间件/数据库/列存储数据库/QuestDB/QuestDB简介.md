## QuestDB 简介

QuestDB 是一款针对时序数据实时处理优化的关系型列存数据库

官方：

- GitHub 仓库地址：<https://github.com/questdb/questdb>
- 官网：<https://questdb.io/>

## 部署 QuestDB

- 9000 - REST API和 Web 控制台
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

- <https://spytensor.com/index.php/archives/7/>

- <https://docs.dolphindb.cn/zh/tutorials/l2_stk_data_proc_2.html>

- <https://lib.tsinghua.edu.cn/resource/qh/guide/RESSET%20dictionary%20enhanced.xlsx#:~:text=1.%E8%A1%A8%E5%90%8D%E7%BC%A9%E5%86%99%EF%BC%9A%E6%8C%87%E6%95%B0,%E8%B5%84%E4%BA%A7%E6%94%AF%E6%8C%81%E8%AF%81%E5%88%B8%EF%BC%88Abs%EF%BC%89%E3%80%82>