只导出表结构

```bash
PGPASSWORD=<密码> pg_dump \
  -h <主机> \
  -U <用户名> \
  --schema-only <databasename>
```

导出数据

```bash
#!/usr/bin/env bash

set -eo pipefail
set -vx

: "${POSTGRESQL_CLUSTER_HOST:=127.0.0.1}"
: "${POSTGRESQL_CLUSTER_PORT:=5432}"
: "${POSTGRESQL_CLUSTER_USER:=postgres}"
: "${POSTGRESQL_CLUSTER_PASSWORD:=xxx}"

: "${BACKUP_ROOT_DIR:=/backup/postgresql_cluster}"

BACKUP_DIR="${BACKUP_ROOT_DIR}/postgresql_cluster_$(date +"%Y%m%d_%H%M%S")"
[[ -d ${BACKUP_DIR} ]] || mkdir -p "${BACKUP_DIR}"

export PGPASSWORD=${POSTGRESQL_CLUSTER_PASSWORD}
databases=$(\
    psql \
    -U"$POSTGRESQL_CLUSTER_USER" \
    -h "$POSTGRESQL_CLUSTER_HOST" \
    -p "$POSTGRESQL_CLUSTER_PORT" \
    -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres');" -t \
)
echo "$databases" | while read -r db_name; do
    echo "Dumping database: $db_name"
    pg_dump \
        -U"$POSTGRESQL_CLUSTER_USER" \
        -d "${db_name}" \
        -h "$POSTGRESQL_CLUSTER_HOST" \
        -p "$POSTGRESQL_CLUSTER_PORT" \
        -F p \
        --inserts \
        -f "${BACKUP_DIR}/${db_name}.sql"
done
```

注意恢复的时候需要：

```bash
# ON_ERROR_STOP=1 避免中间出错
psql -v ON_ERROR_STOP=1 -d ${PG_DB} -U ${PG_USER} -f sql_file
```

其中 pg 16.9 -> 16.10 引入了安全修复，加入了 `\restrict` 指令，尽量不要跨任何版本进行备份和恢复
