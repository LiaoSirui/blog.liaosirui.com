虽然 capsule 通过 webhook 机制可以将权限限定在特定的 namespaces 中, 但还是会存在下列一类的问题

```bash
$ kubectl get namespaces
Error from server (Forbidden): namespaces is forbidden:
User "srliao" cannot list resource "namespaces" in API group "" at the cluster scope

# 但是在 get 时又会提示有权限
$ kubectl auth can-i [get|list|watch|delete] ns oil-production
yes
```

RBAC 操作仅在 Cluster-Scope 中可用，并且不授予没有适当权限的用户。

为了解决这类问题，capsule 引入了自己的解决方案, 即 capsule-proxy.capsule-proxy 实现了一个简单的反向代理，它只拦截对 API 服务器的特定请求，然后 capsule 完成请求的转换、响应、返回数据, 这样就可解决上述问题

```yaml
apiVersion: capsule.clastix.io/v1beta1
kind: GlobalProxySettings
metadata:
  name: srliao-proxy-settings
spec:
  rules:
    - subjects:
        - kind: User
          name: srliao
      clusterResources:
        - apiGroups:
            - ""
          resources:
            - nodes
          selector:
            matchLabels:
              kubernetes.io/hostname: aq-dev-node

```

