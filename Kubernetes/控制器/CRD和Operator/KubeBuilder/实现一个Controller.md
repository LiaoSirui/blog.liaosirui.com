官方文档：

- 构建 cronjob：<https://book.kubebuilder.io/cronjob-tutorial/cronjob-tutorial.html>

## 模板项目

使用 kubebuilder 创建一个新项目

```bash
# 所有的 API 组将是 <group>.tutorial.kubebuilder.io
kubebuilder init --domain tutorial.kubebuilder.io --repo tutorial.kubebuilder.io/project
```

当自动生成一个新项目时，Kubebuilder 为提供了一些基本的模板

### 创建基础组件

首先是基本的项目文件初始化，为项目构建做好准备。

- `go.mod`: 的项目的 Go mod 配置文件，记录依赖库信息

```go
module tutorial.kubebuilder.io/project

go 1.19

require (
	k8s.io/apimachinery v0.25.0
	k8s.io/client-go v0.25.0
	sigs.k8s.io/controller-runtime v0.13.1
)

require (
	cloud.google.com/go v0.97.0 // indirect
	github.com/Azure/go-autorest v14.2.0+incompatible // indirect
	github.com/Azure/go-autorest/autorest v0.11.27 // indirect
	github.com/Azure/go-autorest/autorest/adal v0.9.20 // indirect
	github.com/Azure/go-autorest/autorest/date v0.3.0 // indirect
	github.com/Azure/go-autorest/logger v0.2.1 // indirect
	github.com/Azure/go-autorest/tracing v0.6.0 // indirect
	github.com/PuerkitoBio/purell v1.1.1 // indirect
	github.com/PuerkitoBio/urlesc v0.0.0-20170810143723-de5bf2ad4578 // indirect
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/cespare/xxhash/v2 v2.1.2 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/emicklei/go-restful/v3 v3.8.0 // indirect
	github.com/evanphx/json-patch/v5 v5.6.0 // indirect
	github.com/fsnotify/fsnotify v1.5.4 // indirect
	github.com/go-logr/logr v1.2.3 // indirect
	github.com/go-logr/zapr v1.2.3 // indirect
	github.com/go-openapi/jsonpointer v0.19.5 // indirect
	github.com/go-openapi/jsonreference v0.19.5 // indirect
	github.com/go-openapi/swag v0.19.14 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang-jwt/jwt/v4 v4.2.0 // indirect
	github.com/golang/groupcache v0.0.0-20210331224755-41bb18bfe9da // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/google/gnostic v0.5.7-v3refs // indirect
	github.com/google/go-cmp v0.5.8 // indirect
	github.com/google/gofuzz v1.1.0 // indirect
	github.com/google/uuid v1.1.2 // indirect
	github.com/imdario/mergo v0.3.12 // indirect
	github.com/josharian/intern v1.0.0 // indirect
	github.com/json-iterator/go v1.1.12 // indirect
	github.com/mailru/easyjson v0.7.6 // indirect
	github.com/matttproud/golang_protobuf_extensions v1.0.2-0.20181231171920-c182affec369 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.2 // indirect
	github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/prometheus/client_golang v1.12.2 // indirect
	github.com/prometheus/client_model v0.2.0 // indirect
	github.com/prometheus/common v0.32.1 // indirect
	github.com/prometheus/procfs v0.7.3 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	go.uber.org/atomic v1.7.0 // indirect
	go.uber.org/multierr v1.6.0 // indirect
	go.uber.org/zap v1.21.0 // indirect
	golang.org/x/crypto v0.0.0-20220315160706-3147a52a75dd // indirect
	golang.org/x/net v0.0.0-20220722155237-a158d28d115b // indirect
	golang.org/x/oauth2 v0.0.0-20211104180415-d3ed0bb246c8 // indirect
	golang.org/x/sys v0.0.0-20220722155257-8c9f86f7a55f // indirect
	golang.org/x/term v0.0.0-20210927222741-03fcf44c2211 // indirect
	golang.org/x/text v0.3.7 // indirect
	golang.org/x/time v0.0.0-20220609170525-579cf78fd858 // indirect
	gomodules.xyz/jsonpatch/v2 v2.2.0 // indirect
	google.golang.org/appengine v1.6.7 // indirect
	google.golang.org/protobuf v1.28.0 // indirect
	gopkg.in/inf.v0 v0.9.1 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
	k8s.io/api v0.25.0 // indirect
	k8s.io/apiextensions-apiserver v0.25.0 // indirect
	k8s.io/component-base v0.25.0 // indirect
	k8s.io/klog/v2 v2.70.1 // indirect
	k8s.io/kube-openapi v0.0.0-20220803162953-67bda5d908f1 // indirect
	k8s.io/utils v0.0.0-20220728103510-ee6ede2d64ed // indirect
	sigs.k8s.io/json v0.0.0-20220713155537-f223a00ba0e2 // indirect
	sigs.k8s.io/structured-merge-diff/v4 v4.2.3 // indirect
	sigs.k8s.io/yaml v1.3.0 // indirect
)

```

