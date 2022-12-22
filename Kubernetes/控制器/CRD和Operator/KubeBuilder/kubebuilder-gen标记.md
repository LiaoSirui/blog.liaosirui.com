官方文档：

- Config/Code 生成标记：<https://book.kubebuilder.io/reference/markers.html>
- CRD 生成相关的标记：<https://book.kubebuilder.io/reference/markers/crd.html>
- CRD 验证相关的标记：<https://book.kubebuilder.io/reference/markers/crd-validation.html>
- CRD 处理相关的标记：<https://book.kubebuilder.io/reference/markers/crd-processing.html>
- Webhook 相关的标记：<https://book.kubebuilder.io/reference/markers/webhook.html>
- Object/DeepCopy 相关的标记：<https://book.kubebuilder.io/reference/markers/object.html>
- RBAC 相关的标记：<https://book.kubebuilder.io/reference/markers/rbac.html>

## CRD 生成

作用于结构体上方，用于配置全局显示和启用

- 配置 CRD 范围和别名

```go
// +kubebuilder:resource:scope=Cluster,shortName={'',''},categories={'',''}
```

常用参数：

`scope=Cluster`：非命名空间资源（与 node 类似，不需要指定命名空间），若不加则为命名空间资源

`shortNam={}`：定义 CRD 的别名，可以定义多个（类似于 service==svc ），注解中切片用{"",""}表示

`categories={}`：资源组的别名

示例：

```go
//+kubebuilder:resource:scope=Cluster

// KBDev is the Schema for the kbdevs API
type KBDev struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   KBDevSpec   `json:"spec,omitempty"`
	Status KBDevStatus `json:"status,omitempty"`
}

```

- 指定 kubectl get 时显示的字段

```go
// +kubebuilder:printcolumn:JSONPath=<string>
// +kubebuilder:printcolumn:JSONPath=".status.replicas",name=Replicas,type=string
```

可选参数：

1. `JSONPath`：显示的字段
2. `name`：当前列标题
3. `format`：当前列格式
4. `priority=<int>`：当前列的优先级
5. `type=<string>`：当前列的类型

示例：

```go

```

- 启用 status 和 scale 子对象

```go
// +kubebuilder:subresource:scale
// +kubebuilder:subresource:status
```

默认开启 status 后，外部修改的 status 将不会被捕获，只能通过控制器使用 `status().update()` 来修改

## CRD 字段验证

字段验证注解作用于结构体内部的字段之上

- 默认值

```go
// 设置默认值
// +kubebuilder:default=

// 允许空值
// +nullable
```

- 设置枚举

该字段只能使用这些值中的一个，否则无法通过 apiservice 检查

```go
// +kubebuilder:validation:Enum={}
```

- 长度限制

```go
// 数组最大/小长度
// +kubebuilder:validation:MaxItems=
// +kubebuilder:validation:MinItems=

// 字符串的最大/小长度
// +kubebuilder:validation:MaxLength=
// +kubebuilder:validation:MinLength=

// 允许的最大/小数字
// +kubebuilder:validation:Maximum=
// +kubebuilder:validation:Minimum=
```

- 格式限制

```go
// 该字段是可选字段，非必须（默认都是必须）
// +kubebuilder:validation:Optional

// 该字段必须存在
// +kubebuilder:validation:Required

// 只能是该数的倍数
// +kubebuilder:validation:MultipleOf=

// 该字段内容的正则匹配
// +kubebuilder:validation:Pattern=

// 指定格式 （默认使用 go 的类型）
// +kubebuilder:validation:Type=

// 该字段全局唯一（不可以和其他 cr 相同）
// +kubebuilder:validation:UniqueItems=true
```

## RBAC 权限

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
// +kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;watch
// +kubebuilder:rbac:groups=core,resources=events,verbs=get;list;watch;create;patch
// +kubebuilder:rbac:groups=core,resources=namespace,verbs="*"
// +kubebuilder:rbac:groups=core,resources=services,verbs="*"
// +kubebuilder:rbac:groups=apps,resources=statefulsets,verbs="*"
// +kubebuilder:rbac:groups=devops.aipaas.io,resources=kbdevs,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=devops.aipaas.io,resources=kbdevs/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=devops.aipaas.io,resources=kbdevs/finalizers,verbs=update
```

