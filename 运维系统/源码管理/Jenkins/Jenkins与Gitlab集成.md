## GitLab API Token

Jenkins 通过 GitLab 的 Access Token 来访问

创建 Token 时，有几个关键点需要注意：

- 作用域（Scopes）选择：务必勾选 `api` 权限，这是 Jenkins 与 GitLab API 交互的基础。同时，建议勾选 `read_repository` 和 `write_repository`，以便 Jenkins 能够读取代码、触发构建，甚至在某些流程中回写状态。
- 生命周期管理：为 Token 设置合理的过期日期是一个安全最佳实践。对于生产环境，建议定期轮换 Token。
- 妥善保管：Token 一旦生成，仅在首次显示，务必立即复制保存到 Jenkins 或安全的密码管理工具中。

是生成 Token 的具体路径：

```bash
GitLab → 右上角头像 → Edit profile → User Settings → Access Tokens
```

创建时，Token 名称（如 `jenkins-gitlab-token`）应具有描述性，方便后续管理。权限选择 `api` 和 `read_repository` 是常见组合。

## Jenkins 凭证配置

使用 `GitLab API token` 类型。

进入 Jenkins 的凭证管理页面：

```bash
Jenkins → Credentials → Domains → (global) → Add credentials
```

将复制的 GitLab Token 粘贴到 “API Token” 字段。

为凭证设置一个唯一的 ID（如 `gitlab-api-token`），这将在后续的 Pipeline 脚本或任务配置中被引用。

## 全局连接配置与系统集成

配置好凭证后，需要在 Jenkins 系统层面建立与 GitLab 服务器的连接。这一步确保了所有 Jenkins 任务都可以方便地引用这个统一的配置，避免了在每个任务中重复设置。

进入系统配置页面：

```bash
Jenkins → Manage Jenkins → Configure System
```

找到 GitLab 配置部分，关键配置项包括：

- **Connection name**：一个友好的连接名称，例如 `gitlab-connection`。
- **GitLab host URL**：你的 GitLab 实例地址，格式如 `https://gitlab.alpha-quant.tech`

- **Credentials**：下拉选择刚才创建的 GitLab Token 凭证。

填写完成后，务必点击 “Test Connection” 按钮。

## 任务配置与自动化部署实战