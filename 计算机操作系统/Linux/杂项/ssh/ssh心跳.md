参考 <https://www.mtjo.net/blog/article/30.html>

服务端设置

```
ClientAliveInterval 30
ClientAliveCountMax 6
```

或者客户端

```bash
ssh -o ServerAliveInterval=30 -o ServerAliveCountMax 100 yyy@xxx.xxx.xxx.xxx
```

