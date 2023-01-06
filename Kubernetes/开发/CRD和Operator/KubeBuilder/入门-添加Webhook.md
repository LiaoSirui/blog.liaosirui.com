https://juejin.cn/post/7132752189646667784

如果希望本地运行 webhook，需要放置证书 `/tmp/k8s-webhook-server/serving-certs/tls.{crt,key}`

使用如下命令签发一个证书

```bash
mkcd /tmp/k8s-webhook-server/serving-certs/
```

## 准入控制器简介

准入控制器是在对象持久化之前用于对 Kubernetes API Server 的请求进行拦截的代码段，在请求经过身份验证和授权之后放行通过

时序图如下所示：

<img src=".assets/image-20230106184811477.png" alt="image-20230106184811477" style="zoom: 80%;" />

准入控制存在两种 WebHook

- 变更准入控制 MutatingAdmissionWebhook：Mutating 控制器可以修改他们处理的资源对象
- 验证准入控制 ValidatingAdmissionWebhook：如果任何一个阶段中的任何控制器拒绝了请求，则会立即拒绝整个请求，并将错误返回给最终的用户

执行的顺序是先执行 MutatingAdmissionWebhook 再执行 ValidatingAdmissionWebhook

<img src=".assets/image-20230106184732677.png" alt="image-20230106184732677" style="zoom:50%;" />

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
	DefaultImage = "dockerhub.bigquant.ai:5000/dockerstacks/rocky-kbdev:master_latest"
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

## 本地调试

创建的 webhook 默认使用的 service 的方式访问 webhook server，这需要将 webhook 部署到 k8s 上才能工作

对于开发的初级阶段，往往需要在反复修改调试代码，每次将 webhook 部署到 k8s 上很不方便

在使用 Kubebuilder 开发 Kubernetes Operator 的时候，通过在本地直接运行 Operator 进行功能调试往往更为方便、效率

一般情况下开发者仅需要执行 `make run` 即可在本地运行 Operator。但是当 Operator 启用了 webhook 服务时，就需要对配置内容进行一些调整，才能使 Operator 在本地正常运行

### 原理

webhook 分别为两部分

- 其一是能够处理 https 请求的 web 服务器，以及 webhook 请求的处理程序；
- 其二是在 k8s 上声明哪些资源对象状态变化需要调用 webhook 请求，该功能通过创建 mutatingwebhookconfigurations 和 validatingwebhookconfigurations 实现

所以原理上 web 服务器可以本地节点启动，然后修改 k8s 上的 webhook 配置，使其将请求发送给本地的 web 服务器

需要完成三个步骤：

- 生成认证证书，包括服务端和客户端，证书中必须包含本地节点的地址或域名
- 使用认证证书，在本地启动 webhook 的服务端程序；
- 在 k8s 创建 `MutatingAdmissionWebhook` 和 `ValidatingWebhookConfiguration` 对象，指定使用本地 webhook 服务，其中 clientConfig 字段指定为本地地址，例如：<https://192.168.56.200:9443/...>

### 配置变更

为了和原本的开发体验保持一致，所以利用 kustomize 的特性新建一个 `config/overlay/dev` 文件夹，包含文件修改想要的配置

```bash
mkdir -p config/overlay/dev
```

先看一下 `kustomization.yaml`，从其他文件夹中继承配置，然后使用 patches 修改一些配置

```yaml
namespace: kbdev-operator-system

namePrefix: kbdev-operator-

bases:
# - ../../crd
# - ../../rbac
# - ../../certmanager
# - ../../webhook

patchesStrategicMerge:
# ...
```

为了方便调试，在 makefile 中添加

```makefile
.PHONY: dev
dev: manifests kustomize
	$(KUSTOMIZE) build config/overlays/dev | kubectl apply -f -

```

### 生成证书

用 Kubernetes 的认证证书管理插件 cert-manager，生成所需的认证证书

下述文件会自动生成在 `config/certmanager` 文件夹中：

