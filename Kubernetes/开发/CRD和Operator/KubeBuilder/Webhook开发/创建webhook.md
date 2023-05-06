## 创建 webhook

通过命令创建相关的脚手架代码和 api

```bash
kubebuilder create webhook \
  --group devops \
  --version v1 \
  --kind KBDev \
  --defaulting \
  --programmatic-validation
```

执行之后可以看到多了一些 webhook 相关的文件和配置

```bash
  ├── api
  │   └── v1
  │       ├── groupversion_info.go
  ...
+ │       ├── nodepool_webhook.go # 在这里实现 webhook 的相关接口
+ │       ├── webhook_suite_test.go # webhook 测试
  │       └── zz_generated.deepcopy.go
  ├── bin
  ├── config
+ │   ├── certmanager # 用于部署证书
  │   ├── crd
  ...
  │   ├── default
  │   │   ├── kustomization.yaml
  │   │   ├── manager_auth_proxy_patch.yaml
  │   │   ├── manager_config_patch.yaml
+ │   │   ├── manager_webhook_patch.yaml
+ │   │   └── webhookcainjection_patch.yaml
  │   ├── manager
  │   ├── prometheus
  │   ├── rbac
  ...
+ │   └── webhook # webhook 部署配置
  ├── controllers
  ├── main.go
```

### webhook 的入口

```go
package v1

import (
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
)

// log is for logging in this package.
var kbdevlog = logf.Log.WithName("kbdev-resource")

func (r *KBDev) SetupWebhookWithManager(mgr ctrl.Manager) error {
	return ctrl.NewWebhookManagedBy(mgr).
		For(r).
		Complete()
}

//+kubebuilder:webhook:path=/mutate-devops-aipaas-io-v1-kbdev,mutating=true,failurePolicy=fail,sideEffects=None,groups=devops.aipaas.io,resources=kbdevs,verbs=create;update,versions=v1,name=mkbdev.kb.io,admissionReviewVersions=v1

var _ webhook.Defaulter = &KBDev{}

const (
	DefaultImage = "dockerstacks/rocky-kbdev:master_latest"
)

// Default implements webhook.Defaulter so a webhook will be registered for the type
func (r *KBDev) Default() {

	kbdevlog.Info("default", "name", r.Name)

}

//+kubebuilder:webhook:path=/validate-devops-aipaas-io-v1-kbdev,mutating=false,failurePolicy=fail,sideEffects=None,groups=devops.aipaas.io,resources=kbdevs,verbs=create;update,versions=v1,name=vkbdev.kb.io,admissionReviewVersions=v1

var _ webhook.Validator = &KBDev{}

// ValidateCreate implements webhook.Validator so a webhook will be registered for the type
func (r *KBDev) ValidateCreate() error {
	kbdevlog.Info("validate create", "name", r.Name)

	return nil
}

// ValidateUpdate implements webhook.Validator so a webhook will be registered for the type
func (r *KBDev) ValidateUpdate(old runtime.Object) error {
	kbdevlog.Info("validate update", "name", r.Name)

	return nil
}

// ValidateDelete implements webhook.Validator so a webhook will be registered for the type
func (r *KBDev) ValidateDelete() error {
	kbdevlog.Info("validate delete", "name", r.Name)

	return nil
}

```

### webhook 注册的原理

调用 `ctrl.NewWebhookManagedBy(mgr).For(r).Complete()` 注册 webhook

代码：`"sigs.k8s.io/controller-runtime/pkg/builder/webhook/webhook.go"`

```go
// Complete builds the webhook.
func (blder *WebhookBuilder) Complete() error {
	// Set the Config
	blder.loadRestConfig()

	// Set the Webhook if needed
	return blder.registerWebhooks()
}

func (blder *WebhookBuilder) registerWebhooks() error {
	typ, err := blder.getType()
	if err != nil {
		return err
	}

	// Create webhook(s) for each type
	blder.gvk, err = apiutil.GVKForObject(typ, blder.mgr.GetScheme())
	if err != nil {
		return err
	}

	blder.registerDefaultingWebhook() // 注册 mutate webhook
	blder.registerValidatingWebhook() // 注册 validate webhook

	err = blder.registerConversionWebhook() // 注册 conversion webhook
	if err != nil {
		return err
	}
	return nil
}

```

注册 webhook 的服务路径

在 mutate 和 validate webhook 的注册中，controller-runtime 通过以下规则生成 path

