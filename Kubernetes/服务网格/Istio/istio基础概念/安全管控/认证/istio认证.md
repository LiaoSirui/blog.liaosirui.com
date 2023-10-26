Istio 提供两种类型的认证，一种是服务间认证 Peer Authentication，一种是客户端请求认证 Request Authentication

## Peer Authentication

Peer authentication 用于服务到服务的认证，在零信任网络中，Envoy 给服务之间的通讯加密，只有服务双方才能看到请求内容和响应结果

在 Istio 中，默认情况下，服务之间的通信不会被加密或进行身份验证。比如说， A 服务通过 http 请求 B 服务，流量经过 Envoy A 时，Envoy A 直接将流量发送到 Envoy B 中，流量不会进行加密处理，也就是明文请求

istio 的 Peer Authentication 主要解决以下问题：

- 保护服务到服务的通信
- 提供密钥管理系统，通讯加密需要使用证书，而证书会过期，所以需要一个管理系统自动颁发证书、替换证书等
- 为每个服务提供强大的身份标识，以实现跨群集和云的互操作性

Istio 的 PeerAuthentication 是一种安全策略，用于对服务网格内的工作负载之间的通信进行双向 TLS（mTLS）验证

![image-20230527090410894](.assets/istio认证/image-20230527090410894.png)

通过 PeerAuthentication 在 Envoy 间启用 mTLS，以确保工作负载之间的通信在传输过程中是加密和安全的

PeerAuthentication 可以配置为整个集群或只在命名空间中起作用，但是只能有一个网格范围的 Peer 认证策略，每个命名空间也只能有一个命名空间范围的 Peer 认证策略

###  PeerAuthentication 的定义

下面是一个简单的 PeerAuthentication 示例：

```yaml
apiVersion: security.istio.io/v1beta1  
kind: PeerAuthentication  
metadata:  
  name: my-peer-authentication  
  namespace: my-namespace  
spec:  
  selector:  
    matchLabels:  
      app: my-app  
  mtls:  
    mode: STRICT
```

- `selector`: 标签选择器，用于选择应用 PeerAuthentication 策略的工作负载。例如：

```yaml
selector:  
  matchLabels:  
    app: my-app
```

如果省略选择器，PeerAuthentication 策略将应用于命名空间中的所有工作负载

- mtls: 定义双向 TLS 的模式，有三种模式。
  - `STRICT`: 强制执行 mTLS，要求客户端和服务器使用 TLS 进行通信。这需要客户端和服务器具有有效的证书
  - `PERMISSIVE`: 允许客户端使用 TLS 或纯文本进行通信。这对于逐步迁移到 mTLS 的场景非常有用
  - `DISABLE`: 禁用 mTLS，不要求客户端和服务器使用 TLS 进行通信

只能有一个网格范围的 Peer 认证策略，每个命名空间也只能有一个命名空间范围的 Peer 认证策略。当同一网格或命名空间配置多个网格范围或命名空间范围的 Peer 认证策略时，Istio 会忽略较新的策略。当多个特定于工作负载的 Peer 认证策略匹配时，Istio 将选择最旧的策略

## Request Authentication

Request authentication 用于外部请求的用户认证， Istio 使用 JWT（JSON Web Token) 来验证客户端的请求，并使用自定义认证实现或任何 OpenID Connect 的Request authentication 认证实现来简化的开发人员体验

支持以下认证类型：

- ORY Hydra
- Keycloak
- Auth0
- Firebase Auth
- Google Auth

Istio 的 RequestAuthentication 是一种安全策略，用于验证和授权客户端访问Istio服务网格中的服务

RequestAuthencation 需要搭配一个 AuthorizationPolicy来 使用。RequestAuthentication 和 AuthorizationPolicy 这两个策略用于验证和授权客户端访问服务网格中的服务

RequestAuthentication 负责验证客户端提供的 JWT，而 AuthorizationPolicy 负责基于角色的访问控制（RBAC），允许定义细粒度的权限以限制对特定服务、方法和路径的访问

### RequestAuthencation 的定义

下面是一个完整的 RequestAuthentication 示例：

```yaml
apiVersion: security.istio.io/v1beta1  
kind: RequestAuthentication  
metadata:  
  name: my-request-authentication  
  namespace: my-namespace  
spec:  
  jwtRules:  
  - issuer: "https://accounts.google.com"  
    audiences:  
    - "my-audience-1"  
    - "my-audience-2"  
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"  
    jwtHeaders:  
    - "x-jwt-assertion"  
    - "x-jwt-assertion-original"  
    jwtParams:  
    - "access_token"  
    forward: true
```

在 RequestAuthentication 中，jwtRules 是一个配置项，用于定义如何验证和处理 JWT。

一个典型的 jwtRules 配置可能包括以下几个部分：

- `issuer`: 发行者，表示JWT的发行方，例如：`https://accounts.google.com`。这个字段用于验证JWT的iss（发行者）声明。
- `audiences`: 受众列表，表示接受JWT的一组实体。这个字段用于验证JWT的aud（受众）声明。例如：`["my-audience-1", "my-audience-2"]`。
- `jwksUri`: JSON Web Key Set（JWKS）的URL，用于获取JWT签名公钥。Istio会从这个URL下载公钥，用于验证JWT的签名。例如：`https://www.googleapis.com/oauth2/v3/certs`。
- `jwtHeaders`: 一个字符串数组，表示可以从HTTP请求头中获取JWT的头名称。默认情况下，Istio会从"Authorization"头中获取令牌。例如：`["x-jwt-assertion", "x-jwt-assertion-original"]`。
- `jwtParams`: 一个字符串数组，表示可以从HTTP请求参数中获取JWT的参数名称。例如：`["access_token"]`。
- `forward`: 一个布尔值，表示是否将JWT转发给上游服务。默认值为`false`，表示JWT令牌不会转发给上游服务。如果设置为`true`，则Istio会将令牌添加到请求头中，并转发给上游服务。

通过正确配置 jwtRules，Istio 可以对请求中的 JWT 进行验证，确保客户端访问服务网格中的服务时具有适当的授权。