## 准入控制器

准入控制器是在对象持久化之前用于对 Kubernetes API Server 的请求进行拦截的代码段，在请求经过身份验证和授权之后放行通过

时序图如下所示：

![image-20230506105627557](.assets/Admission/image-20230506105627557.png)

准入控制器（Admission Controller）是一种插件，它会拦截在 API Server 层面的请求，执行对应的检查和处理。这些处理可能包含验证、默认设置以及请求的条件限制等。准入控制器不会（也不能）阻止读取（get、watch 或 list）对象的请求

准入控制存在两种 WebHook

- 变更准入控制 MutatingAdmissionWebhook：Mutating 控制器可以修改他们处理的资源对象
- 验证准入控制 ValidatingAdmissionWebhook：如果任何一个阶段中的任何控制器拒绝了请求，则会立即拒绝整个请求，并将错误返回给最终的用户

执行的顺序是先执行 MutatingAdmissionWebhook 再执行 ValidatingAdmissionWebhook

## 常见的准入控制器

- NamespaceExists ：此准入控制器检查针对名字空间作用域的资源（除 Namespace 自身）的所有请求。如果请求引用的名字空间不存在，则拒绝该请求
- NamespaceLifecycle：该准入控制器禁止在一个正在被终止的 Namespace 中创建新对象，并确保针对不存在的 Namespace 的请求被拒绝。该准入控制器还会禁止删除三个系统保留的名字空间，即 default、 kube-system 和 kube-public。Namespace 的删除操作会触发一系列删除该名字空间中所有对象（Pod、Service 等）的操作。为了确保这个过程的完整性，我们强烈建议启用这个准入控制器

- LimitRanger：此准入控制器会监测传入的请求，并确保请求不会违反 Namespace 中 LimitRange 对象所设置的任何约束。如果你在 Kubernetes 部署中使用了 LimitRange 对象，则必须使用此准入控制器来执行这些约束。LimitRanger 还可以用于将默认资源请求应用到没有设定资源约束的 Pod；当前，默认的 LimitRanger 对 default 名字空间中的所有 Pod 都设置 0.1 CPU 的需求
- ServiceAccount：此准入控制器实现了 ServiceAccount 的自动化。强烈推荐为 Kubernetes 项目启用此准入控制器。如果你打算使用 Kubernetes 的 ServiceAccount 对象，你应启用这个准入控制器
- DefaultStorageClass：此准入控制器监测没有请求任何特定存储类的 PersistentVolumeClaim 对象的创建请求， 并自动向其添加默认存储类。这样，没有任何特殊存储类需求的用户根本不需要关心它们，它们将被设置为使用默认存储类。当未配置默认存储类时，此准入控制器不执行任何操作。如果将多个存储类标记为默认存储类， 此控制器将拒绝所有创建 PersistentVolumeClaim 的请求，并返回错误信息。要修复此错误，管理员必须重新检查其 StorageClass 对象，并仅将其中一个标记为默认。此准入控制器会忽略所有 PersistentVolumeClaim 更新操作，仅处理创建操作
- PodSecurity：PodSecurity 准入控制器在新 Pod 被准入之前对其进行检查， 根据请求的安全上下文和 Pod 所在名字空间允许的 Pod 安全性标准的限制来确定新 Pod 是否应该被准入
