## 部署

镜像：<https://hub.docker.com/r/atlassian/jira-software>

数据库配置：<https://confluence.atlassian.com/adminjiraserver/connecting-jira-applications-to-postgresql-938846851.html>

兼容性列表：<https://confluence.atlassian.com/adminjiraserver/supported-platforms-938846830.html>

示例 compose 文件

```yaml
version: '3'
services:

  jira-postgresql:
    restart: always
    image: harbor.alpha-quant.com.cn:5000/3rd_party/docker.io/library/postgres:13.11
    volumes:
      # - './pg-data:/var/lib/postgresql/data'
      - '/data/nvme/jira/pg-data:/var/lib/postgresql/data'
    environment:
      POSTGRES_USER: jira
      POSTGRES_PASSWORD: yiW3HW
      POSTGRES_DB: jira
      POSTGRES_INITDB_ARGS: '--encoding=UTF-8 --lc-collate=C --lc-ctype=C'
      LC_COLLATE: C
      LC_CTYPE: C
      LANG: C.UTF-8
    shm_size: '256m'
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 10s
      timeout: 5s
      retries: 40

  jira:
    image: 'harbor.alpha-quant.com.cn:5000/3rd_party/docker.io/atlassian/jira-software:9.12.1'
    restart: always
    hostname: 'jira.alpha-quant.com.cn'
    depends_on:
      jira-postgresql:
        condition: service_healthy
    ports:
      - "8080:8080"
    volumes:
      - './jira-data:/var/atlassian/application-data/jira'
    environment:
      TZ: 'Asia/Shanghai'
      JVM_MINIMUM_MEMORY: "1g"
      JVM_MAXIMUM_MEMORY: "12g"

```

示例的数据库配置

```xml
<?xml version="1.0" encoding="UTF-8"?>

<jira-database-config>
    <name>defaultDS</name>
    <delegator-name>default</delegator-name>
    <database-type>postgres72</database-type>
    <schema-name>public</schema-name>
    <jdbc-datasource>
        <url>jdbc:postgresql://jira-postgresql:5432/jira</url>
        <driver-class>org.postgresql.Driver</driver-class>
        <username>jira</username>
        <password>yiW3HW</password>
        <pool-min-size>20</pool-min-size>
        <pool-max-size>20</pool-max-size>
        <pool-max-wait>30000</pool-max-wait>
        <pool-max-idle>20</pool-max-idle>
        <pool-remove-abandoned>true</pool-remove-abandoned>
        <pool-remove-abandoned-timeout>300</pool-remove-abandoned-timeout>

        <validation-query>select version();</validation-query>
        <min-evictable-idle-time-millis>60000</min-evictable-idle-time-millis>
        <time-between-eviction-runs-millis>300000</time-between-eviction-runs-millis>

        <pool-test-on-borrow>false</pool-test-on-borrow>
        <pool-test-while-idle>true</pool-test-while-idle>

    </jdbc-datasource>
</jira-database-config>

```

反向代理：

```bash
ATL_PROXY_NAME: "jira.alpha-quant.com.cn"
ATL_PROXY_PORT: "443"
```

## 常见问题处理

- `Unable to create and acquire lock file for jira.home directory '/var/atlassian/application-data/jira`

解决：删除 jira_home 目录下的 lock 文件（`.jira-home.lock`），是一个隐藏文件，然后重启 jira 服务即可

- `Unable to clean the cache directory: /var/atlassian/application-data/jira/plugins/.osgi-plugins/felix`

解决：先停止jira服务，然后删除 `$JIRA_HOME/plugins/.osgi-plugins/felix/`，然后启动 jira 服务即可

- `There is/are [1] thread(s) in total that are monitored by this Valve and may be stuck.`

解决：等等就好了