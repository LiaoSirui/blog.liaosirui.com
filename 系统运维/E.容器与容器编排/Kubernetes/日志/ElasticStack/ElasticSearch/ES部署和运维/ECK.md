Elastic Cloud on Kubernetes(ECK)是一个 Elasticsearch Operator，但远不止于此。 ECK 使用 Kubernetes Operator 模式构建而成，需要安装在您的 Kubernetes 集群内，其功能绝不仅限于简化 Kubernetes 上 Elasticsearch 和 Kibana 的部署工作这一项任务。ECK 专注于简化所有后期运行工作，通过 ECK 可以轻松实现：

- 管理和监控多个集群。
- 集群版本升级。
- 自动扩缩容。
- 冷热架构。
- 备份和快照。
- 自定义配置和插件。
- 默认提供安全保护。

ECK 不仅能自动完成所有运行和集群管理任务，还专注于简化在 Kubernetes 上使用 Elasticsearch 的完整体验。ECK 的愿景是为 Kubernetes 上的 Elastic 产品和解决方案提供 SaaS 般的体验。在 ECK 上启动的所有 Elasticsearch 集群都默认受到保护，这意味着在最初创建的那一刻便已启用加密并受到默认强密码的保护