- nerdctl 使用 http 的 harbor

```bash
nerdctl login harbor.cadp.com --insecure-registry -u admin -p Harbor123456
```

- 拉取镜像

```bash
docker pull harbor.cadp.com/smartgate/gwit:v5 --insecure-registry

# 这个为 ctr 下载镜像命令
ctr -n k8s.io i pull --plain-http   harbor.cadp.com/smartgate/gwit:v5
# --plain-http 表示使用 http 下载
```

- 推送镜像

```bash
docker push harbor.cadp.com/public/elasticsearch:7.13.1 --insecure-registry
```