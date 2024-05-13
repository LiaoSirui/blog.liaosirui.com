配置上游：<https://github.com/eclipse/openvsx/wiki/Deploying-Open-VSX#upstream-registry>

```yaml
services:

  postgres:
    image: docker.io/library/postgres:14.11
    environment:
      - POSTGRES_USER=openvsx
      - POSTGRES_PASSWORD=openvsx
      - POSTGRES_DB=openvsx
    logging:
      options:
        max-size: 10m
        max-file: "3"
    volumes:
      # - './pg-data:/var/lib/postgresql/data'
      - '/data/nvme/open-vsx/pg-data:/var/lib/postgresql/data'
    shm_size: '256m'
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 10s
      timeout: 5s
      retries: 40

  elasticsearch:
    image: docker.io/library/elasticsearch:8.7.1
    environment:
      - xpack.security.enabled=false
      - xpack.ml.enabled=false
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - cluster.routing.allocation.disk.threshold_enabled=false
    healthcheck:
      test: curl -s http://elasticsearch01:9200 >/dev/null || exit 1
      interval: 10s
      timeout: 5s
      retries: 50
      start_period: 5s

  server:
    image: ghcr.io/eclipse/openvsx-server:v0.15.1
    volumes:
      - ./server:/app
    ports:
      - 8080:8080
    depends_on:
      - postgres
      - elasticsearch
    volumes:
      - ./application.yml:/home/openvsx/server/config/application.yml
    healthcheck:
      test: "curl --fail --silent localhost:8081/actuator/health | grep UP || exit 1"
      interval: 10s
      timeout: 5s
      retries: 50
      start_period: 5s
    
  webui:
    image: ghcr.io/eclipse/openvsx-webui:v0.15.1
    ports:
      - 3000:3000
    depends_on:
      - server
```

配置文件

```yaml
spring:
  datasource:
    url: jdbc:postgresql://postgres:5432/openvsx
    username: openvsx
    password: openvsx
    # refer: https://stackoverflow.com/questions/60310858/possibly-consider-using-a-shorter-maxlifetime-value-hikari-connection-pool-spr
    # 10 minutes wait time
    hikari:
      maxLifeTime: 600000
  jpa:
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
    hibernate:
      ddl-auto: none
  session:
    store-type: jdbc
    jdbc:
      initialize-schema: never
ovsx:
  webui:
    url: https://openvsx.alpha-quant.com.cn
  elasticsearch:
    enabled: true
    host: elasticsearch:9200
  databasesearch:
    enabled: false
  upstream:
    url: https://marketplace.visualstudio.com
  vscode:
    upstream:
      gallery-url: https://marketplace.visualstudio.com/_apis/public/gallery
```

使用者：<https://github.com/eclipse/openvsx/wiki/Using-Open-VSX-in-VS-Code>
