## Capsule

Kubernetes 的多租户管理一直是个复杂的难题。虽然 K8s 本身支持命名空间，但要想实现真正的资源隔离，还需要进行更多的配置。Capsule 这个开源项目正是为了解决这个问题而开发的

Capsule 是一种 Kubernetes 多租户管理解决方案。它允许你将一个 Kubernetes 集群划分为多个独立的 “租户”。每个租户都有自己独立的资源配额和隔离策略。

- <https://projectcapsule.dev/docs/tenants/namespaces/>

应用场景

- 公司内部多个团队共用一个 K8s 集群
- 向客户提供 Kubernetes 即服务（KaaS）
- 开发/测试/正式环境完全隔离
- 多项目或多人协作时的资源管理

## 使用入门

### 建立租户

<https://projectcapsule.dev/docs/rules/>

```yaml
apiVersion: capsule.clastix.io/v1beta1
kind: Tenant
metadata:
  name: my-tenant
spec:
  owner:
    kind: User
    name: alice
  nodeSelector:
    kubernetes.io/os: linux
  quotas:
    cpu: "20"
    memory: 64Gi
    persistentvolumeclaims: "10"
  namespacesQuota: "10"
  servicesQuota: "50"
  ingressClasses:
    - nginx
  ingressHostnames:
    - "*.example.com"
  storageClasses:
    - standard
    - custom-storage
```

