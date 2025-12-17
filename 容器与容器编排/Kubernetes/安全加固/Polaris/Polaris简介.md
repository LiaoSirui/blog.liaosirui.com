## Polaris 简介

Polaris 是一款针对 Kubernetes 的开源安全策略引擎，可以帮助广大研究人员通过验证和修复 Kubernetes 的资源配置，来审查 Kubernetes 集群是否遵循了最佳安全实践

当前版本的 Polaris 包含了 30 多种内置的配置策略，并且能够使用 JSON Schema 构建自定义策略。如果你通过命令行或 Webhook 运行 Polaris 的话，Polaris 则可以根据策略标准自动修复问题

Polaris 支持下列三种运行模式：

- 仪表盘模式：根据 “策略即代码” 来验证 Kubernetes 资源安全态势
- 准入控制器模式：自动拒绝或修改不符合组织策略的工作负载

- 命令行工具：将策略作为代码纳入 CI/CD 流程，以测试本地 YAML 文件

## Helm安装

```
helm repo add fairwinds-stable https://charts.fairwinds.com/stable

helm upgrade --install polaris fairwinds-stable/polaris --namespace polaris --create-namespace

kubectl port-forward --namespace polaris svc/polaris-dashboard 8080:80
```

## 其他项目

- Goldilocks - 通过将内存和 CPU 设置与实际使用情况进行比较来调整 Kubernetes Deploy资源的大小
- Polaris - 审核、执行和构建 Kubernetes 资源策略，包括 20 多项内置最佳实践检查
- Pluto - 检测未来版本中已弃用或删除的 Kubernetes 资源
- Nova - 检查你的 Helm 图表是否有可用更新
- rbac-manager - 简化 Kubernetes 集群中 RBAC 的管理

Goldilocks: *https://github.com/FairwindsOps/Goldilocks*

Polaris: *https://github.com/FairwindsOps/Polaris*

Pluto: *https://github.com/FairwindsOps/Pluto

Nova: *https://github.com/FairwindsOps/Nova*

rbac-manager: *https://github.com/FairwindsOps/rbac-manager*
