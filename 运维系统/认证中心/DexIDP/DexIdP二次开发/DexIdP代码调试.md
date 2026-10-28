需要 Go 1.19 以后的版本

克隆仓库并构建二进制

```bash
git clone https://github.com/dexidp/dex.git

cd dex/

make build
```

运行一个 dev 环境

```bash
./bin/dex serve examples/config-dev.yaml
```

构建示例客户端

```bash
make examples
```

运行一个示例客户端

```bash
./bin/example-app
```

默认账户 `admin@example.com` / `password`

可以使用 curl 命令来发送 HTTP 请求：

```bash
curl --location --request POST 'http://localhost:3000/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=1' \
--data-urlencode 'client_secret=1' \
--data-urlencode 'redirect_uri=http://localhost:8080/app2.html' \
--data-urlencode 'code=QL10pBYMjVSw5B3Ir3_KdmgVPCLFOMfQHOcclKd2tj1' \
--data-urlencode 'grant_type=authorization_code'
```

获取到 access_token 之后，我们可以使用 access_token 访问 OP 上面的资源，主要用于获取用户信息，即你的应用从你的用户目录中读取一条用户信息

```bash
curl --location --request POST 'http://localhost:3000/me' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'access_token=I6WB2g0Rq9G307pPVTDhN5vKuyC9eWjrGjxsO2j6jm-'

```

## 认证过程

- login请求

（1）请求login接口

```plain
http://127.0.0.1:8080/login?redirect_uri=http://127.0.0.1:8080/callback
```

login 接口传递 redirect_uri 地址，作为回调地址

（2）接下来login接口回去访问

```plain
dex/auth?client_id=test&redirect_uri=http://127.0.0.1:8080callback&response_type=code&scope=openid+email+groups+profile+offline_access&state=login
```

（3）从 dex 返回 `http://127.0.0.1/dex/auth/ldap?req=xxxxxx`，并展示 dex 的登录界面

（4）输入用户名和密码，点击登录之后，IdP 验证用户名密码的合法行，生成 code 返回到 callback 地址

- callback 请求

callback 获取授权的 code

通过 code 获取认证的 token
