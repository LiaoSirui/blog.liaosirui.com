使用 Postgres 作为 Grafana 后端，并迁移数据

停止 Grafana，备份 grafana.db 文件

配置 PG 后端

```yaml
      - env:
        - name: GF_DATABASE_TYPE
          value: postgres
        - name: GF_DATABASE_HOST
          value: pg.postgres-system.svc.cluster.local:5432
        - name: GF_DATABASE_NAME
          value: grafana
        - name: GF_DATABASE_USER
          value: postgres
        - name: GF_DATABASE_PASSWORD
          value: u14b3MrK
        - name: GF_DATABASE_SSL_MODE
          value: disable

```

停止 Grafana， 导出 pg 中的 grafana 库的 schema（表结构）

```bash
pg_dump --schema-only-U postgres grafana > schema.sql
```

删除 grafana 库，重新创建 grafana 库，导入表结构

导入表结构

```bash
psql -d grafana -f schema.sql
```

pgloader 导入数据

```bash
load database
    from sqlite:///var/db/grafana.db
    into postgresql://postgres:xxx@pg.postgres-system.svc:5432/grafana
    with data only, reset sequences
    set work_mem to '1024MB', maintenance_work_mem to '2048MB';
```

开始导入

```bash
pgloader db.load
```

- <https://pgloader.io/>

- <https://cloud.tencent.com/developer/ask/sof/53438>