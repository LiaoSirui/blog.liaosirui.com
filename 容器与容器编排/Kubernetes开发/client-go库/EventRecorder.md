## 发布事件

官方文档：<https://kubebuilder.io/reference/raising-events.html>

从控制器协调功能发布事件对对象通常很有用，因为它们允许用户或任何自动化进程查看特定对象发生的情况并对其做出响应

可以通过运行 `kubectl describe <resource kind> <resource name>`，此外，还可以通过运行 `kubectl get events` 来查看事件

注意：不建议为所有操作发出事件。如果引发太多事件，就会给集群上的解决方案使用者带来糟糕的用户体验。并且它们可能会很难从混乱的事件中过滤出可操作的事件。有关更多信息，请查看 Kubernetes API 约定 <https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#events>

## 在控制器上使用 EventRecorder

Reconciler 下添加 `Recorder record.EventRecorder`

```go
type UserReconciler struct {
	client.Client
	Scheme   *runtime.Scheme
	Recorder record.EventRecorder
}
```

## 如何能够引发事件

事件是使用 EventRecorder（https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#events）从 Controller发布 的 type CorrelatorOptions struct， 可以通过调用 `GetRecorder(name string) Manager` 为 Controller 创建事件记录器

```go
if err = (&authcontroller.UserReconciler{
	Client:   mgr.GetClient(),
	Scheme:   mgr.GetScheme(),
	Recorder: mgr.GetEventRecorderFor("user-controller"),
}).SetupWithManager(mgr); err != nil {
	setupLog.Error(err, "unable to create controller", "controller", "User")
	os.Exit(1)
}
```

授权项目创建事件

```go
//+kubebuilder:rbac:groups=core,resources=events,verbs=create;patch
```

## 生成 Events

```go
Event(object runtime.Object, eventtype, reason, message string)
```

- object：是此事件所涉及的对象。
- eventtype：是此事件类型，并且是 Normal 或 Warning。（https://github.com/kubernetes/api/blob/6c11c9e4685cc62e4ddc8d4aaa824c46150c9148/core/v1/types.go#L6019-L6024）
- reason：是生成此事件的原因，它应该简短且UpperCameCase格式独特。该值可以自动出现在 wsitch 语句中。（https://github.com/kubernetes/api/blob/6c11c9e4685cc62e4ddc8d4aaa824c46150c9148/core/v1/types.go#L6048）
- message: 旨在供作者查看（https://github.com/kubernetes/api/blob/6c11c9e4685cc62e4ddc8d4aaa824c46150c9148/core/v1/types.go#L6053）

示例：

```go
    // The following implementation will raise an event
    r.Recorder.Event(cr, "Warning", "Deleting",
        fmt.Sprintf("Custom Resource %s is being deleted from the namespace %s",
            cr.Name,
            cr.Namespace))

```

添加事件

```go
r.Recorder.Event(
  cr, 
  corev1.EventTypeNormal, 
  "Created", 
  fmt.Sprintf("Custom Resource %s is being deleted from the namespace %s", cr.Name, cr.Namespace))
```

