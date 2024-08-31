<https://mysqldump.guru/run-mysqldump-without-locking-the-tables.html>

<https://www.stackhero.io/en/services/MySQL/documentations/Troubleshooting/How-to-solve-MySQL-error-Authentication-plugin-cachingsha2password-cannot-be-loaded>

<https://www.maoyingdong.com/mysql-update-sql-locking/>

<https://blog.csdn.net/yucaifu1989/article/details/79400446>

<https://blog.csdn.net/u013810234/article/details/105978479>



<https://cloud.tencent.com/developer/article/1401617>

<https://zhuanlan.zhihu.com/p/347105199>

<https://www.jianshu.com/p/3c7d6a59c4a3>



<https://blog.csdn.net/miyatang/article/details/78227344>



只导出表结构

```bash
mysqldump \
  -h $HOST \
  -u$USER \
  -p$PASSWORD \
  --single-transaction \
  --skip-lock-tables \
  --no-data \
  --databases <db1> <db2> <..>
```

导出示例

```bash
#!/usr/bin/env bash

set -eo pipefail
set -vx

: "${MYSQL_CLUSTER_HOST:=127.0.0.1}"
: "${MYSQL_CLUSTER_PORT:=3306}"
: "${MYSQL_CLUSTER_USER:=root}"
: "${MYSQL_CLUSTER_PASSWORD:=xxx}"

: "${BACKUP_ROOT_DIR:=/backup/mysql_cluster}"

BACKUP_DIR="${BACKUP_ROOT_DIR}/mysql_cluster_$(date +"%Y%m%d_%H%M%S")"
[[ -d ${BACKUP_DIR} ]] || mkdir -p "${BACKUP_DIR}"

# mysqldump \
#     -u"$MYSQL_CLUSTER_USER" \
#     -p"$MYSQL_CLUSTER_PASSWORD" \
#     -h "$MYSQL_CLUSTER_HOST" \
#     -P "$MYSQL_CLUSTER_PORT" \
#     --single-transaction \
#     --skip-lock-tables \
#     --all-databases > "${BACKUP_DIR}/all_database.sql"

databases=$(\
    mysql \
    -u"$MYSQL_CLUSTER_USER" \
    -p"$MYSQL_CLUSTER_PASSWORD" \
    -h "$MYSQL_CLUSTER_HOST" \
    -P "$MYSQL_CLUSTER_PORT" \
    -e "SHOW DATABASES\G" | grep 'Database:' | awk -F 'Database: ' '{print $2}' \
)
for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
        echo "Dumping database: $db"
        mysqldump \
            -u"$MYSQL_CLUSTER_USER" \
            -p"$MYSQL_CLUSTER_PASSWORD" \
            -h "$MYSQL_CLUSTER_HOST" \
            -P "$MYSQL_CLUSTER_PORT" \
            --single-transaction \
            --skip-lock-tables \
            --databases "$db" > "${BACKUP_DIR}/$db.sql"
    fi
done

```

