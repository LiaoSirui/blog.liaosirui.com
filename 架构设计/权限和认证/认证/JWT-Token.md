##  JWT 简介

JSON Web Token (JWT，RFC 7519)，是为了在网络应用环境间传递声明而执行的一种基于 JSON 的开放标准（(RFC 7519)。

- <https://tools.ietf.org/html/rfc7519>

该 token 被设计为紧凑且安全的，特别适用于分布式站点的单点登录（SSO）场景。JWT 的声明一般被用来在身份提供者和服务提供者间传递被认证的用户身份信息，以便于从资源服务器获取资源，也可以增加一些额外的其它业务逻辑所必须的声明信息，该 token 也可直接被用于认证，也可被加密。

JWT 在生成时会被签名，相同的签名 JWT 在收到时会被验证，以确保它在传输过程中没有被修改。

## 认证流程

<img src=".assets/jwt-flow.2035c3b5.png" alt="img" style="zoom: 25%;" />

- 用户使用账号（手机/邮箱/用户名）密码请求服务器
- 服务器验证用户账号是否和数据库匹配
- 服务器通过验证后发送给客户端一个 JWT Token
- 客户端存储 Token，并在每次请求时携带该 Token
- 服务端验证 Token 值，并根据 Token 合法性返回对应资源

有[Auth0](https://auth0.com/)、 [Okta](https://www.okta.com/)、[Ping Identity](https://www.pingidentity.com/en.html)等身份平台帮助完成，也提供应用端和 API 端的 SDK、验证库和令牌管理系统

### 客户端附带 JWT Token 的方式

用户在完成认证后会返回开发者一个 JWT Token，开发者需将此 Token 存储于客户端，然后将此 Token 发送给开发者受限的后端服务器进行验证。

建议使用 **HTTP Header Authorization** 的形式携带 Token，以下以 JavaScript 的 axios 库为例示范如何携带：

```javascript
const axios = require("axios");
axios
  .get({
    url: "https://yourdomain.com/api/v1/your/resources",
    headers: {
      Authorization: "Bearer ID_TOKEN",
    },
  })
  .then((res) => {
    // custom codes
  });

```

Bearer Token  RFC 6750) 用于授权访问资源，任何 Bearer 持有者都可以无差别地用它来访问相关的资源，而无需证明持有加密 key。一个 Bearer 代表授权范围、有效期，以及其他授权事项；一个 Bearer 在存储和传输过程中应当防止泄露，需实现 Transport Layer Security (TLS)；一个 Bearer 有效期不能过长，过期后可用 Refresh Token 申请更新。

- <http://www.rfcreader.com/#rfc6750>

建议开发者遵循规范，在每次请求的 Token 前附带 Bearer。

## JWT 的构成

Jwt 示例：

```
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.Qv42pM3s3GJk8n6JcJPJVJJTd8pTldcA7ac2142xquQ
```

### Header（头部）部分

第一个部分是头部，如下：

```
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9
```

头部是一个 JSON 对象，包含了一个签名算法和一个令牌类型。它是由 base64Url 编码而成。

解码后如下：

```json
{"alg":"RS256","typ":"JWT"}
```

### Payload（负载）部分

第二部分是负载：

```
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0
```

这是一个包含数据声明的 JSON 对象，其中包含有关用户的信息和其他与身份验证相关的信息。

是 JWT 从一个实体传递到另一个实体的信息。它也是 base64Url 编码的。数据声明如下所示：

```json
{"sub":"1234567890","name":"John Doe","admin":true,"iat":1516239022}
```

### 加密/签名部分

最后一部分是加密/签名部分。JWT 被签名之后不能在传输的过程中被修改。一旦一个授权的服务器发行了一个令牌，就使用密匙来签名。

当客户端接收到 ID 的令牌，也通过密匙来验证签名。

签名算法不同，使用的密钥也会有所不同。如果使用的是非对称签名算法，则使用不同的密钥进行签名和验证。在这种情况下，只有授权服务器能够签名令牌。

## 签名和验证

### 如何签名一个 JWT

