官方文档：

- [Admission Webhook for Core Types](https://book.kubebuilder.io/reference/webhook-for-core-types.html#admission-webhook-for-core-types)

- controller-runtime example: <https://github.com/kubernetes-sigs/controller-runtime/tree/main/examples/builtins>

## controller-runtime example

`mutatingwebhook.go`

```go
package main

import (
	"context"
	"fmt"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"

	logf "sigs.k8s.io/controller-runtime/pkg/log"
)

// +kubebuilder:webhook:path=/mutate-v1-pod,mutating=true,failurePolicy=fail,groups="",resources=pods,verbs=create;update,versions=v1,name=mpod.kb.io

// podAnnotator annotates Pods
type podAnnotator struct{}

func (a *podAnnotator) Default(ctx context.Context, obj runtime.Object) error {
	log := logf.FromContext(ctx)
	pod, ok := obj.(*corev1.Pod)
	if !ok {
		return fmt.Errorf("expected a Pod but got a %T", obj)
	}

	if pod.Annotations == nil {
		pod.Annotations = map[string]string{}
	}
	pod.Annotations["example-mutating-admission-webhook"] = "foo"
	log.Info("Annotated Pod")

	return nil
}

```

`validatingwebhook.go`

```go
package main

import (
	"context"
	"fmt"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"

	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

// +kubebuilder:webhook:path=/validate-v1-pod,mutating=false,failurePolicy=fail,groups="",resources=pods,verbs=create;update,versions=v1,name=vpod.kb.io

// podValidator validates Pods
type podValidator struct{}

// validate admits a pod if a specific annotation exists.
func (v *podValidator) validate(ctx context.Context, obj runtime.Object) (admission.Warnings, error) {
	log := logf.FromContext(ctx)
	pod, ok := obj.(*corev1.Pod)
	if !ok {
		return nil, fmt.Errorf("expected a Pod but got a %T", obj)
	}

	log.Info("Validating Pod")
	key := "example-mutating-admission-webhook"
	anno, found := pod.Annotations[key]
	if !found {
		return nil, fmt.Errorf("missing annotation %s", key)
	}
	if anno != "foo" {
		return nil, fmt.Errorf("annotation %s did not have value %q", key, "foo")
	}

	return nil, nil
}

func (v *podValidator) ValidateCreate(ctx context.Context, obj runtime.Object) (admission.Warnings, error) {
	return v.validate(ctx, obj)
}

func (v *podValidator) ValidateUpdate(ctx context.Context, oldObj, newObj runtime.Object) (admission.Warnings, error) {
	return v.validate(ctx, newObj)
}

func (v *podValidator) ValidateDelete(ctx context.Context, obj runtime.Object) (admission.Warnings, error) {
	return v.validate(ctx, obj)
}
```

## kubebuilder 创建 Core Types Webhook

需要先创建项目

```bash
kubebuilder init \
  --domain kubebuilder.io \
  --repo kubebuilder.io/core-types-webhook
 
kubebuilder edit --multigroup=true
```

需要随便创建一个 crd

```bash
kubebuilder create api \
  --group batch \
  --version v1 \
  --kind CronJob \
  --controller=false \
  --resource=true

# 这里只需要 defaulting webhook
kubebuilder create webhook \
  --group batch \
  --version v1 \
  --kind CronJob \
  --defaulting
```

完成后，需要移除一些多余的代码，再参考官方文档进行修改
