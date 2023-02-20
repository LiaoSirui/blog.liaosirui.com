
## 获取容器信息

查看容器进程在宿主机的 PID

```bash
docker inspect -f '{{.State.Pid}}' 容器
```

查看所有容器的宿主机 PID

```bash
docker ps -aq  | xargs -i docker inspect -f  '{{.State.Pid}} {{ .Name }} ' {}
```

## nsenter 调试工具

安装 nsenter

```bash
yum install -y util-linux
```

调试容器的 network namespace

```bash
nsenter -n -t 30837 /bin/bash
```
