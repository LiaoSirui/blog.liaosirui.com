JSON Web 令牌 (JWT) 身份验证过滤器检查传入请求是否具有有效的 JSON Web 令牌 (JWT)。 它通过基于 HTTP 过滤器配置验证 JWT 签名、受众和颁发者来检查 JWT 的有效性。

JWT 身份验证过滤器可以配置为立即拒绝具有无效 JWT 的请求，或者通过将 JWT 有效负载传递给其他过滤器来将决定推迟到以后的过滤器。 JWT 身份验证过滤器支持在各种请求条件下检查 JWT，它可以配置为仅在特定路径上检查 JWT，以便您可以将 JWT 身份验证中的一些路径列入白名单，这在路径可公开访问且不公开时很有用 ' 需要任何 JWT 身份验证。 JWT 身份验证过滤器支持从请求的不同位置提取 JWT，并且可以为同一请求组合多个 JWT 要求。

JWT 签名验证所需的 JSON Web 密钥集 (JWKS) 可以在过滤器配置中内联指定，也可以通过 HTTP/HTTPS 从远程服务器获取。

JWT 身份验证过滤器还支持将成功验证的 JWT 的标头和负载写入动态状态，以便以后的过滤器可以使用它来根据 JWT 负载做出自己的决策。



## 官方文档

- HTTP filters -> JWT Authentication <https://www.envoyproxy.io/docs/envoy/v1.24.0/configuration/http/http_filters/jwt_authn_filter#config-http-filters-jwt-authn>

## 使用

Jwt 参考文档

- [JSON Web Token (JWT)](https://tools.ietf.org/html/rfc7519)
- [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect](http://openid.net/connect)

JwtProvider 消息指定如何验证 JSON Web 令牌 (JWT):

- issuer: 发行 JWT 的委托人。 如果指定，它必须匹配 JWT 中的 iss 字段
- allowed audiences: the ones in the token have to be listed here.
- how to fetch public key JWKS to verify the token signature.
- how to extract JWT token in the request.
- how to pass successfully verified token payload.