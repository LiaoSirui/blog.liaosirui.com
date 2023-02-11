在使用客户端登录 MySQL8.0 时，我们经常会遇到下面这个报错：

```
ERROR 2061 (HY000): Authentication plugin 'caching_sha2_password' reported error: Authentication requires secure connection.
```

将用户认证插件修改成 mysql_native_password 来解决（不推荐）