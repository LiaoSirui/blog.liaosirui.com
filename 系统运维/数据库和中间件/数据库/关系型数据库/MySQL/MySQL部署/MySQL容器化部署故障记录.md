使用容器会受 LimitNOFILE 影响

报错如下：

```bash
[ERROR] [Entrypoint]: mysqld failed while attempting to check config
```

<https://github.com/docker-library/mysql/issues/873>

```
LimitNOFILE=1048576
```