```go
func generateMutatePath(gvk schema.GroupVersionKind) string {
	return "/mutate-" + strings.ReplaceAll(gvk.Group, ".", "-") + "-" +
		gvk.Version + "-" + strings.ToLower(gvk.Kind)
}

func generateValidatePath(gvk schema.GroupVersionKind) string {
	return "/validate-" + strings.ReplaceAll(gvk.Group, ".", "-") + "-" +
		gvk.Version + "-" + strings.ToLower(gvk.Kind)
}
```

在 conversion webhook 的注册中，controller-runtime 通过以下规则生成 path

即 conversion webhook 必须使用 `/convert` 作为服务路径；同时如果有多个资源需要 conversion，仅需要注册一次即可

```go
func (blder *WebhookBuilder) registerConversionWebhook() error {
	ok, err := conversion.IsConvertible(blder.mgr.GetScheme(), blder.apiType)
	if err != nil {
		log.Error(err, "conversion check failed", "GVK", blder.gvk)
		return err
	}
	if ok {
		if !blder.isAlreadyHandled("/convert") {
			blder.mgr.GetWebhookServer().Register("/convert", &conversion.Webhook{})
		}
		log.Info("Conversion webhook enabled", "GVK", blder.gvk)
	}

	return nil
}
```

注册的具体逻辑

代码：`"sigs.k8s.io/controller-runtime/pkg/webhook/server.go"`

```go
// Register marks the given webhook as being served at the given path.
// It panics if two hooks are registered on the same path.
func (s *Server) Register(path string, hook http.Handler) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.defaultingOnce.Do(s.setDefaults)
	if _, found := s.webhooks[path]; found {
		panic(fmt.Errorf("can't register duplicate path: %v", path))
	}
	// TODO(directxman12): call setfields if we've already started the server
	s.webhooks[path] = hook
	s.WebhookMux.Handle(path, metrics.InstrumentedHook(path, hook))

	regLog := log.WithValues("path", path)
	regLog.Info("Registering webhook")

	// we've already been "started", inject dependencies here.
	// Otherwise, InjectFunc will do this for us later.
	if s.setFields != nil {
		if err := s.setFields(hook); err != nil {
			// TODO(directxman12): swallowing this error isn't great, but we'd have to
			// change the signature to fix that
			regLog.Error(err, "unable to inject fields into webhook during registration")
		}

		baseHookLog := log.WithName("webhooks")

		// NB(directxman12): we don't propagate this further by wrapping setFields because it's
		// unclear if this is how we want to deal with log propagation.  In this specific instance,
		// we want to be able to pass a logger to webhooks because they don't know their own path.
		if _, err := inject.LoggerInto(baseHookLog.WithValues("webhook", path), hook); err != nil {
			regLog.Error(err, "unable to logger into webhook during registration")
		}
	}
}

```

### 启用 webhook

然后在 main.go 中需要匹配正确的 webhook 入口：

```go
	if os.Getenv("ENABLE_WEBHOOKS") != "false" {
		if err = (&devopsv1.KBDev{}).SetupWebhookWithManager(mgr); err != nil {
			setupLog.Error(err, "unable to create webhook", "webhook", "KBDev")
			os.Exit(1)
		}
	}

```

## 实现逻辑

### 实现 MutatingAdmissionWebhook 接口

这个只需要实现 Default 方法就行

```go
// Default implements webhook.Defaulter so a webhook will be registered for the type
func (r *KBDev) Default() {

	kbdevlog.Info("default", "name", r.Name)

}

```

### 实现 ValidatingAdmissionWebhook 接口

实现 `ValidatingAdmissionWebhook`也是一样只需要实现对应的方法就行了，默认是注册了 Create 和 Update 事件的校验

```go
//+kubebuilder:webhook:path=/validate-devops-aipaas-io-v1-kbdev,mutating=false,failurePolicy=fail,sideEffects=None,groups=devops.aipaas.io,resources=kbdevs,verbs=create;update,versions=v1,name=vkbdev.kb.io,admissionReviewVersions=v1

var _ webhook.Validator = &KBDev{}

// ValidateCreate implements webhook.Validator so a webhook will be registered for the type
func (r *KBDev) ValidateCreate() error {
	kbdevlog.Info("validate create", "name", r.Name)

	return nil
}

// ValidateUpdate implements webhook.Validator so a webhook will be registered for the type
func (r *KBDev) ValidateUpdate(old runtime.Object) error {
	kbdevlog.Info("validate update", "name", r.Name)

	return nil
}

// ValidateDelete implements webhook.Validator so a webhook will be registered for the type
func (r *KBDev) ValidateDelete() error {
	kbdevlog.Info("validate delete", "name", r.Name)

	return nil
}

```

