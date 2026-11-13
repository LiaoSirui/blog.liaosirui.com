## 租户

在 Capsule 中，租户是一种抽象，用于在集群管理员定义的一组边界内将多个命名空间分组到单个实体中。然后将租户分配给称为租户所有者的用户或用户组

只有集群管理员才有权限操作 Tenant 对象

```yaml
apiVersion: capsule.clastix.io/v1beta2
kind: Tenant
metadata:
  name: srliao
spec:
  owners:
    - name: srliao
      kind: User
    - name: system:serviceaccount:srliao:default
      kind: ServiceAccount

```

声明了一个 srliao 的租户，它的租户管理员是 User srliao 或者是 sa，具有相应权限的 sa 也可以是租户管理员

每个租户都有一个委派的用户或一组用户作为租户管理员。在 capsule 中这被称为租户所有者。其他用户可以在租户内部使用由租户所有者直接分配的不同级别的权限和授权进行操作。

- 具有创建 ns 的权限
- 具有删除 ns 的权限，只能删除由其创建的 ns

- 没有 get ns 的权限
- 没有 get 其它集群级别资源的权限

默认情况下，租户所有者将通过 RoleBinding API 被授予两个 ClusterRole 资源：

- Kubernetes admin (可以理解为是限制在 namespace 中的 admin 而不是真的集群 admin)，由它授权大多数命名空间范围内的资源
- 由 Capsule 创建名为 capsule-namespace-deleter 的权限，允许删除创建的命名空间，所以 Owner 有删除 ns 的权限

## 属性

tenant 支持的属性非常多，实现这些属性的机制是通过策略引擎的方式

```yaml
apiVersion: capsule.clastix.io/v1beta2
kind: Tenant
metadata:
  name: srliao
spec:
  owners:
    - name: srliao
      kind: User
    - name: system:serviceaccount:srliao:default
      kind: ServiceAccount
  additionalRoleBindings: # 可以为相关的用户指定额外的权限，与 rbac 进行联动
    - clusterRoleName: "argoproj-provisioner"
      subjects:
        - apiGroup: rbac.authorization.k8s.io
          kind: User
          name: alice
        - apiGroup: rbac.authorization.k8s.io
          kind: User
          name: joe
  namespaceOptions: # 可以创建的最大 namespace 数量
    quota: 3
    additionalMetadata: # 给 ns 添加 annotation 及 label
      annotations:
        storagelocationtype: s3
      labels:
        capsule.clastix.io/backup: "true"
  resourceQuotas: # ns 的 resourcequota, 最终转换成 ns 的 resourcequota 对象, 也支持自定义的资源 quota
    scope: Tenant # 可以是 tenant 级别 (该 tenant 下的所有的 ns 有效), 也可以是 namespace 级别 (针对 ns 有限, ns 可通过 label selector 选定)
    items:
      - hard:
          limits.cpu: "8"
          limits.memory: 16Gi
          requests.cpu: "8"
          requests.memory: 16Gi
          pods: "10"
  limitRanges: # 容器的 limitrange，最终转换成 ns 的 limitrange 对象
    items:
      - limits:
          - default:
              cpu: 500m
              memory: 512Mi
            defaultRequest:
              cpu: 100m
              memory: 10Mi
            type: Container
  priorityClasses: # 限制该 tenant 下的所有 pod 的优先级
    allowed:
      - custom # 自定义的 PriorityClass
    allowedRegex: "^tier-.*$"
    matchLabels:
      env: "production"
  nodeSelector: # 给 tenant 下的所有 pod 指定调度策略，当然也包含亲和及非亲和属性
    pool: oil
    kubernetes.io/os: linux
  # ... 更多属性

```

## GlobalTenantResource

GlobalTenantResource 被设计用于在选定的 tenant 对象中共享资源

```yaml
apiVersion: capsule.clastix.io/v1beta2
kind: GlobalTenantResource
metadata:
  name: pull-secrets
spec:
  tenantSelector: # 通过 label 选择 tenant, 只有 tenant 对象上具有该 label 才能继承 resources 中指定的对象
    matchLabels:
      tenant: srliao
  resyncPeriod: 60s # 资源是否已复制并同步的时间间隔
  resources: # 指定需要共享的资源对象列表，同样，这里支持任一对象，包含 CRD
    - namespacedItems:
        - apiVersion: v1
          kind: Secret
          namespace: harbor-system # 在 harbor-system 中带有 tenant: srliao label 的 secret 都将被共享
          selector:
            matchLabels:
              tenant: srliao

```

由于 GlobalTenantResource 是群集范围内的资源，因此只有群集管理员才能操作该对象

## TenantResource

在某一 tenant 中的所有 ns 共享资源

```yaml
apiVersion: capsule.clastix.io/v1beta2
kind: TenantResource
metadata:
  name: solar-db
  namespace: solar-system
spec:
  resyncPeriod: 60s # 资源是否已复制并同步的时间间隔
  resources:
    - namespaceSelector: # 选择 namespace
        matchLabels:
          environment: production
      rawItems: # 选择资源对象列表
        - apiVersion: postgresql.cnpg.io/v1
          kind: Cluster
          metadata:
            name: postgresql
          spec:
            description: PostgreSQL cluster for the Solar project
            instances: 3
            postgresql:
              pg_hba:
                - hostssl app all all cert
            primaryUpdateStrategy: unsupervised
            storage:
              size: 1Gi

```

