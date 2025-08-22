## 配置事件投递

在 v1.9.3 及以上版本的 CoreDNS 中，可以开启 k8s_event 插件以将 CoreDNS 关键日志以 Kubernetes 事件的形式投递到事件中心

关于 k8s_event 插件，请参见 k8s_event：

- <https://github.com/coredns/coredns.io/blob/master/content/explugins/k8s_event.md>

- <https://github.com/coredns/k8s_event>

插件编译需要开启

```ini
k8s_event:github.com/coredns/k8s_event
kubernetai:github.com/coredns/kubernetai
```

添加环境变量

```yaml
env:
  - name: COREDNS_POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: COREDNS_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
```

添加一个 cluster role 和 rolebindings

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: coredns-events-admin
rules:
  - apiGroups:
    - ""
    - events.k8s.io
    resources:
    - events
    verbs:
    - create
    - patch
    - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: console
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: coredns-events-admin
subjects:
  - kind: ServiceAccount
    name: coredns
    namespace: kube-system

```

core dns 配置示例

```ini
.:53 {
    // ...
    ready
    
    // 新增开始
    kubeapi
    k8s_event {
      level info error warning
      rate 0.15 10 1024
    }
    // 新增结束
    
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
        ttl 30
    }
    // ...
}
```

## 验证事件投递

查看事件

```bash
kubectl get ev -A -w | grep CoreDNS
```

