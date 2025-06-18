## OnlyOffice

### OnlyOffice 简介

OnlyOffice 是一款强大的在线 office 工具，通过它可以脱离于客户端环境，直接从 Web 端进行文档编写

官网：<https://www.onlyoffice.com/zh/>

### OnlyOffice 部署

```yaml
services:

  onlyoffice-rabbitmq:
    restart: always
    image: docker.io/library/rabbitmq:3.13.2
    healthcheck:
      test: rabbitmq-diagnostics check_port_connectivity
      interval: 30s
      timeout: 30s
      retries: 10

  onlyoffice-postgresql:
    restart: always
    image: docker.io/library/postgres:12.18-bookworm
    environment:
      POSTGRES_DB: onlyoffice
      POSTGRES_USER: onlyoffice
      POSTGRES_PASSWORD: onlyoffice
      POSTGRES_HOST_AUTH_METHOD: trust
    shm_size: '256m'
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 10s
      timeout: 5s
      retries: 40
    volumes:
      # - './pg-data:/var/lib/postgresql/data'
      - '/data/nvme/onlyoffice/pg-data:/var/lib/postgresql/data'

  onlyoffice-documentserver:
    restart: always
    image: docker.io/onlyoffice/documentserver:8.0.1
    depends_on:
      onlyoffice-postgresql:
        condition: service_healthy
      onlyoffice-rabbitmq:
        condition: service_healthy
    environment:
      DB_TYPE: postgres
      DB_HOST: onlyoffice-postgresql
      DB_PORT: 5432
      DB_NAME: onlyoffice
      DB_USER: onlyoffice
      AMQP_URI: amqp://guest:guest@onlyoffice-rabbitmq
      AMQP_TYPE: rabbitmq
      JWT_ENABLEE: true
      JWT_SECRET: Babj9O2Ed5eP
      JWT_HEADER: Authorization
      JWT_IN_BODY: true
    ports:
      - '18080:80'
    stdin_open: true
    stop_grace_period: 60s
    volumes:
      - './onlyoffice/data:/var/www/onlyoffice/Data'
      - './onlyoffice/logs:/var/log/onlyoffice'
      - './onlyoffice/cache:/var/lib/onlyoffice/documentserver/App_Data/cache/files'
      - './onlyoffice/cache:/var/www/onlyoffice/documentserver-example/public/files'
      - './onlyoffice/font:/usr/share/fonts'

```

参考：

- <https://github.com/ONLYOFFICE/Docker-DocumentServer/blob/master/docker-compose.yml>
- OnlyOffice Helm Chart 部署 <https://elma365.com/en//help/install-onlyoffice.html>

### OnlyOffice 集成其他系统

集成到 Jira：<https://api.onlyoffice.com/zh/editors/jira>

集成到 Conflunce：<https://api.onlyoffice.com/zh/editors/confluence>

### OnlyOffice 运维

关闭证书校验

Office内部的nodejs的配置：在容器内 `/etc/onlyoffice/documentserver/default.json` 中大致 159 行左右将 rejectUnauthorized 的值改为 false，然后重启服务即可：

```json
"requestDefaults": {
  "headers": {
    "User-Agent": "Node.js/6.13",
    "Connection": "Keep-Alive"
  },
  "gzip": true,
  "rejectUnauthorized": false
},
```

导入字体

Win10 系统提取中文字体的方法：控制面板——搜字体——查看安装的字体——再在搜索栏输入中文 2个字，这些就是需要的中文字体了。首次加载会比较慢，因为加载中文字体，一般达到 50M 以上。

将当前文件夹 `C:\Users\Administrator\` 下的 `winfont` 文件夹内的字体全部拷贝到容器的文件夹 `/usr/share/fonts/truetype` 中

## 参考文档

- <https://post.smzdm.com/p/avx9w257/>
- <https://blog.csdn.net/m0_68274698/article/details/132069372>
- <https://blog.csdn.net/VincentYoung/article/details/132384047>
- <https://linuxstory.org/onlyoffice-doc-space/>
- <https://www.dhorde.com/news/305.html>
