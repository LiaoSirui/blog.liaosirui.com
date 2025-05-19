## Authentik

Authentik 是一个开源的身份验证和授权框架，用于保护和授权对应用程序的访问

Authentik 的主要特点包括：

- 身份验证：Authentik 支持多种身份验证机制，包括用户名 / 密码、JWT（JSON Web Tokens）、OAuth 2.0 等，可以满足不同场景下的需求。
- 授权：Authentik 提供基于策略的授权功能，可以定义各种访问规则和限制，以确保只有具有足够权限的用户才能访问应用程序。
- 多租户支持：Authentik 可以支持多个租户（Tenants），这意味着多个客户可以在同一个部署中使用该框架，并且每个客户可以独立管理其用户和权限。
- 可扩展性：Authentik 提供了丰富的插件和扩展机制，可以轻松地与其他身份验证和授权解决方案集成，例如 LDAP、Active Directory 等。
- 安全性和隐私保护：Authentik 在处理敏感信息时确保了足够的安全性和隐私保护，例如加密密码、防止跨站点请求伪造（CSRF）攻击等。

链接地址：

- 文档：<https://docs.goauthentik.io/docs/>
- Github 仓库：<https://github.com/goauthentik/authentik>

## 界面

- 管理界面：用于创建和管理用户和组、令牌和凭证、应用程序集成、事件以及定义标准和可自定义登录和身份验证流程的流程的可视化工具。易于阅读的可视化仪表板显示系统状态、最近的登录和身份验证事件以及应用程序使用情况。
- 用户界面：authentik 中的此控制台视图显示您在其中实施了 authentik 的所有应用程序和集成。单击要访问的应用程序以将其打开，或向下钻取以在管理界面中编辑其配置。
- 流：流是登录和身份验证过程的各个阶段发生的步骤。阶段表示登录过程中的单个验证或逻辑步骤。Authentik 允许自定义和精确定义这些流。

## 术语

- Application

应用程序将 Policy 与 Provider 链接在一起，从而允许控制访问。它还包含 UI 名称、图标等信息

- Source

源是可以将用户添加到 authentik 的位置。例如，用于从 Active Directory 导入用户的 LDAP 连接，或用于允许社交登录的 OAuth2 连接

- Provider

Provider 是其他应用程序对 authentik 进行身份验证的一种方式。常见的提供商是 OpenID Connect （OIDC） 和 SAML

LDAP、Proxy 见 Outpost

- Policy

策略是 yes/no。它将计算为 True 或 False，具体取决于 Policy Kind （策略类型） 和设置。

例如，如果用户是指定组的成员，则“组成员身份策略”的计算结果为 True，否则为 False。

这可用于有条件地应用 Stages、授予/拒绝对各种对象的访问权限，以及用于其他自定义逻辑

- Flows & Stages

流是有序的阶段序列。这些流可用于定义用户如何进行身份验证、注册等。

阶段表示单个验证或逻辑步骤。它们用于对用户进行身份验证、注册用户等。可以选择通过策略将这些阶段应用于流。

- Property Mappings

属性映射允许为外部应用程序提供信息，并修改来自源的信息在 authentik 中的存储方式

- Outpost

Outpost 是 authentik 的一个单独组件，无论 authentik 部署如何，都可以部署在任何地方。Outpost 提供的服务未直接实施到 authentik 核心中，例如反向代理

### 架构

authentik 由少量组件组成，其中大多数都是正常运行所需要的

- Server 容器由两个子组件组成，即实际服务器本身和嵌入式前哨。轻量级路由器将传入服务器容器的请求路由到核心服务器或嵌入式前哨。此路由器还处理对任何静态文件（例如 JavaScript 和 CSS 文件）的请求。

  - Core 子组件处理 authentik 的大部分逻辑，例如 API 请求、流执行、任何类型的 SSO 请求等。
  - Embedded outpost 与其他 Outpost 类似，此 Outpost 允许使用代理提供商，而无需部署单独的 Outpost。

  - `/media` 用于存储 icon 等，但不是必需的，如果未挂载，authentik 将允许设置图标的 URL 来代替文件上传

- Background Worker 此容器执行后台任务，例如发送电子邮件、事件通知系统以及可以在前端的 System Tasks 页面上看到的所有内容。
  - `/certs` 用于 authentik 导入外部证书，在大多数情况下，这些证书不应用于 SAML，但如果使用 authentik 而不使用反向代理，则可以将其用于 Let's Encrypt 集成
  - `/templates` 用于自定义电子邮件模板，并且与其他模板一样，完全可选

中间件

- PostgreSQL 数据库 `/var/lib/postgresql/data` 用于存储 PostgreSQL 数据库
- Redis，authentik 使用 Redis 作为消息队列和缓存。Redis 中的数据不需要持久化，重新启动 Redis 将导致所有会话丢失。`/data` 用于存储 Redis 数据
