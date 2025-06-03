## Resilio 简介

Resilio Sync （原 BitTorrent Sync）是由 Resilio 推出的全平台文件同步产品

## Resilio 部署

```yaml
services:
  resilio-sync:
    image: linuxserver/resilio-sync:latest
    container_name: resilio-sync
    environment:
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
    volumes:
      - ./config:/config
      - ./downloads:/downloads
      - ${BORG_REPO}:/sync
    ports:
      - 8888:8888
      - 55555:55555
    restart: always

```