- `Makefile`: 用于控制器构建和部署的 Makefile 文件

```makefile

# Image URL to use all building/pushing image targets
IMG ?= controller:latest
# ENVTEST_K8S_VERSION refers to the version of kubebuilder assets to be downloaded by envtest binary.
ENVTEST_K8S_VERSION = 1.25.0

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all
all: build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: manifests
manifests: controller-gen ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
	$(CONTROLLER_GEN) rbac:roleName=manager-role crd webhook paths="./..." output:crd:artifacts:config=config/crd/bases

.PHONY: generate
generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

.PHONY: fmt
fmt: ## Run go fmt against code.
	go fmt ./...

.PHONY: vet
vet: ## Run go vet against code.
	go vet ./...

.PHONY: test
test: manifests generate fmt vet envtest ## Run tests.
	KUBEBUILDER_ASSETS="$(shell $(ENVTEST) use $(ENVTEST_K8S_VERSION) --bin-dir $(LOCALBIN) -p path)" go test ./... -coverprofile cover.out

##@ Build

.PHONY: build
build: manifests generate fmt vet ## Build manager binary.
	go build -o bin/manager main.go

.PHONY: run
run: manifests generate fmt vet ## Run a controller from your host.
	go run ./main.go

# If you wish built the manager image targeting other platforms you can use the --platform flag.
# (i.e. docker build --platform linux/arm64 ). However, you must enable docker buildKit for it.
# More info: https://docs.docker.com/develop/develop-images/build_enhancements/
.PHONY: docker-build
docker-build: test ## Build docker image with the manager.
	docker build -t ${IMG} .

.PHONY: docker-push
docker-push: ## Push docker image with the manager.
	docker push ${IMG}

# PLATFORMS defines the target platforms for  the manager image be build to provide support to multiple
# architectures. (i.e. make docker-buildx IMG=myregistry/mypoperator:0.0.1). To use this option you need to:
# - able to use docker buildx . More info: https://docs.docker.com/build/buildx/
# - have enable BuildKit, More info: https://docs.docker.com/develop/develop-images/build_enhancements/
# - be able to push the image for your registry (i.e. if you do not inform a valid value via IMG=<myregistry/image:<tag>> then the export will fail)
# To properly provided solutions that supports more than one platform you should use this option.
PLATFORMS ?= linux/arm64,linux/amd64,linux/s390x,linux/ppc64le
.PHONY: docker-buildx
docker-buildx: test ## Build and push docker image for the manager for cross-platform support
	# copy existing Dockerfile and insert --platform=${BUILDPLATFORM} into Dockerfile.cross, and preserve the original Dockerfile
	sed -e '1 s/\(^FROM\)/FROM --platform=\$$\{BUILDPLATFORM\}/; t' -e ' 1,// s//FROM --platform=\$$\{BUILDPLATFORM\}/' Dockerfile > Dockerfile.cross
	- docker buildx create --name project-v3-builder
	docker buildx use project-v3-builder
	- docker buildx build --push --platform=$(PLATFORMS) --tag ${IMG} -f Dockerfile.cross .
	- docker buildx rm project-v3-builder
	rm Dockerfile.cross

##@ Deployment

ifndef ignore-not-found
  ignore-not-found = false
endif

.PHONY: install
install: manifests kustomize ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

.PHONY: uninstall
uninstall: manifests kustomize ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config. Call with ignore-not-found=true to ignore resource not found errors during deletion.
	$(KUSTOMIZE) build config/crd | kubectl delete --ignore-not-found=$(ignore-not-found) -f -

.PHONY: deploy
deploy: manifests kustomize ## Deploy controller to the K8s cluster specified in ~/.kube/config.
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | kubectl apply -f -

.PHONY: undeploy
undeploy: ## Undeploy controller from the K8s cluster specified in ~/.kube/config. Call with ignore-not-found=true to ignore resource not found errors during deletion.
	$(KUSTOMIZE) build config/default | kubectl delete --ignore-not-found=$(ignore-not-found) -f -

##@ Build Dependencies

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Binaries
KUSTOMIZE ?= $(LOCALBIN)/kustomize
CONTROLLER_GEN ?= $(LOCALBIN)/controller-gen
ENVTEST ?= $(LOCALBIN)/setup-envtest

## Tool Versions
KUSTOMIZE_VERSION ?= v3.8.7
CONTROLLER_TOOLS_VERSION ?= v0.10.0

KUSTOMIZE_INSTALL_SCRIPT ?= "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
.PHONY: kustomize
kustomize: $(KUSTOMIZE) ## Download kustomize locally if necessary. If wrong version is installed, it will be removed before downloading.
$(KUSTOMIZE): $(LOCALBIN)
	@if test -x $(LOCALBIN)/kustomize && ! $(LOCALBIN)/kustomize version | grep -q $(KUSTOMIZE_VERSION); then \
		echo "$(LOCALBIN)/kustomize version is not expected $(KUSTOMIZE_VERSION). Removing it before installing."; \
		rm -rf $(LOCALBIN)/kustomize; \
	fi
	test -s $(LOCALBIN)/kustomize || { curl -Ss $(KUSTOMIZE_INSTALL_SCRIPT) | bash -s -- $(subst v,,$(KUSTOMIZE_VERSION)) $(LOCALBIN); }

.PHONY: controller-gen
controller-gen: $(CONTROLLER_GEN) ## Download controller-gen locally if necessary. If wrong version is installed, it will be overwritten.
$(CONTROLLER_GEN): $(LOCALBIN)
	test -s $(LOCALBIN)/controller-gen && $(LOCALBIN)/controller-gen --version | grep -q $(CONTROLLER_TOOLS_VERSION) || \
	GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

.PHONY: envtest
envtest: $(ENVTEST) ## Download envtest-setup locally if necessary.
$(ENVTEST): $(LOCALBIN)
	test -s $(LOCALBIN)/setup-envtest || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

```

