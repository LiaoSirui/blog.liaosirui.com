## 安装 Authentik

官方是推荐使用 Docker Compose 进行安装

文档：<https://docs.goauthentik.io/docs/install-config/install/docker-compose>

```bash
wget https://goauthentik.io/docker-compose.yml
```

`.env` 文件会存储 PostgreSQL 数据库的密码，以及 Authentik 的一个私钥

```bash
echo "PG_PASS=$(openssl rand -base64 36 | tr -d '\n')" >> .env
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .env
```

Authentik 会启动一个 Server 和一个 worker ，共两个容器

- Server 一般是处理前端的界面，具体的业务流程；
- worker 一般是作为计划任务的执行者

它们之间呢并不会直接的进行沟通，而是通过连接，同一个 PostgreSQL 的数据库和 Redis 数据库来进行这个间接的信息交流

禁止出站点网络请求

```bash
AUTHENTIK_DISABLE_STARTUP_ANALYTICS=true
AUTHENTIK_DISABLE_UPDATE_CHECK=true
AUTHENTIK_ERROR_REPORTING__ENABLED=false
```

设置自动安装信息

```bash
AUTHENTIK_BOOTSTRAP_EMAIL=
AUTHENTIK_BOOTSTRAP_PASSWORD=
AUTHENTIK_BOOTSTRAP_TOKEN=
```

配置电子邮件功能

这些设置定义了 SMTP 设置，确保电子邮件功能正常工作

```bash
AUTHENTIK_EMAIL__HOST=localhost
AUTHENTIK_EMAIL__PORT=25
AUTHENTIK_EMAIL__USERNAME=
AUTHENTIK_EMAIL__PASSWORD=
AUTHENTIK_EMAIL__USE_TLS=false
AUTHENTIK_EMAIL__USE_SSL=false
AUTHENTIK_EMAIL__TIMEOUT=10
AUTHENTIK_EMAIL__FROM=authentik@localhost
```

启动后进入系统

进入到右上角管理员界面，在左侧栏有个系统 -> 设置，建议

- 头像中的 gravatar 给删掉，只留 initials
- 允许用户去修改自己的昵称，但是不允许修改电子邮箱和用户名