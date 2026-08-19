## Headlamp 简介

Headlamp 是一个开源的 Kubernetes Web UI，旨在提供一个现代化的用户界面来管理 Kubernetes 集群。它是一个轻量级的替代品，适用于那些需要一个简单易用的界面的用户

## Headlamp 插件生态

Headlamp 的插件系统允许用户扩展其功能，进一步增强运维能力

## 多集群管理

支持多集群管理，可以通过 Headlamp 来管理多个集群

OIDC Kubeconfig 示例（DexIdP）

```yaml
apiVersion: v1
kind: Config
preferences: {}
clusters:
  - cluster:
      certificate-authority-data: ...
      server: https://172.31.24.101:6443
    name: dev-kube-cluster
  - cluster:
      certificate-authority-data: ...
      server: https://172.31.24.201:6443
    name: infra-kube-cluster
contexts:
  - context:
      cluster: dev-kube-cluster
      namespace: cpaas-monitoring-system
      user: dev-admin
    name: dev-kube-cluster
  - context:
      cluster: infra-kube-cluster
      namespace: cpaas-infra-system
      user: infra-admin
    name: infra-kube-cluster
users:
  - name: dev-admin
    user:
      auth-provider:
        name: oidc
        config:
          idp-issuer-url: https://cpaas.dev.alpha-quant.cn/sys-apps/dex-idp
          client-id: dex-idp
          client-secret: 628e0eb5-3f8f-4cd9-86ba-2dbf36467ad4
          # 注意是 scope 不是 scopes
          scope: openid,profile,email,groups
  - name: infra-admin
    user:
      auth-provider:
        name: oidc
        config:
          idp-issuer-url: https://cpaas.dev.alpha-quant.cn/sys-apps/dex-idp
          client-id: dex-idp
          client-secret: 628e0eb5-3f8f-4cd9-86ba-2dbf36467ad4
          scope: openid,profile,email,groups
```

