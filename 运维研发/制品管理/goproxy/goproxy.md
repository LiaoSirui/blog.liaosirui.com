接用 docker hub 上编译好的镜像来运行这个服务：

```text
docker run -d -p80:8081 goproxy/goproxy
```

这样服务就运行在本地的 80 端口服务上

官方文档：<https://goproxy.io/zh/docs/enterprise-goproxyio.html>