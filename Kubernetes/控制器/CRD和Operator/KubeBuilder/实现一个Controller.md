官方文档：

- 一个 kubebuilder 项目有哪些组件？<https://cloudnative.to/kubebuilder/cronjob-tutorial/basic-project.html>
- MultiNamespacedCacheBuilder https://pkg.go.dev/github.com/kubernetes-sigs/controller-runtime/pkg/cache#MultiNamespacedCacheBuilder
- GVK 介绍：<https://cloudnative.to/kubebuilder/cronjob-tutorial/gvks.html>

## 模板项目

当自动生成一个新项目时，Kubebuilder 为提供了一些基本的模板

### 创建基础组件

首先是基本的项目文件初始化，为项目构建做好准备。

- `go.mod`: 的项目的 Go mod 配置文件，记录依赖库信息
- `Makefile`: 用于控制器构建和部署的 Makefile 文件
- `PROJECT`: 用于生成组件的 Kubebuilder 元数据

### 启动配置

还可以在 config/ 目录下获得启动配置。现在，它只包含了在集群上启动控制器所需的 Kustomize YAML 定义，但一旦开始编写控制器，它还将包含的 CustomResourceDefinitions(CRD) 、RBAC 配置和 WebhookConfigurations 。

config/default 在标准配置中包含 Kustomize base ，它用于启动控制器。

其他每个目录都包含一个不同的配置，重构为自己的基础。

- config/manager: 在集群中以 pod 的形式启动控制器
- config/rbac: 在自己的账户下运行控制器所需的权限

### 入口函数

最后，当然也是最重要的一点，生成项目的入口函数：`main.go`

## 入口函数

main 文件最开始是 import 一些基本库，尤其是：

- 核心的控制器运行时库
- 默认的控制器运行时日志库-- Zap

```go
package main

import (
	"flag"
	"os"

	// Import all Kubernetes client auth plugins (e.g. Azure, GCP, OIDC, etc.)
	// to ensure that exec-entrypoint and run can make use of them.
	_ "k8s.io/client-go/plugin/pkg/client/auth"

	"k8s.io/apimachinery/pkg/runtime"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/healthz"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"

	//+kubebuilder:scaffold:imports
)
```

每一组控制器都需要一个 Scheme，它提供了 Kinds 和相应的 Go 类型之间的映射

```go
var (
	scheme   = runtime.NewScheme()
	setupLog = ctrl.Log.WithName("setup")
)

func init() {

	//+kubebuilder:scaffold:scheme
}
```



这段代码的核心逻辑比较简单:

- 通过 flag 库解析入参
- 实例化了一个 manager，它记录着所有控制器的运行情况，以及设置共享缓存和API服务器的客户端（注意，把的 Scheme 的信息告诉了 manager）。
- 运行 manager，它反过来运行所有的控制器和 webhooks。manager 状态被设置为 Running，直到它收到一个优雅停机 (graceful shutdown) 信号。这样一来，当在 Kubernetes 上运行时，就可以优雅地停止 pod。

```go
func main() {
    var metricsAddr string
    flag.StringVar(&metricsAddr, "metrics-addr", ":8080", "The address the metric endpoint binds to.")
    flag.Parse()

    ctrl.SetLogger(zap.New(zap.UseDevMode(true)))

    mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{Scheme: scheme, MetricsBindAddress: metricsAddr})
    if err != nil {
        setupLog.Error(err, "unable to start manager")
        os.Exit(1)
    }

```

注意：Manager 可以通过以下方式限制控制器可以监听资源的命名空间。

```go
    mgr, err = ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
        Scheme:             scheme,
        Namespace:          namespace,
        MetricsBindAddress: metricsAddr,
    })
```

上面的例子将把项目改成只监听单一的命名空间。在这种情况下，建议通过将默认的 ClusterRole 和 ClusterRoleBinding 分别替换为 Role 和 RoleBinding 来限制所提供给这个命名空间的授权。

另外，也可以使用 [MultiNamespacedCacheBuilder](https://pkg.go.dev/github.com/kubernetes-sigs/controller-runtime/pkg/cache#MultiNamespacedCacheBuilder) 来监听特定的命名空间。

## GVK 介绍

### 术语

当在 Kubernetes 中谈论 API 时，经常会使用 4 个术语：groups 、versions、kinds 和 resources。

- 组和版本

Kubernetes 中的 API 组简单来说就是相关功能的集合。每个组都有一个或多个版本，顾名思义，它允许随着时间的推移改变 API 的职责

- 类型和资源

```plain
GVK = Group Version Kind
GVR = Group Version Resources
```

每个 API 组-版本包含一个或多个 API 类型，称之为 Kinds

虽然一个 Kind 可以在不同版本之间改变表单内容，但每个表单必须能够以某种方式存储其他表单的所有数据（可以将数据存储在字段中，或者在注释中）。 这意味着，使用旧的 API 版本不会导致新的数据丢失或损坏

resources（资源） 只是 API 中的一个 Kind 的使用方式。通常情况下，Kind 和 resources 之间有一个一对一的映射。 例如，`pods` 资源对应于 `Pod` 种类。但是有时，同一类型可能由多个资源返回。例如，`Scale` Kind 是由所有 `scale` 子资源返回的，如 `deployments/scale` 或 `replicasets/scale`。这就是允许 Kubernetes HorizontalPodAutoscaler(HPA) 与不同资源交互的原因。然而，使用 CRD，每个 Kind 都将对应一个 resources。

注意：resources 总是用小写，按照惯例是 Kind 的小写形式。

### Golang 中的实现

当在一个特定的群组版本 (Group-Version) 中提到一个 Kind 时，会把它称为 GroupVersionKind，简称 GVK

与资源 (resources) 和 GVR 一样，每个 GVK 对应 Golang 代码中的到对应生成代码中的 Go type

### Scheme

之前看到的 `Scheme` 是一种追踪 Go Type 的方法，它对应于给定的 GVK

例如，假设将 `"tutorial.kubebuilder.io/api/v1".CronJob{}` 类型放置在 `batch.tutorial.kubebuilder.io/v1` API 组中（也就是说它有 `CronJob` Kind)

然后，便可以在 API server 给定的 json 数据构造一个新的 `&CronJob{}`

```json
{
    "kind": "CronJob",
    "apiVersion": "batch.tutorial.kubebuilder.io/v1",
    ...
}
```

或当在一次变更中去更新或提交 `&CronJob{}` 时，查找正确的组版本

## 创建一个 API