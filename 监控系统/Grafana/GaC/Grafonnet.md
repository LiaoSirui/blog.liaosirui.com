## Grafonnet 简介

- 文档：<https://grafana.github.io/grafonnet/API/index.html>

## 创建项目

初始化项目

```bash
jb init
```

添加 grafonnet 到项目中

```bash
jb install github.com/grafana/grafonnet/gen/grafonnet-v11.4.0@main

# jb install github.com/grafana/grafonnet/gen/grafonnet-latest@main
```

使用

```json
// dashboard.jsonnet
local grafonnet = import "github.com/grafana/grafonnet/gen/grafonnet-v11.4.0/main.libsonnet";

grafonnet.dashboard.new('My Dashboard')

```

生成面板

```bash
jsonnet -J vendor dashboard.jsonnet
```

## 完整面板示例

- <https://github.com/grafana/grafonnet/tree/main/examples>
- <https://github.com/grafana/jsonnet-libs>

## 常用文档列表

- Dashboard 基础设置：<https://grafana.github.io/grafonnet/API/dashboard/index.html>