- `PROJECT`: 用于生成组件的 Kubebuilder 元数据

```yaml
domain: tutorial.kubebuilder.io
layout:
- go.kubebuilder.io/v3
projectName: project
repo: tutorial.kubebuilder.io/project
version: "3"

```

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
- 默认的控制器运行时日志库 -- Zap

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
    utilruntime.Must(clientgoscheme.AddToScheme(scheme))

    //+kubebuilder:scaffold:scheme
}
```

这段代码的核心逻辑比较简单:

- 通过 flag 库解析入参设置 metrics server
- 实例化了一个 manager，它记录着所有控制器的运行情况，以及设置共享缓存和 API 服务器的客户端（注意，把的 Scheme 的信息告诉了 manager）。
- 运行 manager，它反过来运行所有的控制器和 webhooks。manager 状态被设置为 Running，直到它收到一个优雅停机 (graceful shutdown) 信号。这样一来，当在 Kubernetes 上运行时，就可以优雅地停止 pod。

```go
func main() {
	var metricsAddr string
	var enableLeaderElection bool
	var probeAddr string
	flag.StringVar(&metricsAddr, "metrics-bind-address", ":8080", "The address the metric endpoint binds to.")
	flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", "The address the probe endpoint binds to.")
	flag.BoolVar(&enableLeaderElection, "leader-elect", false,
		"Enable leader election for controller manager. "+
			"Enabling this will ensure there is only one active controller manager.")
	opts := zap.Options{
		Development: true,
	}
	opts.BindFlags(flag.CommandLine)
	flag.Parse()

	ctrl.SetLogger(zap.New(zap.UseFlagOptions(&opts)))

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme:                 scheme,
		MetricsBindAddress:     metricsAddr,
		Port:                   9443,
		HealthProbeBindAddress: probeAddr,
		LeaderElection:         enableLeaderElection,
		LeaderElectionID:       "80807133.tutorial.kubebuilder.io",
	})
	if err != nil {
		setupLog.Error(err, "unable to start manager")
		os.Exit(1)
	}
