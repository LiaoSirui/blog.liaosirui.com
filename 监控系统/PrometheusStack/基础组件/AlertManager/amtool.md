## 命令行工具 amtool

安装

```bash
go install github.com/prometheus/alertmanager/cmd/amtool@latest
```

配置文件存放在 `/etc/amtool/config.yml`，内容如下

```
# Define the path that `amtool` can find your `alertmanager` instance
alertmanager.url: "http://localhost:9093"

# Override the default author. (unset defaults to your username)
author: me@example.com

# Force amtool to give you an error if you don't include a comment on a silence
comment_required: true

# Set a default output format. (unset defaults to simple)
output: extended

# Set a default receiver
receiver: team-X-pager
```

官方文档：<https://github.com/prometheus/alertmanager?tab=readme-ov-file#amtool>

## 使用

### 停止告警

```bash
amtool silence add \
    --alertmanager.url="http://localhost:9093" \
    --comment="disable pod not ready" \
    --duration="365d" \
    'alertname=KubePodNotReady' \
    'pod=~nameprefix.*'

# 时间可以设置为例如：6h30m
```

