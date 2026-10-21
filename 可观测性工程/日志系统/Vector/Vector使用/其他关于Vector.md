## Vector API Modules

Vector 中的 API 模块提供了与外部系统交互的能力，支持多种操作和监控。这些 API 使用户能够方便地管理 Vector 实例，获取系统状态信息，并进行数据查询和配置管理

## GraphQL API

Vector GraphQL API 允许用户与运行中的 Vector 实例通过 graphql endpoint 进行交互，它基于 GraphQL 语言提供灵活且高效的数据查询和操作方式

- 获取当前 Vector 配置

```bash
curl -X POST http://127.0.0.1:8686/graphql \
-H "Content-Type: application/json" \
-d '{"query": "query { sources { edges { node { componentId componentType } } } sinks { edges { node { componentId componentType } } } }"}'

{"data":{"sources":{"edges":[{"node":{"componentId":"kubernetes_logs","componentType":"kubernetes_logs"}}]},"sinks":{"edges":[{"node":{"componentId":"stdout","componentType":"console"}}]}}}
```

- 查询 Vector 版本信息

```bash
curl -X POST http://127.0.0.1:8686/graphql \
-H "Content-Type: application/json" \
-d '{"query": "query { meta { versionString hostname } }"}'

{"data":{"meta":{"versionString":"0.42.0 (aarch64-unknown-linux-gnu 3d16e34 2024-10-21 14:10:14.375255220)","hostname":"vector-2p6ts"}}}
```

## Playground API

Vector Playground API 提供了一个用户友好的界面，可以输入一些条件来获取信息，通过访问 http://localhost:8686/playground 来访问

