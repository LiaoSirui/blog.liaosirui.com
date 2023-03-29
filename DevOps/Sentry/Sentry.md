## Sentry 简介

官方：

- 官网：<https://sentry.io/>
- GitHub 仓库：<https://github.com/getsentry/sentry>

## 安装

目前没有官方的 chart，可选用的第三方方案：

- <https://github.com/sentry-kubernetes/charts>
- <https://github.com/helm/charts/blob/master/stable/sentry/values.yaml>（已弃用）

官方推荐的 self hosted 仓库：<https://github.com/getsentry/self-hosted>

添加仓库

```bash
helm repo add sentry https://sentry-kubernetes.github.io/charts
```

查看最新的 chart 版本

```bash
> helm search repo sentry                                        

NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
sentry/sentry                   17.11.0         22.11.0         A Helm chart for Kubernetes                       
sentry/sentry-db                0.9.4           10.0.0          A Helm chart for Kubernetes                       
sentry/sentry-kubernetes        0.3.2           latest          A Helm chart for sentry-kubernetes (https://git...
sentry/clickhouse               3.2.1           19.14           ClickHouse is an open source column-oriented da...
```

下载最新的 chart 版本

```bash
helm pull sentry/sentry --version 17.11.0

# 下载并解压
helm pull sentry/sentry --version 17.11.0 --untar
```



参考 values

（1）创建 admin 用户

```yaml
user: 
  create: "true"
  email: "admin@yourdomain.com"
  password: "AgoodPassword"

```





```yaml
# Admin user to create
user:
  # Indicated to create the admin user or not,
  # Default is true as the initial installation.
  create: true
  email: "<your email>"
  password: "<your password>"

email:
  from_address: "<your from email>"
  host: smtp
  port: 25
  use_tls: false
  user: "<your email username>"
  password: "<your email password>"
  enable_replies: false

ingress:
  enabled: true
  hostname: "<sentry.example.com>"

# Needs to be here between runs.
# See https://github.com/helm/charts/tree/master/stable/postgresql#upgrade for more info
postgresql:
  postgresqlPassword: example-postgresql-password

```





```bash
user:
  create: true
  email: youremail@example.com
  password: admin

ingress:
  enabled: true
  # If you are using traefik ingress controller, switch this to 'traefik'
  regexPathStyle: nginx
  annotations:
  # If you are using nginx ingress controller, please use at least those 2 annotations
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/use-regex: "true"
  
  hostname: sentry.example.com

sentry:
  singleOrganization: false
  worker:
    replicas: 2
mail:
  backend: smtp
  useTls: false
  username: "apikey"
  password: "XXXXX"
  port: 25
  host: "smtp.sendgrid.net"
  from: "sentry@example.com"

service:
  name: sentry
  type: ClusterIP
  externalPort: 9000
  annotations: {}
slack: 
  clientId: "client-it"
  clientSecret: "cleint-secret"
  signingSecret: "signing-secret"
# Reference -> https://develop.sentry.dev/integrations/slack/

postgresql:
  enabled: false
## This value is only used when postgresql.enabled is set to false
##
externalPostgresql:
  host: database-host
  port: 5432
  username: postgres
  password: ""
  database: sentry
```

安装：

```bash
helm upgrade --install sentry  \
    --namespace sentry \
    --create-namespace \
    -f ./values.yaml \
    sentry/sentry --version 17.11.0
```

