## OPA 简介

Open Policy Agent (OPA)  为 Kubernetes 提供 Policy 平台，从而让 Kubernetes 实现更细粒度的 Authorization

OpenPolicyAgent Gatekeeper

- 文档：<https://www.openpolicyagent.org/docs/kubernetes>

- Github 仓库：<https://github.com/open-policy-agent/gatekeeper>

安装

```bash
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper/gatekeeper --name-template=gatekeeper --namespace gatekeeper-system --create-namespace
```

## Rego 语法

Rego 受到 Datalog 的启发，Datalog 是一种众所周知的数十年的查询语言。Rego 扩展了 Datalog 以支持诸如 JSON 之类的结构化文档模型。

Rego 查询是对存储在 OPA 中的数据的断言。这些查询可用于定义策略，该策略枚举违反系统预期状态的数据实例