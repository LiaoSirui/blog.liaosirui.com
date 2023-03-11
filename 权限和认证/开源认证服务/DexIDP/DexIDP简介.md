## DexIDP 简介

Dex 是一种身份服务，它使用 OpenID Connect 来驱动其他应用程序的身份验证

官方：

- 官方文档：<https://dexidp.io/docs/>
- GitHub 仓库：<https://github.com/dexidp/dex>

### Connector

Dex 通过 `Connector` 充当其他身份提供者的门户

![dex-flow.png](.assets/DexIDP%E7%AE%80%E4%BB%8B/dex-flow.png)

这允许 Dex 将身份验证推迟到 LDAP 服务器、SAML 提供者或已建立的身份提供者（如 GitHub、Google 和 Active Directory）

可以把 Dex 当作一个轻量级的认证的代理入口（portal），应用 APP 只需要通过与 Dex 交互，由 Dex 负责与后端的上游认证服务器交互，从而屏蔽了后端认证服务器的协议差异

支持的 Connector 列表详见：<https://dexidp.io/docs/connectors/>



<https://aws.amazon.com/cn/blogs/china/using-dex-and-dex-k8s-authenticator-to-authenticate-amazon-eks/>
