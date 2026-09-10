## controller-runtime 框架

<https://github.com/kubernetes-sigs/controller-runtime>

提供了用于构建 Controller 的库。Controller 实现 Kubernetes API 访问，在这基础之上构建 Operators，Workload APIs，Configuration APIs，Autoscalers 等。

## 基础概念

### Client

提供用于读写 Kubernetes 对象的 Read/Write 客户端。

### Cache

提供读取客户端，用于从本地缓存读取对象。缓存可以注册处理程序以响应更新缓存的事件。

### Manager

Manager 是创建 Controller 所必需的，并提供 Controller 共享的依赖项，例如客户端，缓存，方案等。应通过调用 `Manager.Start` 通过 Manager 启动 Controller。

### Controller

控制器实现 Kubernetes API 来响应事件（Create/Update/Delete objetc）并确保资源实例指定的状态与系统状态匹配（使用）。这称为 reconcile。如果它们不匹配，则控制器将根据需要 create/update/delete objects 以使其匹配。

控制器实现工作队列处理 reconcile 的请求。与 http 处理程序不同，Controller 不会直接处理事件，而是将请求加入队列以最终协调该对象。这意味着可以将多个事件的处理分批处理，并且每次协调时都必须读取系统的完整状态。

Controllers 需要 Reconciler 来执行从工作队列中拉出的工作。

Controllers 需要配置 Watchs 为监控 reconcile.Requests 的请求。

### Scheme

每一组 Controllers 都需要一个 Scheme，提供了 Kinds 与对应 Go types 的映射，也就是说给定 Go type 就知道他的 GVK，给定 GVK 就知道他的 Go type，比如说我们给定一个 `Scheme: "tutotial.kubebuilder.io/api/v1".CronJob{}` 这个 Go type 映射到 `batch.tutotial.kubebuilder.io/v1` 的 CronJob GVK，那么从 Api Server 获取到下面的 JSON:

```json
{
    "kind": "CronJob",
    "apiVersion": "batch.tutorial.kubebuilder.io/v1",
    ...
}
```

就能构造出对应的 Go type 了，通过这个 Go type 也能正确地获取 GVR 的一些信息，控制器可以通过该 Go type 获取到期望状态以及其他辅助信息进行调谐逻辑。

### OwnerReference

K8s GC 在删除一个对象时，任何 ownerReference 是该对象的对象都会被清除，与此同时，Kubebuidler 支持所有对象的变更都会触发 Owner 对象 controller 的 Reconcile 方法。

### Webhook

Admission Webhooks 是一种扩展 kubernetes API 的机制。可以使用目标事件类型（对象创建，更新，删除）来配置 Webhooks，当某些事件发生时，API 服务器将向他们发送 Admission Requests。Webhook 可能会转变和（或）验证请求的对象，并将响应发送回 API 服务器。

admission Webhook 有两种类型：mutating 和 validating。mutating webhook 用于在 API 服务器允许之前转变核心 API 对象或 CRD 实例。和 validating 用于验证对象是否满足某些要求。

Admission Webhooks 要求提供 Handle 来处理接收到的 AdmissionReview 请求。

### Reconciler

Reconciler 提供给 Controller 的方法接口（具体方法为 Reconcile）：可以随时通过对象的 Name 和 Namespace 调用。当 Reconciler 被调用时，Reconciler 将确保系统状态与调用 Reconciler 时对象中指定的状态相匹配。

示例：为 ReplicaSet 对象调用 Reconciler 函数。ReplicaSet 指定 5 个副本，但系统中仅存在 3 个 Pod。Reconciler 将再创建 2 个 Pod，并设置 OwnerReference 指向 ReplicaSet 和 controller=true。

Reconciler 包含 Controller 的所有业务逻辑。

- 一个 Reconciler 通常在一个对象（资源实例）上工作。对于单独的对象（资源实例），请使用单独的控制器。如果希望从其他对象触发该 Reconciler，则可以提供一个 map（例如所有者引用），该 map 将触发对帐的对象映射到要该对象。
- 提供 Reconciler 的协调器对象的 Name/Namespace。
- Reconciler 不关心负责触发的事件内容或事件类型。例如，创建或更新 ReplicaSet 无关紧要，Reconciler 将始终将系统中 Pod 的数量与调用对象时指定的数量进行比较。

### Source

resource.Source 是 Controller.Watch 的参数。Source 提供事件流（streaming event）类型。事件流（streaming event）通常来自 watch Kubernetes API event（例如 Pod 创建，更新，删除）。

示例：source.Kind 将 Kubernetes API 监控（Watch） GroupVersionKind 的 Create，Update，Delete 事件。

- Source 提供事件流 (例如 object 的 Create, Update, Delete) 通过 Watch API 为 Kubernetes 对象
- 用户应该只使用提供的 Source 接口，而不是在实现自己的 Source。

### EventHandler

handler.EventHandler 是 Controller.Watch 的参数，它响应 reconcile.Requests 事件（排队方式）。

示例：Pod Create 事件（来源于上面 Source）提供给 eventhandler.EnqueueHandler。该 Pod Create 事件将在一个 reconcile.Request 排队。

- EventHandlers 通过使 reconcile.enqueques 处理一个或多个对象的事件。
- EventHandlers 可以将一个对象的事件映射到一个 reconcile.Request 来请求相同类型的对象。
- EventHandlers 可以将对象的事件映射到 reconcile.Request 不同类型的对象。例如，将 Pod 事件映射到拥有的 ReplicaSet 的 reconcile.Request。
- EventHandlers 可以将一个对象的事件映射到多个协调对象。对相同或不同类型的对象的请求。例如，将 Node 事件映射到响应集群调整大小事件的对象。
- 用户应该只使用提供的 EventHandler 实现，而不是在都实现自己的实现。

### Predicate

predicate.Predicate 是 Controller.Watch 的可选参数，用于过滤事件。这使普通的过滤器可以重复使用和组合。

- Predicate 接受一个事件并返回布尔值（如果为真，入队）
- Predicate 是可选参数
- 用户应该使用 Predicate 接口，但是可以实现 additional Predicate，例如更改 generation，更改标签选择器等。