```yaml
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  labels:
    app.kubernetes.io/name: issuer
    app.kubernetes.io/instance: selfsigned-issuer
    app.kubernetes.io/component: certificate
    app.kubernetes.io/created-by: kbdev-operator
    app.kubernetes.io/part-of: kbdev-operator
    app.kubernetes.io/managed-by: kustomize
  name: selfsigned-issuer
  namespace: system
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  labels:
    app.kubernetes.io/name: certificate
    app.kubernetes.io/instance: serving-cert
    app.kubernetes.io/component: certificate
    app.kubernetes.io/created-by: kbdev-operator
    app.kubernetes.io/part-of: kbdev-operator
    app.kubernetes.io/managed-by: kustomize
  name: serving-cert  # this name should match the one appeared in kustomizeconfig.yaml
  namespace: system
spec:
  # $(SERVICE_NAME) and $(SERVICE_NAMESPACE) will be substituted by kustomize
  dnsNames:
  - $(SERVICE_NAME).$(SERVICE_NAMESPACE).svc
  - $(SERVICE_NAME).$(SERVICE_NAMESPACE).svc.cluster.local
  issuerRef:
    kind: Issuer
    name: selfsigned-issuer
  secretName: webhook-server-cert # this secret will not be prefixed, since it's not managed by kustomize

```

证书中需要增加本地服务的地址

```yaml
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    labels:
      app.kubernetes.io/name: certificate
      app.kubernetes.io/instance: serving-cert
      app.kubernetes.io/component: certificate
      app.kubernetes.io/created-by: kbdev-operator
      app.kubernetes.io/part-of: kbdev-operator
      app.kubernetes.io/managed-by: kustomize
    name: serving-cert  # this name should match the one appeared in kustomizeconfig.yaml
    namespace: system
  spec:
    # $(SERVICE_NAME) and $(SERVICE_NAMESPACE) will be substituted by kustomize
    dnsNames:
    - $(SERVICE_NAME).$(SERVICE_NAMESPACE).svc
    - $(SERVICE_NAME).$(SERVICE_NAMESPACE).svc.cluster.local
++  ipAddresses:
++  - 10.244.244.101
    issuerRef:
      kind: Issuer
      name: selfsigned-issuer
    secretName: webhook-server-cert # this secret will not be prefixed, since it's not managed by kustomize

```

因此编写 patch 文件 `config/overlays/dev/certificate_patch.yaml`

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: serving-cert  # this name should match the one appeared in kustomizeconfig.yaml
  namespace: system
spec:
  ipAddresses:
  - 10.244.244.101

```

更改 `config/overlays/dev/kustomization.yaml`

```yaml
namespace: kbdev-operator-system

namePrefix: kbdev-operator-

bases:
# - ../../crd
# - ../../rbac
- ../../certmanager
# - ../../webhook

patchesStrategicMerge:
- certificate_patch.yaml

```

之后执行 make dev 生成相关的配置文件以及完成安装

```bash
> make dev
/code/bigquant/aipaas-devops/kbdev-operator/bin/controller-gen rbac:roleName=manager-role crd webhook paths="./..." output:crd:artifacts:config=config/crd/bases
/code/bigquant/aipaas-devops/kbdev-operator/bin/kustomize build config/overlays/dev | kubectl apply -f -
certificate.cert-manager.io/kbdev-operator-serving-cert created
issuer.cert-manager.io/kbdev-operator-selfsigned-issuer created

```

此时，需要在本地准备 tls.key 和 tls.crt 文件，用于 apiserver 与 webhook 之间的通信：

可以直接从 secret 资源中找到；生成的 `tls.*` 文件需要存放在 `/tmp/k8s-webhook-server/serving-certs` 路径下

```bash
mkcd /tmp/k8s-webhook-server/serving-certs

kubectl get secret -n kbdev-operator-system webhook-server-cert -o=jsonpath='{.data.tls\.crt}' |base64 -d > tls.crt

