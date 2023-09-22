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

