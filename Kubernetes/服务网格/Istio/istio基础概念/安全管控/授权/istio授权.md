Istio 的 AuthorizationPolicy 是一种安全策略，用于控制在Istio服务网格中谁可以访问哪些服务。它提供了基于角色的访问控制（RBAC），允许定义细粒度的权限，以限制对特定服务、方法和路径的访问。AuthorizationPolicy 使用 Istio 的 Envoy 代理拦截并检查传入的请求，以确保它们满足定义的访问策略。

AuthorizationPolicy 的示例如下：

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin-policy
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: httpbin
  action: ALLOW
  rules:
  - to:
    - operation:
        paths: ["/delay/*"]
```

AuthorizationPolicy 的主要属性包括：

- `action`: 定义在规则匹配时要执行的操作。它可以是`ALLOW`（允许访问），`DENY`（拒绝访问）或`CUSTOM`（自定义操作，与自定义扩展插件一起使用）。
- `rules`: 定义一组访问策略规则。每个规则可以包括以下属性：
  - `from`: 包含一个或多个源规范，用于定义允许访问的来源。可以包括`principals`（发起请求的主体，例如用户或服务帐户）和`namespaces`（发起请求的命名空间）。
  - `to`: 包含一个或多个目标规范，用于定义允许访问的操作。可以包括`methods`（允许的HTTP方法，例如GET或POST）和`paths`（允许访问的路径，可以是精确路径或通配符路径）。
  - `when`: 包含一组条件，用于定义规则生效的附加约束。例如，您可以使用`key`和`values`定义请求头匹配。