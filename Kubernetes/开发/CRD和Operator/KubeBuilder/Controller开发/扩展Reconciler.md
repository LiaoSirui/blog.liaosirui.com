## 扩展 Reconciler

假设现在已经监听到 CR 的变化事件（包括 创建、更新、删除、扩展），这个事件则会进入 WorkQueue 中。在进入 WorkQueue 之前， `controller-runtime` 会进行一些过滤处理和业务处理。主要涉及接口是 `EventHandler` 和 `Predicate`

其中 `EventHandler` 可以在事件入队列之前加入其他逻辑，其定义如下：

```go
//controller-runtime@v0.5.0\pkg\handler\eventhandler.go
//此处定义了针对不同事件的处理接口，我们可以通过实现此接口完成扩展业务逻辑
type EventHandler interface {
	// Create is called in response to an create event - e.g. Pod Creation.
	Create(event.CreateEvent, workqueue.RateLimitingInterface)

	// Update is called in response to an update event -  e.g. Pod Updated.
	Update(event.UpdateEvent, workqueue.RateLimitingInterface)

	// Delete is called in response to a delete event - e.g. Pod Deleted.
	Delete(event.DeleteEvent, workqueue.RateLimitingInterface)

	// Generic is called in response to an event of an unknown type or a synthetic event triggered as a cron or
	// external trigger request - e.g. reconcile Autoscaling, or a Webhook.
	Generic(event.GenericEvent, workqueue.RateLimitingInterface)
}
```

`Predicate` 则是对监听到的事件进行过滤，只关注想要的事件，其结构体如下：

```go
type Predicate interface {
	// Create returns true if the Create event should be processed
	Create(event.CreateEvent) bool

	// Delete returns true if the Delete event should be processed
	Delete(event.DeleteEvent) bool

	// Update returns true if the Update event should be processed
	Update(event.UpdateEvent) bool

	// Generic returns true if the Generic event should be processed
	Generic(event.GenericEvent) bool
}
```

在入队列之前，controller-runtime 的处理逻辑如下：

```go
//controller-runtime@v0.5.0\pkg\source\internal\eventsource.go
type EventHandler struct {
	EventHandler handler.EventHandler
	Queue        workqueue.RateLimitingInterface
	Predicates   []predicate.Predicate
}

func (e EventHandler) OnAdd(obj interface{}) {
	c := event.CreateEvent{}
	...
	// 这里可以自定义 Predicates，将事件进行过滤
	for _, p := range e.Predicates {
		if !p.Create(c) {
			return
		}
	}

	// 调用了上面的 EventHandler 对应的逻辑
	e.EventHandler.Create(c, e.Queue)
}

// 除了 OnAdd 外，还有 OnUpdate OnDelete
```

注意，最终入队列的数据结构如下，即只有 namespace 和name，并没有资源的类型

```go
type NamespacedName struct {
	Namespace string
	Name      string
}
```

在 `controller-runtime` 包中的 `controller.Start()`方法中，则会循环从队列中拿取一个事件

```go
// controller.go
func (c *Controller) Start(stop <-chan struct{}) error {
    ...
        // 启动多个 worker 线程，处理事件
        log.Info("Starting workers", "controller", c.Name, "worker count", c.MaxConcurrentReconciles)
		for i := 0; i < c.MaxConcurrentReconciles; i++ {
			go wait.Until(c.worker, c.JitterPeriod, stop)
		}
    ...
}
func (c *Controller) worker() {
	for c.processNextWorkItem() {
	}
}
func (c *Controller) processNextWorkItem() bool {
    // 拿取一个事件
    obj, shutdown := c.Queue.Get()
	if shutdown {
		// Stop working
		return false
	}

	// We call Done here so the workqueue knows we have finished
	// processing this item. We also must remember to call Forget if we
	// do not want this work item being re-queued. For example, we do
	// not call Forget if a transient error occurs, instead the item is
	// put back on the workqueue and attempted again after a back-off
	// period.
	defer c.Queue.Done(obj)
    //处理事件
	return c.reconcileHandler(obj)
}
```

## 监控多个资源变化

可能会遇到 CR -> Deployment -> Pod 的逻辑，即由CR 创建deployment，最终落入pod。这时，我们不仅需要监听 CR 的变化， deployment 以及 pod 的变化我们也需要关注，这就意味着在 reconciler 中也需要根据 deployment 变化进行相应的处理