```

注意：Manager 可以通过以下方式限制控制器可以监听资源的命名空间。

```go
	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme:                 scheme,
		MetricsBindAddress:     metricsAddr,
		Port:                   9443,
		HealthProbeBindAddress: probeAddr,
		LeaderElection:         enableLeaderElection,
		LeaderElectionID:       "80807133.tutorial.kubebuilder.io",
	})
```

上面的例子将把项目改成只监听单一的命名空间。在这种情况下，建议通过将默认的 ClusterRole 和 ClusterRoleBinding 分别替换为 Role 和 RoleBinding 来限制所提供给这个命名空间的授权。

另外，也可以使用 [MultiNamespacedCacheBuilder](https://pkg.go.dev/github.com/kubernetes-sigs/controller-runtime/pkg/cache#MultiNamespacedCacheBuilder) 来监听特定的命名空间。

```go
    var namespaces []string // List of Namespaces

    mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
        Scheme:                 scheme,
        NewCache:               cache.MultiNamespacedCacheBuilder(namespaces),
        MetricsBindAddress:     fmt.Sprintf("%s:%d", metricsHost, metricsPort),
        Port:                   9443,
        HealthProbeBindAddress: probeAddr,
        LeaderElection:         enableLeaderElection,
        LeaderElectionID:       "80807133.tutorial.kubebuilder.io",
    })
```

最后的一部分：

```go
    // +kubebuilder:scaffold:builder

    if err := mgr.AddHealthzCheck("healthz", healthz.Ping); err != nil {
        setupLog.Error(err, "unable to set up health check")
        os.Exit(1)
    }
    if err := mgr.AddReadyzCheck("readyz", healthz.Ping); err != nil {
        setupLog.Error(err, "unable to set up ready check")
        os.Exit(1)
    }

    setupLog.Info("starting manager")
    if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
        setupLog.Error(err, "problem running manager")
        os.Exit(1)
    }
}
```

至此，就可以开始创建 API

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

创建一个新的 Kind 和相应的控制器

```bash
kubebuilder create api --group batch --version v1 --kind CronJob
```

当第一次为每个组-版本调用这个命令的时候，它将会为新的组-版本创建一个目录

非常简单地开始：导入`meta/v1` API 组，通常本身并不会暴露该组，而是包含所有 Kubernetes 种类共有的元数据

```go
package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)
```

下一步，为 Kind 的 Spec 和 Status 定义类型

Kubernetes 功能通过使期待的状态 (`Spec`) 和实际集群状态 (其他对象的 `Status`)保 持一致和外部状态，然后记录观察到的状态(`Status`)

因此，每个 *functional* 对象包括 spec 和 status

很少的类型，像 `ConfigMap` 不需要遵从这个模式，因为它们不编码期待的状态， 但是大部分类型需要做这一步

```go
// CronJobSpec defines the desired state of CronJob
type CronJobSpec struct {
	// INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
	// Important: Run "make" to regenerate code after modifying this file

	// Foo is an example field of CronJob. Edit cronjob_types.go to remove/update
	Foo string `json:"foo,omitempty"`
}

// CronJobStatus defines the observed state of CronJob
type CronJobStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
}

```

下一步，我们定义与实际种类相对应的类型，`CronJob` 和 `CronJobList`

- `CronJob` 是一个根类型, 它描述了 `CronJob` 种类。像所有 Kubernetes 对象，它包含 `TypeMeta` (描述了API版本和种类)，也包含其中拥有像名称,名称空间和标签的东西的 `ObjectMeta`

- `CronJobList` 只是多个 `CronJob` 的容器。它是批量操作中使用的种类，像 LIST

```go
//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// CronJob is the Schema for the cronjobs API
type CronJob struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   CronJobSpec   `json:"spec,omitempty"`
	Status CronJobStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// CronJobList contains a list of CronJob