将使用 RS256 签名算法。RS256 是使用 SHA-256 的 RSA 电子签名

SHA-256 是一种非对称密钥加密算法，它使用一对密钥：一个公钥和一个私钥来加密和解密

在这里，授权服务器将使用私钥，而接收令牌以验证它的应用程序将使用公钥

#### 签名输入

首先让我来看看 JWT 的前两个部分（头部和负载），如下：

```
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0
```

基本上就是一个由 base64url 编码的头部和负载，并且由 `.` 连接。

```
base64UrlEncode(header) + "." + base64UrlEncode(payload)
```

以上就是签名输入

#### 对签名输入做哈希加密

然后使用 SHA-256 哈希算法对签名输入进行加密。哈希将一个值转换为另一个不同的值。哈希函数使用数学算法从现有值生成新值

注意:

- 哈希是不可逆的，一旦将输入哈希之后，就无法再次获取原有的输入
- 如果输入相同，哈希后的结果始终相同
- 不存在两个不同的哈希输入产出相同的结果

```
SHA-256 (
    base64UrlEncode(header) + "." + base64UrlEncode(payload)
)
```

现在就拥有了哈希后的头部和负载部分，可以用此和其他的哈希结果比较，但是不能逆转返回到最初的签名输入

#### 加密签名输入

接下来，给哈希后的签名输入加密。和哈希不同的是，加密是可逆的。授权服务器使用加密私钥给哈希后的签名加密，产生一个结果。

这个最终结果（哈希过、加密过、头部和负载编码后）就是 JWT 的加密/签名部分。

```
RSA (
    SHA-256 (
        base64UrlEncode(header) + "."  + base64UrlEncode(payload)
    ),
    {RSA Private Key}
)
```

这就是 JSON Web 令牌产生的过程。

### 如何验证 JWT

现在知道令牌是如何签名的，可以进一步了解当收到令牌后，如何验证这个 JWT 是没有被篡改的。

假设有一个接受 JWT 的应用，并且需要验证 JWT。这个应用也可以访问授权服务器的公钥。

JWT 的验证是为了达到一个目的：即可以有效地将收到的与期望的进行比较。

#### 解码声明

应用可以对头部和负载解码来获取信息。

请记住，这两个段是用 base64Url 编码，以使它们是 URL 安全的。这并不是密码学维度的安全。

可以使用简单的在线 base64 解码工具来解码。一旦被解码，就可以轻松地读取其中的信息。

例如，可以解码头部，看看 JWT 说它是用什么算法签名的。

解码后的头部如下：

```json
{
  "alg": "RS256",
  "typ": "JWT"
}
```

当读取 JWT 头部的算法后，应该验证它是否和期待的配置匹配，如果不匹配，就马上拒绝这个令牌

#### 哈希加密（再次）

如果令牌中的算法符合的期望（即使用 RS256 算法），需要生成头部和负载的 SHA-256 哈希

请记住，哈希是不可逆的，但相同的输入总是会产生相同的输出。所以将哈希连接在一起的、由 base64Url 编码的头部和负载。现在在应用程序端重新哈希计算签名输入

#### 解密

哈希签名输入也在 JWT 的签名中，但它已由授权服务器使用私钥加密。应用程序可以访问公钥，因此可以解密签名

完成此操作后，就可以访问原始哈希：第一次生成令牌时由授权服务器生成的哈希

#### 对比哈希值

现在可以将解密的哈希与计算的哈希进行比较。如果它们相同，那么验证 JWT 头部和负载段中的数据在授权服务器创建令牌到应用程序收到它的之间没有被修改

#### 验证令牌声明

此外，一旦验证了签名，就可以验证 JSON Web 令牌的数据。也可以验证负载段中的声明，因为它包含有关令牌颁发者、令牌到期时间、令牌的目标受众、令牌绑定到授权请求的信息等

这些声明为应用程序提供了签名验证以外的详细信息

例如，对声明的检查可以揭示技术上有效的令牌实际上是为不同的应用程序或用户准备的、它已经过期、它来自与该应用程序无关的发行者等等

## 参考文档

- https://www.jianshu.com/p/576dbf44b2ae