```go
func (r *SampleReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&samplev1.Sample{}).
        Complete(r)
}
```

这里的 `For` 则可以指定需要监听的资源

看`NewControllerManagedBy()`的源码可以发现`pkg\builder\controller.go` 中实现了 **构建者模式**，`controller-runtime` 提供了一个 `builder` 方便我们进行配置。其中监听资源的有 `For()` `Owns()` 和`Watch()` ,`For()` `Owns()`都是基于`Watch()`实现，只不过是入队列前的 `eventHandler` 不同

简单来说，可以调用`Watch()`实现监听 deployment

```go
// Map function to convert Deployment events to reconciliation requests
mapDeploymentToRequest := func(ctx context.Context, object client.Object) []reconcile.Request {
	return []reconcile.Request{
		{NamespacedName: types.NamespacedName{
			Name:      object.GetLabels()["notebook-name"],
			Namespace: object.GetNamespace(),
		}},
	}
}

return ctrl.NewControllerManagedBy(mgr).
	For(&samplev1.Sample{}).
	Watches(
		&corev1.Deployment{},
		handler.EnqueueRequestsFromMapFunc(mapDeploymentToRequest),
	)

```

但这样做会监听所有 deployment 事件变化，如果想只关注由 CR 创建的 Deployment 因此可以采用 `Owns()` 方法

```go
func (r *SampleReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
		For(&samplev1.Sample{}).
		// 这里可以供我们指定 eventhandler
		Owns(&apps.Deployment{}).
        Complete(r)
```

当使用 CR 创建 deployment 时，可以为他塞入一个从属关系，类似于 Pod 资源的`Metadata` 里会有一个`OnwerReference`字段

```go
_ = controllerutil.SetControllerReference(sample, &deployment, r.Scheme)
```

这样在监听时，只会监听到带有 OwnerShip 的 deployment

> 其实 Owns() 方法另外定义了一个 eventHandler 做了处理

## 监听多资源下 evnetHandler 和 Reconciler 的逻辑

controller Reconciler 业务逻辑，实际上只应该处理 CR 的变化，但有时是 CR 所拥有的 Deployment 发生了变化，但对应的 CR 并不会有更新事件，因此需要在自定义`eventHandler`中，对资源进行判断。若是 CR 的变化，则直接向队列写入 namespace 和 name，若是 deployment 的变化，则向队列写入 deployment 对应 CR 的 namespace 和 name，以触发 Reconciler 的逻辑

```go
func (e *EnqueueRequestForDP) Create(evt event.CreateEvent, q workqueue.RateLimitingInterface) {
	if evt.Meta == nil {
		enqueueLog.Error(nil, "CreateEvent received with no metadata", "event", evt)
		return
	}
	_, ok := evt.Object.(*samplev1.Sample)
	if ok {
		q.Add(reconcile.Request{NamespacedName: types.NamespacedName{
				Name:      evt.Meta.Name,
				Namespace: evt.Meta.GetNamespace(),
			}})
		return
	}
	deploy ,_:= evt.Object.(*v1.Deployment)
	for _, owner := range deploy.OwnerReferences {
		if owner.Kind == "Sample" {
			q.Add(reconcile.Request{NamespacedName: types.NamespacedName{
				Name:      owner.Name,
				Namespace: evt.Meta.GetNamespace(),
			}})
		}
	}
}
```

## 监听指定字段变化

依据上文，自定义 predicate 即可实现。 比如只对 CR 改变 label 的事件感兴趣，此时可以自定义 Predicate 以及其 OnUpdate() 方法

```go
func (rl *ResourceLabelChangedPredicate) Update (e event.UpdateEvent) bool{
    _, ok1 = e.ObjectOld.(*samplev1.Sample)
    _, ok2 = e.ObjectNew.(*samplev1.Sample)
    if ok1 && ok2 {
        if !compareMaps(e.MetaOld.GetLabels(), e.MetaNew.GetLabels()) {
            return true
        }
    }
    return false
}

```

注意，当监听多个资源后， deployment 的更新事件也会进入到这个方法，所以在方法中，需要通过 `_, ok = e.Object(*xxx)` 判断资源的类型