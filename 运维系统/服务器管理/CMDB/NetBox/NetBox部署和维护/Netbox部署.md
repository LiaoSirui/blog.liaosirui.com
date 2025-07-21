## compose 部署 netbox

按照官方 compose 部署即可，详见：<https://github.com/netbox-community/netbox-docker/blob/release/docker-compose.yml>

修改后的参考：

```yaml
x-netbox-common: &netbox
  image: harbor.alpha-quant.tech/3rd/docker.io/netboxcommunity/netbox:v4.2.9-3.2.1
  depends_on:
    redis:
      condition: service_healthy
    postgres:
      condition: service_healthy
    redis-cache:
      condition: service_healthy
  env_file: env/netbox.env
  environment:
    TZ: Asia/Shanghai
    DB_PASSWORD: ${PG_PASSWORD}
    REDIS_PASSWORD: ${REDIS_PASSWORD}
    REDIS_CACHE_PASSWORD: ${REDIS_CACHE_PASSWORD}
  user: "unit:root"
  healthcheck:
    test: curl -f http://localhost:8080/login/ || exit 1
    start_period: 90s
    timeout: 3s
    interval: 15s
  networks:
    - netbox
  volumes:
    - ./configuration:/etc/netbox/config:z,ro
    - netbox-media-files:/opt/netbox/netbox/media:rw
    - netbox-reports-files:/opt/netbox/netbox/reports:rw
    - netbox-scripts-files:/opt/netbox/netbox/scripts:rw

services:
  netbox:
    <<: *netbox
    ports: 
      - "38080:8080"
  netbox-worker:
    <<: *netbox
    depends_on:
      netbox:
        condition: service_healthy
    command:
      - /opt/netbox/venv/bin/python
      - /opt/netbox/netbox/manage.py
      - rqworker
    healthcheck:
      test: ps -aux | grep -v grep | grep -q rqworker || exit 1
      start_period: 20s
      timeout: 3s
      interval: 15s
  netbox-housekeeping:
    <<: *netbox
    depends_on:
      netbox:
        condition: service_healthy
    command:
      - /opt/netbox/housekeeping.sh
    healthcheck:
      test: ps -aux | grep -v grep | grep -q housekeeping || exit 1
      start_period: 20s
      timeout: 3s
      interval: 15s

  # postgres
  postgres:
    image: harbor.alpha-quant.tech/3rd/docker.io/library/postgres:17.5
    healthcheck:
      test: pg_isready -q -t 2 -d $$POSTGRES_DB -U $$POSTGRES_USER
      start_period: 20s
      timeout: 30s
      interval: 10s
      retries: 5
    env_file: env/postgres.env
    environment:
      POSTGRES_PASSWORD: ${PG_PASSWORD}
    shm_size: '256m'
    networks:
      - netbox
    volumes:
      - netbox-postgres-data:/var/lib/postgresql/data

  # redis
  redis:
    image: harbor.alpha-quant.tech/3rd/docker.io/valkey/valkey:8.1-alpine
    command:
      - sh
      - -c # this is to evaluate the $REDIS_PASSWORD from the env
      - valkey-server --appendonly yes --requirepass $$REDIS_PASSWORD ## $$ because of docker-compose
    healthcheck: &redis-healthcheck
      test: '[ $$(valkey-cli --pass "$${REDIS_PASSWORD}" ping) = ''PONG'' ]'
      start_period: 5s
      timeout: 3s
      interval: 1s
      retries: 5
    env_file: env/redis.env
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    networks:
      - netbox
    volumes:
      - netbox-redis-data:/data
  redis-cache:
    image: harbor.alpha-quant.tech/3rd/docker.io/valkey/valkey:8.1-alpine
    command:
      - sh
      - -c # this is to evaluate the $REDIS_PASSWORD from the env
      - valkey-server --requirepass $$REDIS_PASSWORD ## $$ because of docker-compose
    healthcheck: *redis-healthcheck
    env_file: env/redis-cache.env
    environment:
      REDIS_PASSWORD: ${REDIS_CACHE_PASSWORD}
    networks:
      - netbox
    volumes:
      - netbox-redis-cache-data:/data

volumes:
  netbox-media-files:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${INST_NETBOX_DATA_DIR}/netbox-media-files
  netbox-postgres-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${INST_NETBOX_POSTGRES_DATA_DIR}
  netbox-redis-cache-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${INST_NETBOX_REDIS_CACHE_DATA_DIR}
  netbox-redis-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${INST_NETBOX_REDIS_DATA_DIR}
  netbox-reports-files:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${INST_NETBOX_DATA_DIR}/netbox-reports-files
  netbox-scripts-files:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${INST_NETBOX_DATA_DIR}/netbox-scripts-files

networks:
  netbox:
    ipam:
      driver: default
      config:
        - subnet: 172.28.211.0/24
          ip_range: 172.28.211.0/24
          gateway: 172.28.211.254

```

手动生成一个加密密钥

```bash
docker run -it --rm \
    harbor.alpha-quant.tech/3rd/docker.io/netboxcommunity/netbox:v4.2.9-3.2.1 \
    /opt/netbox/venv/bin/python3 /opt/netbox/netbox/generate_secret_key.py
```

创建 admin 账号

```bash
docker compose exec -it netbox \
    /opt/netbox/venv/bin/python3 /opt/netbox/netbox/manage.py createsuperuser
```

## 其他问题处理

### csv 导出编码问题

NetBox 在导出 CSV 的时候，会是使用 UTF-8 编码，而不是 UTF-8-SIG 编码。这样会导致导出的文件，在微软的 Excel 打开中会乱码

直接修改 Netbox 虚拟环境的 django_tables2 库的默认编码，这样只要不升级或重装此库就不会失效

```bash
vim /opt/netbox/venv/lib/python3.12/site-packages/django_tables2/export/export.py

# 修改库文件，路径看自己的实际情况
# line 37

    FORMATS = {
        CSV: "text/csv; charset=utf-8-sig",
        JSON: "application/json",
        LATEX: "text/plain",
        ODS: "application/vnd.oasis.opendocument.spreadsheet",
        TSV: "text/tsv; charset=utf-8",
        XLS: "application/vnd.ms-excel",
        XLSX: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        YAML: "text/yaml; charset=utf-8",
    }
```

等效

```bash
sed -i 's#text/csv; charset=utf-8#text/csv; charset=utf-8-sig#g' \
/opt/netbox/venv/lib/python3.12/site-packages/django_tables2/export/export.py
```

### OIDC 登录

增加以下 Python 依赖

```
python-jose[cryptography]
```

增加以下配置

```python
REMOTE_AUTH_BACKEND = "social_core.backends.open_id_connect.OpenIdConnectAuth"
SOCIAL_AUTH_OIDC_OIDC_ENDPOINT = "https://alpha-quant.tech/idp"
SOCIAL_AUTH_OIDC_KEY = "oidc-key"
SOCIAL_AUTH_OIDC_SECRET = "oidc-secret-here"

SOCIAL_AUTH_PROTECTED_USER_FIELDS = [
    "groups"
]
SOCIAL_AUTH_REDIRECT_IS_HTTPS = True

```

