## Let's Encrypt

Cert-manager 是 Kubernetes 上的全能证书管理工具，支持利用 Cert-Manager 基于 ACME(Automatic Certificate Management Environment) 协议与 Let's Encrypt 签发免费证书并为证书自动续期，实现永久免费使用证书

Cert-Manager 用于在 Kubernetes 集群中自动管理和颁发来自各种颁发源的 TLS 证书，它可以从各种受支持的来源颁发证书，包括 Let's Encrypt、HashiCorp Vault 和 Venafi 以及私有 PKI，它将确保证书定期有效和更新，并在到期前的适当时间尝试更新证书。

![image-20230526144158024](.assets/LetsEncrypt%E8%87%AA%E5%8A%A8%E6%9B%B4%E6%96%B0%E8%AF%81%E4%B9%A6/image-20230526144158024.png)

Let's Encrypt 和 ACME 协议的目标是使配置能够自动获取受信任浏览器的证书的 HTTPS 服务器成为可能。这是通过在 Web 服务器上运行证书管理软件（Agent）来达成的。该流程分为两步：

- 首先，管理软件向证书颁发机构证明该服务器拥有域名的控制权。
- 之后，该管理软件就可以申请、续期或吊销该域名的证书。

Let's Encrypt 通过公钥识别服务器管理员。证书管理软件首次与 Let's Encrypt 交互时，会生成新的密钥对，并向 Let's Encrypt CA 证明服务器控制着一个或多个域名。这类似于创建帐户和向该帐户添加域名的传统证书颁发流程。

## 校验方式

Let’s Encrypt 利用 ACME 协议校验域名的归属，校验成功后可以自动颁发免费证书。

免费证书有效期只有90天，需在到期前再校验一次实现续期。使用 cert-manager 可以自动续期，即实现永久使用免费证书。

校验域名归属的两种方式分别是 HTTP-01 和 DNS-01，校验原理详情可参见 Let's Encrypt 的运作方式 <https://letsencrypt.org/zh-cn/how-it-works/>。

### HTTP-01

HTTP-01 的校验原理是给域名指向的 HTTP 服务增加一个临时 location。此方法仅适用于给使用 Ingress 暴露流量的服务颁发证书，并且不支持泛域名证书。

例如，Let’s Encrypt 会发送 HTTP 请求到 `http://<YOUR_DOMAIN>/.well-known/acme-challenge/><TOKEN>`。

- YOUR_DOMAIN 是被校验的域名。
- TOKEN 是 ACME 协议客户端负责放置的文件。

在此处 ACME 客户端即 cert-manager，通过修改或创建 Ingress 规则来增加临时校验路径并指向提供 TOKEN 的服务。

Let’s Encrypt 会对比 TOKEN 是否符合预期，校验成功后就会颁发证书。

### DNS-01

DNS-01 的校验原理是利用 DNS 提供商的 API Key 拿到用户 DNS 控制权限。

此方法不需要使用 Ingress，并且支持泛域名证书。

在 Let’s Encrypt 为 ACME 客户端提供令牌后，ACME 客户端 \(cert-manager\) 将创建从该令牌和帐户密钥派生的 TXT 记录，并将该记录放在 `_acme-challenge.<YOUR_DOMAIN>`。Let’s Encrypt 将向 DNS 系统查询该记录，找到匹配项即可颁发证书。s

### 对比

- HTTP-01 校验方式的优点是配置简单通用，不同 DNS 提供商均可使用相同的配置方法。缺点是需要依赖 Ingress，若仅适用于服务支持 Ingress 暴露流量，不支持泛域名证书。
- DNS-01 校验方式的优点是不依赖 Ingress，并支持泛域名。缺点是不同 DNS 提供商的配置方式不同，DNS 提供商过多而 cert-manager 的 Issuer 不能全部支持。部分可以通过部署实现 cert-manager 的 Webhook 服务来扩展 Issuer 进行支持。例如 DNSPod 和 阿里 DNS，详情请参见 Webhook 列表。

<https://cert-manager.io/docs/configuration/acme/dns01/#webhook>

推荐 DNS-01 方式，其限制较少，功能较全。

## HTTP-01 校验方式签发证书

若使用 HTTP-01 的校验方式，则需要用到 Ingress 来配合校验。

cert-manager 会通过自动修改 Ingress 规则或自动新增 Ingress 来实现对外暴露校验所需的临时 HTTP 路径。

- 为 Issuer 配置 HTTP-01 校验时，如果指定 Ingress 的 name，表示会自动修改指定 Ingress 的规则来暴露校验所需的临时 HTTP 路径
- 如果指定 class，则表示会自动新增 Ingress

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cert-http01
  namespace: cert-manager
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: cert-http01-account-key
    email: "cyril@liaosirui.com"
    solvers:
    - http01:
        ingress:
          # 指定自动创建的 Ingress 的 ingress class
          class: nginx
          # 指定被自动修改的 Ingress 名称
          # name: web

```

- `metadata.name` 是我们创建的签发机构的名称，后面我们创建证书的时候会引用它
- `spec.acme.email` 是你自己的邮箱，证书快过期的时候会有邮件提醒，不过 cert-manager 会利用 acme 协议自动给我们重新颁发证书来续期
- `spec.acme.server` 是 acme 协议的服务端，我们这里用 Let’s Encrypt，这个地址就写死成这样就行
- `spec.acme.privateKeySecretRef` 指示此签发机构的私钥将要存储到哪个 Secret 对象中，名称不重要
- `spec.acme.http01` 这里指示签发机构使用 HTTP-01 的方式进行 acme 协议 (还可以用 DNS 方式，acme 协议的目的是证明这台机器和域名都是属于你的，然后才准许给你颁发证书)

成功创建 Issuer 后，创建 Certificate 并引用 Issuer 进行签发：

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-blog-liaosirui-com
  namespace: release-site
spec:
  dnsNames:
  # 要签发证书的域名
  - blog.liaosirui.com
  issuerRef:
    kind: ClusterIssuer
    # 引用 Issuer，指示采用 http01 方式进行校验
    name: cert-http01
  # 最终签发出来的证书会保存在这个 Secret 里面
  secretName: tls-blog-liaosirui-com

```

## DNS-01 校验方式签发证书

若使用 DNS-01 的校验方式，则需要选择 DNS 提供商。cert-manager 内置 DNS 提供商的支持，详细列表和用法请参见 Supported DNS01 providers。

<https://cert-manager.io/docs/configuration/acme/dns01/#supported-dns01-providers>

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-token: <API Token> # 将 Token 粘贴到此处，不需要 base64 加密。

```

创建 ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns01
spec:
  acme:
    privateKeySecretRef:
      name: letsencrypt-dns01
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - dns01:
        cloudflare:
          # 替换成你的 cloudflare 邮箱账号，API Token 方式认证非必需，API Keys 认证是必需
          email: my-cloudflare-acc@example.com 
          apiTokenSecretRef:
            key: api-token
            name: cloudflare-api-token-secret # 引用保存 cloudflare 认证信息的 Secret

```

创建 Certificate：

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-mydomain-com
  namespace: default
spec:
  dnsNames:
  - test.mydomain.com # 要签发证书的域名
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-dns01 # 引用 ClusterIssuer，指示采用 dns01 方式进行校验
  secretName: test-mydomain-com-tls # 最终签发出来的证书会保存在这个 Secret 里面

```