type CronJobList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CronJob `json:"items"`
}
```

最后，我们将这个 Go 类型添加到 API 组中。这允许我们将这个 API 组中的类型可以添加到任何 [Scheme](https://pkg.go.dev/k8s.io/apimachinery/pkg/runtime?tab=doc#Scheme)。

```go
func init() {
	SchemeBuilder.Register(&CronJob{}, &CronJobList{})
}
```

## 设计一个 API

设计 API 有一些原则

- 所有序列化的字段**必须**是 `驼峰式` ，所以使用的 JSON 标签需要遵循该格式

- 字段可以使用大多数的基本类型
  - 数字是个例外：出于 API 兼容性的目的，我们只允许三种数字类型。对于整数，需要使用 `int32` 和 `int64` 类型；对于小数，使用 `resource.Quantity` 类型

`Quantity` 是十进制数的一种特殊符号，它有一个明确固定的表示方式，使它们在不同的机器上更具可移植性

它们在概念上的工作原理类似于浮点数：它们有一个 significand、基数和指数。它们的序列化和人类可读格式使用整数和后缀来指定值，就像我们描述计算机存储的方式一样

例如，值 `2m` 在十进制符号中表示 `0.002`。 `2Ki` 在十进制中表示 `2048` ，而 `2K` 在十进制中表示 `2000`。 如果我们要指定分数，我们就换成一个后缀，让我们使用一个整数：`2.5` 就是 `2500m`

有两个支持的基数：10 和 2（分别称为十进制和二进制）

- 十进制基数用 “普通的” SI 后缀表示（如 `M` 和 `K` ）
- 二进制基数用 “mebi” 符号表示（如 `Mi` 和 `Ki` ）

还有一个我们使用的特殊类型：`metav1.Time`。 它有一个稳定的、可移植的序列化格式的功能，其他与 `time.Time` 相同。

### CronJob 对象

CronJob 对象：

```go
package v1

