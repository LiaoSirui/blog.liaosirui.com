## DexIDP 简介

Dex 是一种身份服务，它使用 OpenID Connect 来驱动其他应用程序的身份验证

官方：

- 官方文档：<https://dexidp.io/docs/>
- GitHub 仓库：<https://github.com/dexidp/dex>

Dex 本质就是一个认证代理，Dex 主要由前端的 Clients 以及后端的 Connectors 组成，Dex 其本身并没有实现复杂的认证功能，而是通过 Connectors 级联上游的认证服务器（Upstream IDP）实现认证，如 LADP、SAML、OpenShift、Github 等

Dex 最强大的功能在于可以级联其他认证系统 IdP

### Connector

Dex 通过 `Connector` 充当其他身份提供者的门户

![dex-flow.png](.assets/DexIDP%E7%AE%80%E4%BB%8B/dex-flow.png)

这允许 Dex 将身份验证推迟到 LDAP 服务器、SAML 提供者或已建立的身份提供者（如 GitHub、Google 和 Active Directory）

可以把 Dex 当作一个轻量级的认证的代理入口（portal），应用 APP 只需要通过与 Dex 交互，由 Dex 负责与后端的上游认证服务器交互，从而屏蔽了后端认证服务器的协议差异

支持的 Connector 列表详见：<https://dexidp.io/docs/connectors/>

目前 Dex 已经实现对接的外部认证系统如下:

- LDAP
- GitHub
- SAML 2.0
- GitLab
- OpenID Connect
- Google
- LinkedIn
- Microsoft
- AuthProxy
- Bitbucket Cloud
- OpenShift
- Atlassian Crowd
- Gitea

## 配置

### 静态用户名和密码校验

用户列表可以在初始化 Configmap 配置中指定，后续也可以通过 Kubernetes CRD 创建，密码需要通过 bcrypt 算法加密存储

通过 Python 的 bcrypt 库可以实现文本的 bcrypt 加密：

```python
#!/usr/bin/python3
import bcrypt
import sys
salt = bcrypt.gensalt(rounds=15)
for pwd in sys.argv[1:]:
    crypt_pwd = bcrypt.hashpw(pwd.encode(), salt).decode()
    print(f"{pwd}: {crypt_pwd}")

```

Dex 配置静态用户列表如下：

```yaml
enablePasswordDB: true
staticPasswords:
- email: "admin@int32bit.me"
  hash: "$2b$15$9QbV9Vky5.MwFHY9ocae0OcX9lVlA7iaLP/VVoYekXodRT815sqzC"
  username: "admin"
  userID: "a7928eec-65e4-4397-b3b5-640cf62b54f2"
```

配置完用户后，接下来配置 clients，client 也可以在初始化 Configmap 配置中指定，后续也可以通过 Kubernetes CRD 创建：

```yaml
staticClients:
- id: kubernetes
  redirectURIs:
  - 'http://localhost:8000'
  name: 'kubernetes'
  secret: "ZXhhbXBsZS1hcHAtc2Vjcm"
```

这里均为自定义参数，其中

- `client_id`为`kubernetes``
- ``client_secret`为`ZXhhbXBsZS1hcHAtc2Vjcm`

- `redirectURIs` 为后续需要向 Dex 发起认证的可信任应用 callback 列表

## apiserver 对接 Dex

Dex 部署完后需要修改 apiserver 配置 OIDC 服务地址

如果使用 kubeadm 部署的 Kubernetes 集群，需要修改 `/etc/kubernetes/manifests/kube-apiserver.yaml` 文件，在kube-apiserver 启动命令行中增加如下参数

```bash
- --oidc-issuer-url=https://192.168.193.172:32000
- --oidc-client-id=kubernetes
- --oidc-ca-file=/etc/kubernetes/ssl/ca.pem
- --oidc-username-claim=email
- --oidc-groups-claim=groups

```

其中

- `--oidc-issuer-url` 为 Dex 的地址，可以是 IP 也可以是域名，如果配置域名需要按照前面的方法配置静态解析
- `--oidc-client-id` 为 Dex 部署时初始化的 client id
- Kubernetes 中有 User 和 Group 的概念，`--oidc-username-claim`以及`--oidc-groups-claim` 两个参数分别指定 ID Token 中字段对应的 User 和 Group
- `--oidc-ca-file` 由于 Dex 使用的自签证书，为了让 Kubernetes 信任这个证书链必须指定 Dex CA 根证书路径

## 生成 kubeconfig 文件

Kubelogin <https://github.com/int128/kubelogin>

## 请求过程



## 参考资料

- OpenID Connect <https://openid.net/specs/openid-connect-core-1_0.html>

- <https://github.com/panva/node-openid-client/blob/main/docs/README.md>

## 其他参考资料

- <https://aws.amazon.com/cn/blogs/china/using-dex-and-dex-k8s-authenticator-to-authenticate-amazon-eks/>

- <https://www.jokerbai.com/archives/k8s-zi-ding-yi-webhook-shi-xian-ren-zheng-guan-li>

- <https://toutiao.io/posts/ylwd8kk/preview>

- <https://tanzu.vmware.com/developer/guides/identity-dex/>
