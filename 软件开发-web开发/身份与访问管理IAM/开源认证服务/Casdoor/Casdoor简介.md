## 简介

Casdoor 是一个基于 OAuth 2.0、OIDC、SAML 和 CAS 的，UI-first 的身份和访问管理(IAM)/单点登录(SSO)平台

Casdoor 可为网页UI和应用程序用户的登录请求提供服务

Github 地址：

- 后端项目：
- 前端项目：<https://github.com/casdoor/casdoor>

文档地址：

- <https://casdoor.org/docs/overview>

Casdoor 可为网页UI和应用程序用户的登录请求提供服务

## 工作原理

Casdoor 的授权程序建立在 OAuth2 的基础上：OAuth2 是一个工业级别的开发授权协议，可以使用户授权第三方网站 / 应用访问他们在特定网站上的信息，而不必向第三方网站 / 应用提供密码。

整个过程如下图所示，一共分成六个步骤：向用户发送授权请求、获得授权认证、向授权服务器发送授权认证并验证、获取访问令牌、给资源服务器发送访问令牌、获得受保护的资源。

## 连接到 CasDoor

### 标准 OIDC 客户端

CasDoor 完全实现了OIDC协议。 如果您的应用程序已经运行了另一个 OAuth 2，那么 (OIDC) 身份提供商一般会通过标准的 OIDC 客户端库提供服务，如果您想要迁移到Casdoor， 使用 OIDC discovery会帮助您非常容易地切换到Casdoor。CasDoor's OIDC discovery URL 是

```bash
<your-casdoor-backend-host>/.well-known/openid-configuration
```

### CasDoor SDK

与标准的 OIDC 协议相比，Casdoor 在 SDK 中提供了更多的功能，如用户管理、资源上传等。 通过 Casdoor SDK 连接到 Casdoor 的成本比使用 OIDC 标准客户端库更高，并将提供灵活性最佳和最强大的 API。

CasDoor SDK 可分为两类：前端 SDK 和后端 SDK
