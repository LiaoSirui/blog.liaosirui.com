## 简介

组件说明

1. Dex 是一种身份认证服务，它使用 OpenID Connect 来驱动其他应用程序的身份验证。Dex 通过“connectors”充当其他身份提供商的门户。 这让 dex 将身份验证推到 LDAP 服务器、SAML 提供商或已建立的身份提供商（如 GitHub、Gitlab、Google 和 Active Directory等）。 客户端编写身份验证逻辑以与 dex 交互认证，然后 dex 通过 connector 转发到后端用户认证方认证，并返回给客户端Oauth2 Token。与其相似的还有 Keycloak，auth0 等
2. dex-k8s-authenticator 是一个web-app，它可以与 Dex 进行交互并获取 Dex 生成的 token 创建和修改 kubeconfig 文件的命令。用户执行这些生成的命令后可以完成 kubeconfig 文件配置

dex-k8s-authenticator 简介：

- GitHub 仓库：<https://github.com/mintel/dex-k8s-authenticator>

- 部署文档：<https://github.com/mintel/dex-k8s-authenticator/blob/master/docs/helm.md>

```mermaid
sequenceDiagram
Title: 核心认证流程
autonumber

participant user as 用户
participant dex-k8s-authenticator as dex-k8s-authenticator <br/>(https://login.k8s.example.com)
participant dex as Dex <br/> (https://dex.k8s.example.com)
participant github as GitHub
participant kubectl as kubectl
participant apiserver as K8s APIServer

user->>dex-k8s-authenticator: login(OIDC)
dex-k8s-authenticator->>dex: 
dex->>github: 
github-->>dex: id_token
dex-->>dex-k8s-authenticator: 
dex-k8s-authenticator-->>user: id_token
user->>kubectl: id_token
kubectl->>apiserver: id_token
apiserver-->>kubectl: is valid <br/> is expired <br/> is authorized
kubectl-->>user: 
```

## 安装

添加 如下 Helm 仓库

```
helm repo add skm https://charts.sagikazarmark.dev
```

Update Helm cache

```
helm repo update
```

获取 Amazon EKS 集群客户端证书：

```
aws eks describe-cluster --name <cluster-name> --query 'cluster.certificateAuthority' --region <region> --output text | base64 -d
```

为 dex-k8s-authenticator 创建 Value 文件：

```yaml
config:
  clusters:
    - name: your-cluster
      short_description: "Your cluster"
      description: "Your EKS cluster"
      issuer: https://dex.yourdomain.com
      client_id: your-cluster-client-id
      client_secret: your-cluster-client-secret
      redirect_uri: https://login.yourdomain.com/callback
      k8s_master_uri: https://your-eks-cluster-endpoint-url
      k8s_ca_pem: |
        -----BEGIN CERTIFICATE-----
        YOUR CLIENT CERTIFICATE DATA
        -----END CERTIFICATE-----
  
ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: acme
  hosts:
    - host: login.yourdomain.com
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: dex-k8s-authenticator-tls
      hosts:
        - login.yourdomain.com
```

