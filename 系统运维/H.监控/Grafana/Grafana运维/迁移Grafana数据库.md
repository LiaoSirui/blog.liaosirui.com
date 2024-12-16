## 迁移数据到 postgresql

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

```
pg_dump --schema-only -U grafana grafana > schema.sql
```

删除 grafana 库，重新创建 grafana 库，导入表结构

导入表结构

```
psql -d grafana -U grafana -f schema.sql
```



## 参考

- <https://github.com/percona/grafana-db-migrator>

- <https://github.com/wbh1/grafana-sqlite-to-postgres>