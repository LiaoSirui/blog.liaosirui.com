## Labels

Label 允许在 Kubernetes 资源上附加对于系统或者用户有意义的标示性属性，方便对 Kubernetes 资源进行分组管理。 这些属性对不会直接对 Kubernetes 核心组件产生语义，不过可能间接地被 Kubernetes 核心组件处理产生效果。例如：用户在 pod 或者 node 上加一些 label，然后配置一些调度策略，Kubernetes 的 scheduler 会基于这些 label 信息进行调度。

Label 通过记录标示性属性，方便选择查询。支持两种选择判断方式：

- 相等判断
  - `=`：被选择的资源必须带 label key，并且 value 必须相等。
  - `==`：被选择的资源必须带 label key，并且 value 必须相等。
  - `!=`：被选择的资源不带 label key，或者带 label key，但是 value 不相等。
- 集合判断
  - `in`：被选择的资源必须带 label key，并且 value 在集合范围内。
  - `notin`：被选择的资源不带 label key，或者带 label key, 但是 value 不在集合范围内。
  - `exists`：被选择的资源必须带 label key，不检查 value。Label key 前加 `!` 表示不存在，则被选择的资源必须不带 label key。

Label 选择支持多条件查询，多条件间通过 `,` 隔开。例如：`partition,environment notin (qa)` 表示查询带有 `partition` label， 且带有 `environment` label 但是 `environment` 不是 `qa` 的资源。

### 语法规则

Label key 由两部分组成：可选的 prefix 和 name，它们之间通过 `/` 连接。下面对它们的语法规则进行对比：

|             | Label prefix  | Label name                                   |
| :---------- | :------------ | :------------------------------------------- |
| Existence   | Optional      | Required                                     |
| Max length  | 253           | 63                                           |
| Characters  | DNS subdomain | Alphanumeric                                 |
| Separator   | `.`           | `-`, `_`, `.`                                |
| Restriction | End with `/`  | Begin and end with an alphanumeric character |

> `kubernetes.io/` 和 `k8s.io/` 是 Kubernetes 为自己的核心组件预留的两个前缀，不允许被用户使用。

Label value 跟 label name 的语法规则一样。

### 选择器语法

```yaml
selector:
  matchLabels:
    component: redis
  matchExpressions:
    - {key: tier, operator: In, values: [cache]}
    - {key: environment, operator: NotIn, values: [dev]}
```

### 官方推荐的最佳实践

官方文档地址：https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

| Key                            | Description                                                  | Example        | Type   |
| ------------------------------ | ------------------------------------------------------------ | -------------- | ------ |
| `app.kubernetes.io/name`       | The name of the application                                  | `mysql`        | string |
| `app.kubernetes.io/instance`   | A unique name identifying the instance of an application     | `mysql-abcxzy` | string |
| `app.kubernetes.io/version`    | The current version of the application (e.g., a semantic version, revision hash, etc.) | `5.7.21`       | string |
| `app.kubernetes.io/component`  | The component within the architecture                        | `database`     | string |
| `app.kubernetes.io/part-of`    | The name of a higher level application this one is part of   | `wordpress`    | string |
| `app.kubernetes.io/managed-by` | The tool being used to manage the operation of an application | `helm`         | string |

## Annotations

Annotations 允许在 Kubernetes 资源上附加任意的非标识性元数据，用来记录资源的一些属性。这些元数据主要是给工具或者库来提取信息，一般不会直接开放给用户。

绝大多数基于 Kubernetes 的开源项目都不依赖于 DB，完全可以利用 Kubernetes 的能力，满足对 DB 的需求。对于需要持久化的数据，除了定义 CRD，另一种通用的做法就是将数据存储在 annotation 中。

由于 annotation 的定位是 Kubernetes 资源上附加任意的非标识性元数据，除了在 key 上有跟 label key 完全一样的限制外，在 value 上没有任何限制：可长可短，可结构化可非结构化，可包含任意字符。

## Labels 和 Annotations 对比

| 类型        | Labels                                                 | Annotation                                                   |
| :---------- | :----------------------------------------------------- | ------------------------------------------------------------ |
| 用法        | Identifying metadata for efficient queries and watches | Attach arbitrary non-identifying metadata to Kubernetes resources |
| 可选择的    | Yes                                                    | No                                                           |
| Keys 语法   | Label key syntax                                       | Label key syntax                                             |
| Values 语法 | Label value syntax                                     | Arbitrary                                                    |

## 最佳实践

- 平台必须使用带前缀的 label，前缀严格根据组织、产品、资源等信息定义。
- 不带前缀的 label 是预留给用户使用的。
- 给所有的资源加上合适的 label，最终这些 label 会提升资源管理的效率。