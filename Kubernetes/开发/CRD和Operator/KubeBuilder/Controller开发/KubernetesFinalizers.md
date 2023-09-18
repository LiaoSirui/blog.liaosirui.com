## Finalizers 简介

Finalizers（终结器）是指示预删除操作的资源的关键。它们是控制资源上的垃圾收集，旨在提醒控制器在删除资源之前要执行那些清理操作。然而，它们不一定应该执行的代码；资源上的终结器基本知识键列表，就像注释一样。与注释一样，它们可以被操纵

下面是一个自定义 ConfigMap，包含一个终结器：

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mymap
  finalizers:
  - kubernetes
EOF
```

ConfigMap 资源控制器不理解如何处理 kubernetes 终结器键。以下是尝试删除 ConfigMap 时发生的情况：

```bash
kubectl delete configmap/mymap
```

kubernetes 会报告该对象已被删除，但是，它并没有被传统意义上的删除。相反，它正在删除过程中。当再次尝试 get 该对象时，发现该对象已被修改以及包含删除时间戳

```bash
> kubectl get configmap mymap -o yaml

kind: ConfigMap
apiVersion: v1
metadata:
  deletionTimestamp: '2023-09-18T09:03:50Z'
  resourceVersion: '19551991'
  name: mymap
  uid: 851d8016-9794-4a71-86a0-b8f989955d06
  deletionGracePeriodSeconds: 0
  creationTimestamp: '2023-09-18T09:03:46Z'
  managedFields:
    - manager: Mozilla
      operation: Update
      apiVersion: v1
      time: '2023-09-18T09:03:46Z'
      fieldsType: FieldsV1
      fieldsV1:
        'f:metadata':
          'f:finalizers':
            .: {}
            'v:"kubernetes"': {}
  namespace: default
  finalizers:
    - kubernetes

```

所发生的情况是对象被更新，而不是被删除。这是因为 kubernetes 发现该对象包含终结器并阻止从 etcd 中删除该对象。删除时间戳表明已请求删除，但在编辑对象并删除终结器之前，删除不会完成。

以下是使用 patch 命令删除终结器的演示。如果想删除一个对象，可以简单地在命令行上修补它以删除终结器

```bash
kubectl patch configmap/mymap -n default --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]'
```

这是最终的状态图

<img src=".assets/KubernetesFinalizers/vNHkZdwXUGOM4jRic7fPFXJvBuVxJyLJY4OUeuWbcHOlb6RkzBnx3by1Vtsme1Rq3S0F1Xntpvt4L5d134ETicxA.png" alt="img" style="zoom:67%;" />

因此，如果尝试删除具有终结器的对象，它将保持终结状态，直到控制器删除终结器建或使用 kubectl 删除终结器。一旦终结器列表为空，kubernetes 实际上可以回收该对象并将其放入队列中以从注册表中删除

## Reconcile 方法中使用 Finalizers

在自定义控制器 Reconcile 中注册和触发预删除钩子

```go
func (r *GuestbookReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	//...
	//...

	// 表示已请求删除
	if !guestBook.DeletionTimestamp.IsZero() {
		err := r.Client.Delete(ctx, &corev1.Pod{
			TypeMeta: metav1.TypeMeta{
				APIVersion: corev1.SchemeGroupVersion.String(),
				Kind:       "Pod",
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      guestBook.Spec.Name,
				Namespace: guestBook.Namespace,
			},
		})
		if err != nil {
			return ctrl.Result{}, err
		}
		guestBook.Finalizers = []string{}
		if err := r.Update(ctx, guestBook); err != nil {
			return ctrl.Result{}, err
		}
	}

	//...
	//...

	guestBook.Finalizers = append(guestBook.Finalizers, guestBook.Spec.Name)
	if err := r.Update(ctx, guestBook); err != nil {
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}
```

