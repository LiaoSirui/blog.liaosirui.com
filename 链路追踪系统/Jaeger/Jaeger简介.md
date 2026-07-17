## Jaeger 简介

Jaeger 是受到 Dapper 和 OpenZipkin 启发的由 Uber Technologies 作为开源发布的分布式跟踪系统

Jaeger 用于监视和诊断基于微服务的分布式系统，包括：

- 分布式上下文传播
- 分布式传输监控
- 根本原因分析
- 服务依赖性分析
- 性能/延迟优化

## Jaeger 组件

### esRollover

`esRollover`(elasticsearch-rollover) 是 Jaeger 提供的一个工具, 用于管理 Elasticsearch 中存储的 trace 数据索引, 通过 Rollover (滚动索引) 机制 来实现索引的生命周期管理。

`esLookback`的作用是: 将超出查询保留期的旧索引从 "读别名" 中移除,从而缩小 Jaeger 查询时的索引范围。

完整的生命周期：

```bash
时间线上一个索引的生命周期:

创建 ──────────> 停止写入 ──────────> 不可查询 ──────────> 物理删除
  │                 │                    │                    │
  init /          rollover            lookback          index-cleaner
  rollover        (切换写别名)         (移除读别名)        (删除索引)
```

## 参考文档

- <https://mp.weixin.qq.com/s/C-K7cZQ9MaRcv6klUg-wnA>

- <https://makeoptim.com/distributed-tracing/jaeger/>