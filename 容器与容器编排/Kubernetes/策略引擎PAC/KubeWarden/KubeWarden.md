## KubeWarden

Kubewarden 是一个策略引擎，用于保护和帮助管理集群资源。它允许通过策略验证和更改资源请求，包括上下文感知策略和验证镜像签名。它可以在监视或强制模式下运行策略，并提供集群状态的概述。

Kubewarden 旨在通过启用和简化“策略即代码”来成为通用策略引擎。Kubewarden 策略被编译到 WebAssembly 中：它们体积小（400KB~2MB），沙箱式，安全且便携。它旨在通过迎合组织中的每个人来实现通用性：

- 策略用户：使用 Kubernetes 自定义资源管理和声明策略，重新使用 Rego（OPA 和 Gatekeeper）中编写的现有策略。在 CI/CD 中测试群集外部的策略。
- 策略开发人员：使用你喜欢的 Wasm 编译语言（Rego、Go、Rust、C#、Swift、Typescript 等）编写策略。重新使用你已经熟悉的工具、库和工作流的生态系统。
- 策略分发器：策略是 OCI 工件，通过 OCI 仓库为它们提供服务，并在你的基础设施中使用行业标准，如 Software-Bill-Of-Materials 和工件签名。
- 集群操作员：Kubewarden 是模块化的（OCI 注册表、PolicyServers、Audit  Scanner、Controller）。配置你的部署以满足你的需求，隔离不同的租户。使用审核扫描程序和策略报告在集群中获取过去、当前和可能的违规行为的概述。
- Kubewarden Integrator：将其用作编写新的 Kubewarden 模块和自定义策略的平台。

相关资料

- 文档：<https://docs.kubewarden.io/quick-start>
- GitHub：<https://github.com/kubewarden/>
- <https://github.com/topics/kubewarden-policy>
- Policy OCI 列表：<https://github.com/orgs/kubewarden/packages>

## 安装

```bash
# 添加 Kubewarden 的 Helm 仓库
helm repo add kubewarden https://charts.kubewarden.io

# 更新 Helm 仓库以获取最新图表
helm repo update

# 使用 Helm 安装 Kubewarden 控制器
helm install kubewarden-controller kubewarden/kubewarden-controller
```

使用示例

```yaml
apiVersion: policies.kubewarden.io/v1
kind: ClusterAdmissionPolicy
metadata:
  name: privileged-pods
spec:
  module: registry://ghcr.io/kubewarden/policies/pod-privileged:v0.2.2
  rules:
    - apiGroups: [""]
      apiVersions: ["v1"]
      resources: ["pods"]
      operations:
        - CREATE
        - UPDATE
  mutating: false

```

## 编写策略

- Go：<https://docs.kubewarden.io/tutorials/writing-policies/go/intro-go>
