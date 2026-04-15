## Agent

Prometheus Remote Write 的方式，将启用了 Agent 模式的 Prometheus 实例的数据写入到远程存储中。并借助远程存储来提供一个全局视图。

Agent 模式禁用了 Prometheus 的一些特性，优化了指标抓取和远程写入的能力。

Agent 模式是轻量级的 Prometheus 服务，负责采集并远程写入到远端存储； Pushgateway 是中转站，用于接收临时任务（Job）推送的指标并持久化，供 Prometheus 拉取

## 参考资料

- <https://moelove.info/2021/11/28/%E6%96%B0%E5%8A%9F%E8%83%BDPrometheus-Agent-%E6%A8%A1%E5%BC%8F%E4%B8%8A%E6%89%8B%E4%BD%93%E9%AA%8C/>

- <https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/platform/prometheus-agent.md>

- <https://www.trae.cn/article/706584834>