import (
	batchv1beta1 "k8s.io/api/batch/v1beta1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)
```

先看看 spec。正如我们之前讨论过的，spec 代表所期望的状态，所以控制器的任何 “输入” 都会在这里。

通常来说，CronJob 由以下几部分组成：

- 一个时间表（ CronJob 中的 cron ）

```go
Schedule string `json:"schedule"`
```

- 要运行的 Job 模板（ CronJob 中的 Job ）

```go
JobTemplate batchv1beta1.JobTemplateSpec `json:"jobTemplate"`
```

当然 CronJob 还需要一些额外的东西，使得它更加易用

- 一个已经启动的 Job 的超时时间（如果该 Job 执行超时，那么我们会将在下次调度的时候重新执行该 Job）

```bash
StartingDeadlineSeconds *int64 `json:"startingDeadlineSeconds,omitempty"`
```

- 如果多个 Job 同时运行，该怎么办（我们要等待吗？还是停止旧的 Job ？）

```basj
ConcurrencyPolicy ConcurrencyPolicy `json:"concurrencyPolicy,omitempty"`
```

- 暂停 CronJob 运行的方法，以防出现问题

```bas
Suspend *bool `json:"suspend,omitempty"`
```

- 对旧 Job 历史的限制

```bash
SuccessfulJobsHistoryLimit *int32 `json:"successfulJobsHistoryLimit,omitempty"`
FailedJobsHistoryLimit *int32 `json:"failedJobsHistoryLimit,omitempty"`
```

请记住，由于从不读取自己的状态，需要有一些其他的方法来跟踪一个 Job 是否已经运行。可以使用至少一个旧的 Job 来做这件事。

我们将使用几个标记（`// +comment`）来指定额外的元数据。在生成 CRD 清单时，[controller-tools](https://github.com/kubernetes-sigs/controller-tools) 将使用这些数据。我们稍后将看到，controller-tools 也将使用 GoDoc 来生成字段的描述

```go

// CronJobSpec defines the desired state of CronJob
type CronJobSpec struct {
	// +kubebuilder:validation:MinLength=0

	// The schedule in Cron format, see https://en.wikipedia.org/wiki/Cron.
	Schedule string `json:"schedule"`

	// +kubebuilder:validation:Minimum=0

	// Optional deadline in seconds for starting the job if it misses scheduled
	// time for any reason.  Missed jobs executions will be counted as failed ones.
	// +optional
	StartingDeadlineSeconds *int64 `json:"startingDeadlineSeconds,omitempty"`

	// Specifies how to treat concurrent executions of a Job.
	// Valid values are:
	// - "Allow" (default): allows CronJobs to run concurrently;
	// - "Forbid": forbids concurrent runs, skipping next run if previous run hasn't finished yet;
	// - "Replace": cancels currently running job and replaces it with a new one
	// +optional
	ConcurrencyPolicy ConcurrencyPolicy `json:"concurrencyPolicy,omitempty"`

	// This flag tells the controller to suspend subsequent executions, it does
	// not apply to already started executions.  Defaults to false.
	// +optional
	Suspend *bool `json:"suspend,omitempty"`

	// Specifies the job that will be created when executing a CronJob.
	JobTemplate batchv1beta1.JobTemplateSpec `json:"jobTemplate"`

	// +kubebuilder:validation:Minimum=0

	// The number of successful finished jobs to retain.
	// This is a pointer to distinguish between explicit zero and not specified.
	// +optional
	SuccessfulJobsHistoryLimit *int32 `json:"successfulJobsHistoryLimit,omitempty"`

	// +kubebuilder:validation:Minimum=0

	// The number of failed finished jobs to retain.
	// This is a pointer to distinguish between explicit zero and not specified.
	// +optional
	FailedJobsHistoryLimit *int32 `json:"failedJobsHistoryLimit,omitempty"`
}

```

定义了一个自定义类型来保存我们的并发策略。实际上，它的底层类型是 string，但该类型给出了额外的文档，并允许我们在类型上附加验证，而不是在字段上验证，使验证逻辑更容易复用。

```go
// ConcurrencyPolicy describes how the job will be handled.
// Only one of the following concurrent policies may be specified.
// If none of the following policies is specified, the default one
// is AllowConcurrent.
// +kubebuilder:validation:Enum=Allow;Forbid;Replace
type ConcurrencyPolicy string

const (
	// AllowConcurrent allows CronJobs to run concurrently.
	AllowConcurrent ConcurrencyPolicy = "Allow"

	// ForbidConcurrent forbids concurrent runs, skipping next run if previous
	// hasn't finished yet.
	ForbidConcurrent ConcurrencyPolicy = "Forbid"

	// ReplaceConcurrent cancels currently running job and replaces it with a new one.
	ReplaceConcurrent ConcurrencyPolicy = "Replace"
)
```

接下来，设计一下 status，它表示实际看到的状态。它包含了希望用户或其他控制器能够轻松获得的任何信息。

将保存一个正在运行的 Jobs，以及最后一次成功运行 Job 的时间。

注意，使用 `metav1.Time` 而不是 `time.Time` 来保证序列化的兼容性以及稳定性，如上所述。

```go
// CronJobStatus defines the observed state of CronJob
type CronJobStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file

	// A list of pointers to currently running jobs.
	// +optional
	Active []corev1.ObjectReference `json:"active,omitempty"`

	// Information when was the last time the job was successfully scheduled.
	// +optional
	LastScheduleTime *metav1.Time `json:"lastScheduleTime,omitempty"`
}

```

最后，CronJob 和 CronJobList 直接使用模板生成的即可

如前所述，不需要改变这个，除了标记想要一个有状态子资源，这样行为就像内置的 kubernetes 类型

```go
//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// CronJob is the Schema for the cronjobs API
type CronJob struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   CronJobSpec   `json:"spec,omitempty"`
	Status CronJobStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// CronJobList contains a list of CronJob
type CronJobList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CronJob `json:"items"`
}

```

### groupversion_info.go

`groupversion_info.go` 包含了关于 group-version 的一些元数据

首先，我们有一些包级别的标记的，表示存在这个包中的 Kubernetes 对象，并且这个包表示 `batch.tutorial.kubebuilder.io` 组

object 生成器使用前者，而后者是由 CRD 生成器来生成的，它会从这个包创建 CRD 的元数据。

```go
// Package v1 contains API Schema definitions for the batch v1 API group
// +kubebuilder:object:generate=true
// +groupName=batch.tutorial.kubebuilder.io
package v1

import (
	"k8s.io/apimachinery/pkg/runtime/schema"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

```

然后，有一些常见且常用的变量来帮助设置 Scheme

因为需要在这个包的 controller 中用到所有的类型， 用一个方便的方法给其他 `Scheme` 来添加所有的类型，是非常有用的(而且也是一种惯例)

SchemeBuilder 能够帮助我们轻松的实现这个事情

```go
var (
	// GroupVersion is group version used to register these objects
	GroupVersion = schema.GroupVersion{Group: "batch.tutorial.kubebuilder.io", Version: "v1"}

	// SchemeBuilder is used to add go types to the GroupVersionKind scheme
	SchemeBuilder = &scheme.Builder{GroupVersion: GroupVersion}

	// AddToScheme adds the types in this group-version to the given scheme.
	AddToScheme = SchemeBuilder.AddToScheme
)

```

### zz_generated.deepcopy.go

`zz_generated.deepcopy.go` 包含了前述 `runtime.Object` 接口的自动实现，这些实现标记了代表 `Kinds` 的所有根类型

`runtime.Object` 接口的核心是一个深拷贝方法，即 `DeepCopyObject`

controller-tools 中的 `object` 生成器也能够为每一个根类型以及其子类型生成另外两个易用的方法：`DeepCopy` 和 `DeepCopyInto`

## 控制器简介

控制器是 Kubernetes 的核心，也是任何 operator 的核心。

控制器的工作是确保对于任何给定的对象，世界的实际状态（包括集群状态，以及潜在的外部状态，如 Kubelet 的运行容器或云提供商的负载均衡器）与对象中的期望状态相匹配。每个控制器专注于一个根 Kind，但可能会与其他 Kind 交互。

我们把这个过程称为 **reconciling**。

在 controller-runtime 中，为特定种类实现 reconciling 的逻辑被称为 [*Reconciler*](https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/reconcile)。 Reconciler 接受一个对象的名称，并返回我们是否需要再次尝试（例如在错误或周期性控制器的情况下，如 HorizontalPodAutoscaler）。

首先，我们从一些标准的 import 开始。和之前一样，我们需要核心 controller-runtime 运行库，以及 client 包和我们的 API 类型包。

```go
package controllers

import (
	"context"

	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	batchv1 "tutorial.kubebuilder.io/project/api/v1"
)

```

接下来，kubebuilder 为我们搭建了一个基本的 reconciler 结构

Client 和 Scheme 确保我们可以获取对象

```go
// CronJobReconciler reconciles a CronJob object
type CronJobReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}

```

标记

- 大部分的控制器最终都要运行在 k8s 集群中，因此提供了用于声明 RBAC 权限的标记

Reconcile 函数

- `Reconcile` 实际上是对单个对象进行调谐，Request 只是有一个名字，但可以使用 client 从缓存中获取这个对象

- 大多数控制器需要一个日志句柄，所以在 Reconcile 中将他们初始化；controller-runtime 通过一个名为 logr 的库使用结构化的日志记录

返回值

- 返回一个空的结果，没有错误，这就向 controller-runtime 表明我们已经成功地对这个对象进行了调谐，在有一些变化之前不需要再尝试调谐

```go
//+kubebuilder:rbac:groups=batch.tutorial.kubebuilder.io,resources=cronjobs,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=batch.tutorial.kubebuilder.io,resources=cronjobs/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=batch.tutorial.kubebuilder.io,resources=cronjobs/finalizers,verbs=update

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the CronJob object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.13.1/pkg/reconcile
func (r *CronJobReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	_ = log.FromContext(ctx)

	// TODO(user): your logic here

	return ctrl.Result{}, nil
}

```

最后，将 Reconcile 添加到 manager 中，这样当 manager 启动时它就会被启动。

现在，这个 Reconcile 是在 `CronJob` 上运行的。以后，我们也会用这个来标记其他的对象。

```go
// SetupWithManager sets up the controller with the Manager.
func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&batchv1.CronJob{}).
		Complete(r)
}

```

## 实现一个控制器

CronJob 控制器的基本逻辑如下:

1. 根据名称加载定时任务
2. 列出所有有效的 job，更新其状态
3. 根据保留的历史版本数清理版本过旧的 job
4. 检查当前 CronJob 是否被挂起(如果被挂起，则不执行任何操作)
5. 计算 job 下一个定时执行时间
6. 如果 job 符合执行时机，没有超出截止时间，且不被并发策略阻塞，执行该 job
7. 当任务进入运行状态或到了下一次执行时间， job 重新排队

开始编码之前，先引进基本的依赖，除此之外还需要一些额外的依赖库

```go
```



## 实现 defaulting/validating webhooks
