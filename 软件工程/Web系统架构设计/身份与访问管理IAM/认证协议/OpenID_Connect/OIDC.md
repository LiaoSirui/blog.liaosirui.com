## OIDC 协议简介

OIDC 的全称是 OpenID Connect，是一个基于 OAuth 2.0 的轻量级认证 + 授权协议，是 OAuth 2.0 的超集

![img](.assets/OIDC/up-b40c2387325cbffee55db8a4cb575fea997.png)

它规定了其他应用，例如你开发的应用 A（XX 邮件系统），应用 B（XX 聊天系统），应用 C（XX 文档系统），如何到你的中央数据表中取出用户数据，约定了交互方式、安全规范等，确保了你的用户能够在访问所有应用时，只需登录一遍，而不是反反复复地输入密码，而且遵循这些规范，你的用户认证环节会很安全

## OIDC Provider

- JS：<https://github.com/panva/node-oidc-provider>
- Golang：<https://github.com/dexidp/dex>
- Python：<https://github.com/juanifioren/django-oidc-provider>

## OIDC 授权码模式

![img](./.assets/OIDC/openid.png)

以下是 OIDC 授权码模式的交互模式：

![img](.assets/OIDC/up-41f4544a58675d5582c01afdc69e2f4e5e4.png)



OIDC Provider 对外暴露一些接口：

- 授权接口

每次调用这个接口，就像是对 OIDC Provider 喊话：我要登录

然后 OIDC Provider 会检查当前用户在 OIDC Provider 的登录状态，如果是未登录状态，OIDC Provider 会弹出一个登录框，与终端用户确认身份，登录成功后会将一个临时授权码（一个随机字符串）发到你的应用（业务回调地址）；如果是已登录状态，OIDC Provider 会将浏览器直接重定向到你的应用（业务回调地址），并携带临时授权码（一个随机字符串）

- token 接口

每次调用这个接口，就像是对 OIDC Provider 说：这是我的授权码，给我换一个 access_token

因为安全，简单解释一下：code 的有效期一般只有十分钟，而且一次使用过后作废。OIDC 协议授权码模式中，只有 code 的传输经过了用户的浏览器，一旦泄露，攻击者很难抢在应用服务器拿这个 code 换 token 之前，先去 OP 使用这个 code 换掉 token。而如果 access_token 的传输经过浏览器，一般 access_token 的有效期都是一个小时左右，攻击者可以利用 access_token 获取用户的信息，而应用服务器和 OP 也很难察觉到，更不必说去手动撤退了。如果直接传输用户信息，那安全性就更低了

一句话：避免让攻击者偷走用户信息

- 用户信息接口

每次调用这个接口，就像是对 OIDC Provider 说：这是我的 access_token，给我换一下用户信息

到此用户信息获取完毕
