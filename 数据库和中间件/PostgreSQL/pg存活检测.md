## pg_isready

```bash
pg_isready --dbname=dbname \
    --host=hostname \
    --port=port \
    --username=username
```

如果服务器正常接受连接，则 pg_isready 向 shell 返回 0

如果服务器拒绝连接（例如在启动期间），则返回 1，如果对连接尝试没有响应，则返回 2，如果没有尝试进行连接，则返回 3（例如由于无效参数）。
