更多信息请查看官网文档：<https://book.kubebuilder.io/reference/markers/crd-validation.html>

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

简单实用示例

给 `GuestbookSpec` 的 Port 增加验证, Port 指定范围 80~90

```
type GuestbookSpec struct {
 //+kubebuilder:validation:Minimum:=80
 //+kubebuilder:validation:Maximum:=90

 Port int `json:"port,omitempty"`
}
```