kubectl get secret -n kbdev-operator-system webhook-server-cert -o=jsonpath='{.data.tls\.key}' |base64 -d > tls.key
```


### 使用 url 而非 service 触发 webhook

生成的 webhook 在 `config/webhook` 目录下，`config/webhook/manifests.yaml`

```yaml
---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  creationTimestamp: null
  name: mutating-webhook-configuration
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    service:
      name: webhook-service
      namespace: system
      path: /mutate-devops-aipaas-io-v1-kbdev
  failurePolicy: Fail
  name: mkbdev.kb.io
  rules:
  - apiGroups:
    - devops.aipaas.io
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - kbdevs
  sideEffects: None
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  creationTimestamp: null
  name: validating-webhook-configuration
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    service:
      name: webhook-service
      namespace: system
      path: /validate-devops-aipaas-io-v1-kbdev
  failurePolicy: Fail
  name: vkbdev.kb.io
  rules:
  - apiGroups:
    - devops.aipaas.io
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - kbdevs
  sideEffects: None

```

本地调试时，需要将 Dynamic Admission Control 的地址调整为本地地址（代替原本的 svc），即如：`https://<node-ip>:9443` （webhook 默认端口为 9443）

> 在配置了 cert-manager 的情况下，caBundle 由 cert-manager 自动生成

对应修改为：

```yaml
---
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  creationTimestamp: null
  name: mutating-webhook-configuration
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    # service:
    #   name: webhook-service
    #   namespace: system
    #   path: /mutate-devops-aipaas-io-v1-kbdev
    # 新增 url 字段
    url: https://10.244.244.101:9443/mutate-devops-aipaas-io-v1-kbdev
  failurePolicy: Fail
  name: mkbdev.kb.io
  rules:
  - apiGroups:
    - devops.aipaas.io
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - kbdevs
  sideEffects: None
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  creationTimestamp: null
  name: validating-webhook-configuration
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    # service:
    #   name: webhook-service
    #   namespace: system
    #   path: /validate-devops-aipaas-io-v1-kbdev
    # 新增 url 字段
    url: https://10.244.244.101:9443/validate-devops-aipaas-io-v1-kbdev
  failurePolicy: Fail
  name: vkbdev.kb.io
  rules:
  - apiGroups:
    - devops.aipaas.io
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - kbdevs
  sideEffects: None

```

因此执行如下的方式进行新增





在 CRD 的 patch 中也需要调整 webhook 的地址，文件在 `config/crd/patches/webhook_in_kbdevs.yaml`：

```yaml
# The following patch enables a conversion webhook for the CRD
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: kbdevs.devops.aipaas.io
spec:
  conversion:
    strategy: Webhook
    webhook:
      clientConfig:
        service:
          namespace: system
          name: webhook-service
          path: /convert
      conversionReviewVersions:
      - v1

```

同时需要在 `config/webhook/kustomizeconfig.yaml` 中注释掉 svc 的配置：

```yaml
# the following config is for teaching kustomize where to look at when substituting vars.
# It requires kustomize v2.1.0 or newer to work properly.
nameReference:
- kind: Service
  version: v1
  fieldSpecs:
  # - kind: MutatingWebhookConfiguration
  #   group: admissionregistration.k8s.io
  #   path: webhooks/clientConfig/service/name
  # - kind: ValidatingWebhookConfiguration
  #   group: admissionregistration.k8s.io
  #   path: webhooks/clientConfig/service/name

namespace:
# - kind: MutatingWebhookConfiguration
#   group: admissionregistration.k8s.io
#   path: webhooks/clientConfig/service/namespace
#   create: true
# - kind: ValidatingWebhookConfiguration
#   group: admissionregistration.k8s.io
#   path: webhooks/clientConfig/service/namespace
#   create: true

varReference:
- path: metadata/annotations

```


### 启动服务

最后使用 make run 启动服务。

现在就可以在本地调试 Operator 的 webhook 功能了。
