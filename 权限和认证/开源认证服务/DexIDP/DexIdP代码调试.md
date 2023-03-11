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



