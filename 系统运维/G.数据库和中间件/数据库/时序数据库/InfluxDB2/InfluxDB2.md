Docker compose 部署

```
networks:

  influxdb:
    ipam:
      driver: default
      config:
        - subnet: 172.28.104.0/24
          ip_range: 172.28.104.0/24
          gateway: 172.28.104.254

services:

  influxdb2:
    image: harbor-prod.liangkui.co/3rd_party/docker.io/library/influxdb:2.7.4-alpine
    ports:
      - 2003:2003
      - 2004:2004/udp
      - 8086:8086
      - 8089:8089/udp
    environment:
      TZ: Asia/Shanghai
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: "admin"
      DOCKER_INFLUXDB_INIT_PASSWORD: EL7BxVJy0rUuqey1xf53
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: TMMwF36K8ZdzT8n8qD8vQ4evBI5PJfQf
      DOCKER_INFLUXDB_INIT_ORG: influxdata 
      DOCKER_INFLUXDB_INIT_BUCKET: default
      DOCKER_INFLUXDB_INIT_RETENTION: 7d
    volumes:
      - ./data:/var/lib/influxdb2
      - ./config:/etc/influxdb2
    networks:
      - influxdb

  grafana:
    image: harbor-prod.liangkui.co/3rd_party/docker.io/grafana/grafana:10.3.3
    ports:
      - 3000:3000
    environment:
      TZ: Asia/Shanghai
      GF_SECURITY_ADMIN_USER: grafana
      GF_SECURITY_ADMIN_PASSWORD: grafana-csdev-241106
    volumes:
      - ./grafana:/var/lib/grafana
    networks:
      - influxdb
```

配置文件

```
```

