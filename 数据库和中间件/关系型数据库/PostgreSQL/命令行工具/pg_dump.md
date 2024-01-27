只导出表结构

```bash
PGPASSWORD=<密码> pg_dump \
  -h <主机> \
  -U <用户名> \
  --schema-only <databasename>
```

