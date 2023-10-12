## Jaeger 简介

Jaeger 是受到 Dapper 和 OpenZipkin 启发的由 Uber Technologies 作为开源发布的分布式跟踪系统

Jaeger 用于监视和诊断基于微服务的分布式系统，包括：

- 分布式上下文传播
- 分布式传输监控
- 根本原因分析
- 服务依赖性分析
- 性能/延迟优化

## Jaeger 组件

一个基础的 Jaeger 追踪系统包含下面几个部分：

- jaeger-query: 用于客户端查询和检索组件，并包含了一个基础的UI
- jaeger-collector: 接收来自 jaeger-agent 的 trace 数据，并通过处理管道来执行。当前的处理管道包含验证 trace 数据，创建索引，执行数据转换以及将数据存储到对应的后端
- jaeger-agent: 一个网络守护进程，侦听通过 UDP 发送的 spans ，它对其进行批处理并发送给收集器。它被设计为作为基础设施组件部署到所有主机。代理将收集器的路由和发现从客户机抽象出来
- backend-storage: 用于指标数据存储的可插拔式后端存储，支持 Cassandra, Elasticsearch and Kafka
- ingester: 可选组件，用于从 kafka 中消费数据并写入到可直接读取的 Cassandra 或 Elasticsearch 存储中

## 参考文档

- <https://mp.weixin.qq.com/s/C-K7cZQ9MaRcv6klUg-wnA>

- <https://makeoptim.com/distributed-tracing/jaeger/>