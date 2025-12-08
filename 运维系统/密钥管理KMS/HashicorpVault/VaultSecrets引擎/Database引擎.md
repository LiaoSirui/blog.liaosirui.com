## Database 引擎

<https://developer.hashicorp.com/vault/docs/secrets/databases>

数据库机密引擎根据配置的角色动态生成数据库凭据。它通过插件接口与许多不同的数据库协同工作。有许多内置的数据库类型，以及一个用于运行自定义数据库类型以实现可扩展性的公开框架。这意味着需要访问数据库的服务不再需要使用硬编码的凭据：它们可以从 Vault 请求凭据，并使用 Vault 的租约机制来更轻松地轮换密钥。这些被称为 “动态角色” 或 “动态机密”。

由于每个服务都使用与众不同的凭据访问数据库，因此当发现有问题的数据访问时，审计会变得更加容易。可以通过 SQL 用户名跟踪到服务的特定实例。

Vault 使用内建的吊销系统来确保用户的凭据在租约到期后的合理时间内失效。

简单点讲，就是给 vault 里面预置了一个高权限的数据库账号，然后外部系统先访问 vault，vault 会返回一个临时数据库账号密码返回给外部系统，另外在临时账号的 ttl 到期时候 vault 会去数据库销毁临时账号。

常见数据库的文档：

- MySQL：<https://developer.hashicorp.com/vault/docs/secrets/databases/mysql-maria>
- PostgreSQL：<https://developer.hashicorp.com/vault/docs/secrets/databases/postgresql>

- MSSQL：<https://developer.hashicorp.com/vault/tutorials/db-credentials/database-secrets-mssql>

启用 database 引擎

```bash
vault secrets enable database
```

## 静态角色

数据库机密引擎支持“静态角色”的概念，即 Vault 角色与数据库中的用户名的一对一映射。数据库用户的当前密码由 Vault  在可配置的时间段内存储和自动轮换。

这与动态机密不同，动态机密的每次请求凭据都会生成唯一的用户名和密码对。当为角色请求凭据时，Vault  会返回已配置数据库用户的当前密码，允许任何拥有适当 Vault 策略的人访问数据库中的用户帐户。

## MySQL

### MySQL 凭证

启动一个测试的数据库实例

```bash
# 开启 general_log
docker run -itd --name mysql \
  -e MYSQL_ROOT_PASSWORD=dts-vault \
  --ulimit nofile=65536:65536 \
  -p 3306:3306 \
  mysql:5.7.44 \
    --general-log=ON \
    --general-log-file=/tmp/mysql-general.log
```

注册数据库实例到 vault，名称为 my-mysql-database（注意这里用到一个高权限的账号，需要能创建账号、删除账号、调整授权）

```bash
vault write database/config/my-mysql-database \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(172.31.24.199:3306)/" \
    allowed_roles="my-mysql-role" \
    username="root" \
    password="dts-vault"
```

注册一个 role 到 vault，role 名为 my-mysql-role，对应的 MySQL 实例为 my-mysql-database

```bash
vault write database/roles/my-mysql-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"
```

编写策略文件并创建一个低权限的 token，将策略提交到 vault

```bash
vault policy write my-mysql-read-policy - << EOF
path "database/creds/my-mysql-role" {
    capabilities = ["read"]
}
EOF
```

创建一个普通的 token 并关联刚才创建的策略

```bash
vault token create -policy="my-mysql-read-policy"
```

使用低权限的 token 登录 vault，通过读取搭配角色名的 /creds 端点来创建一个新的凭据

```bash
vault read database/creds/my-mysql-role
# 这一步操作，会在数据库里面创建一个账号并授权
```

### 租约

查看全部的 LEASE_ID（列出所有租约）

```bash
vault list sys/leases/lookup/database/creds/my-mysql-role
```

查看最早的一个 LEASE_ID

```bash
LEASE_ID=$(vault list -format=json sys/leases/lookup/database/creds/my-mysql-role | jq -r ".[0]")
echo ${LEASE_ID}
```

续订

```bash
vault lease renew database/creds/my-mysql-role/${LEASE_ID}
```

撤销租约（撤销租约而不等待其到期）

```bash
vault lease revoke database/creds/my-mysql-role/${LEASE_ID}
```

撤销全部租约

```bash
vault lease revoke database/creds/my-mysql-role
```

如果把全部租约都撤销掉，则之前的账号登录就会失败

### TTL

新建一个

```bash
vault write database/roles/my-mysql-role \
    db_name=my-mysql-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="5m" \
    max_ttl="10m"

```

获取账号密码

```bash
vault read database/creds/my-mysql-role
```

持续读取数据

```bash
# pipx install mycli
# pipx ensurepath
while true; do mycli -uv-token-my-mysql-r-EKZiCjUQVPa7S  -p'1ME6FMB-UNVV5fiEJZhV' -e 'select now();select sleep(60)'; done
```

在 10 分钟后，这个账号密码就被回收

```bash
docker exec -it mysql tail -f /tmp/mysql-general.log

# 创建账号时，数据库日志记录类似如下
2025-12-08T06:24:15.315673Z	    2 Query	START TRANSACTION
2025-12-08T06:24:15.315910Z	    2 Prepare	CREATE USER 'v-token-my-mysql-r-EKZiCjUQVPa7S'@'%' IDENTIFIED WITH 'mysql_native_password' AS '<secret>'
2025-12-08T06:24:15.315998Z	    2 Execute	CREATE USER 'v-token-my-mysql-r-EKZiCjUQVPa7S'@'%' IDENTIFIED WITH 'mysql_native_password' AS '<secret>'
2025-12-08T06:24:15.316356Z	    2 Close stmt
2025-12-08T06:24:15.316403Z	    2 Prepare	GRANT SELECT ON *.* TO 'v-token-my-mysql-r-EKZiCjUQVPa7S'@'%'
2025-12-08T06:24:15.316544Z	    2 Execute	GRANT SELECT ON *.* TO 'v-token-my-mysql-r-EKZiCjUQVPa7S'@'%'
2025-12-08T06:24:15.316743Z	    2 Close stmt
2025-12-08T06:24:15.316817Z	    2 Query	COMMIT

# 到期时，可以看到有如下的权限回收的操作
2025-12-08T06:29:15.318102Z	    2 Query	START TRANSACTION
2025-12-08T06:29:15.318291Z	    2 Query	REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'v-token-my-mysql-r-EKZiCjUQVPa7S'@'%'
2025-12-08T06:29:15.318550Z	    2 Query	DROP USER 'v-token-my-mysql-r-EKZiCjUQVPa7S'@'%'
2025-12-08T06:29:15.318779Z	    2 Query	COMMIT
```

### 其他

可选：配置根用户后，建议轮换用户密码，使得 Vault 以外的用户无法使用该账号

实际上就是 vault 连接到 MySQL 去修改上面 vault 连接数据库账号的密码的操作，新密码只有 vault 知道，因此官方文档上强烈推荐在数据库中为 Vault 创建一个专户用户来管理其他数据库用户

```bash
vault write -force database/rotate-root/my-mysql-database
```

