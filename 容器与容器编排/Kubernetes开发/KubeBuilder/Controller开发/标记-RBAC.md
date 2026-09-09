
更多信息请查看官方文档

- <https://book.kubebuilder.io/reference/markers/rbac>

- <https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/rbac/>

用域控制器的`Reconcile`方法上方，用于获取`Client-go`需要的权限

```go
// +kubebuilder:rbac:group=,resources=,verbs={}
```

可选参数：

1. `group`:权限的组（group.domain)
2. `resources`资源类型
3. `verbs`需要的权限类型
4. `resourceNames`：API名称
5. `namespace`权限需要的范围

示例：

```go
// +kubebuilder:rbac:groups="",resources=pods,verbs=create;get;list;watch;update;patch;delete
// +kubebuilder:rbac:groups="",resources=namespaces,verbs="*"
// +kubebuilder:rbac:groups=core,resources=events,verbs=get;list;watch;create;patch
// +kubebuilder:rbac:groups=core,resources=services,verbs="*"
// +kubebuilder:rbac:groups=apps,resources=statefulsets,verbs="*"
// +kubebuilder:rbac:groups=xxx,resources=xs,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=xxx,resources=xs/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=xx,resources=xs/finalizers,verbs=update
```

