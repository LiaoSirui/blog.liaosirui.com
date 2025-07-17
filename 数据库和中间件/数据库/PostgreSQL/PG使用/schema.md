PostgreSQL 的 schema 可看作是一個資料庫的命名空間(namespace)，各個命名空間包含所屬的資料表

在 psql 使用 `\dn *`即可列出所有的 schema 及擁有者

```bash
postgres=> \dn *
      List of schemas
        Name        | Owner
--------------------+-------
 information_schema | user
 pg_catalog         | user
 pg_toast           | user
 public             | user
(4 rows)
```

或者

```sql
SELECT schema_name, schema_owner FROM information_schema.schemata;
```

切换 schema

```sql
set search_path to test_schema;

set search_path to public;

SELECT * FROM information_schema.schemata;
```
