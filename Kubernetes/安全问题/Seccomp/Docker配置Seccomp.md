## 配置安全计算模式

官方文档：<https://docs.docker.com/engine/security/>

Docker  `daemon.json`

```json
{
  "seccomp-profile": "/etc/docker/seccomp/default-no-limit.json"
}
```

默认放开所有限制：

```json
{
    "defaultAction": "SCMP_ACT_ALLOW",
    "syscalls": []
}
```

## 参考资料

docker 配置seccomp <https://www.freebuf.com/articles/system/230587.html>