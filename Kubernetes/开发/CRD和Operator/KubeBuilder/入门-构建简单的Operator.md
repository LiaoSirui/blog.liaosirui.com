
## 简介

Kubebuilder 是一个基于 CRD 来构建 Kubernetes API 的框架，可以使用 CRD 来构建 API、Controller 和 Admission Webhook

### 动机

目前扩展 Kubernetes 的 API 的方式有创建 CRD、使用 Operator SDK 等方式，都需要写很多的样本文件（boilerplate），使用起来十分麻烦

为了能够更方便构建 Kubernetes API 和工具，就需要一款能够事半功倍的工具，与其他 Kubernetes API 扩展方案相比，kubebuilder 更加简单易用，并获得了社区的广泛支持

### 设计哲学

Kubebuilder 提供基于简洁的精心设计的示例 godoc 来提供整洁的库抽象

1. 能使用 go 接口和库，就不使用代码生成
1. 能使用代码生成，就不用使用多于一次的存根初始化
1. 能使用一次存根，就不 fork 和修改 boilerplate
1. 绝不 fork 和修改 boilerplate

<img src=".assets/image-20221222163422951.png" alt="image-20221222163422951" style="zoom: 67%;" />

## 工作流程

Kubebuilder 的工作流程如下：

1. 创建一个新的工程目录
1. 创建一个或多个资源 API CRD 然后将字段添加到资源
1. 在控制器中实现协调循环（reconcile loop），watch 额外的资源
1. 在集群中运行测试（自动安装 CRD 并自动启动控制器）
1. 更新引导集成测试测试新字段和业务逻辑
1. 使用用户提供的 Dockerfile 构建和发布容器

## 使用 kubebuilder 创建 Kubernetes Operator 的示例

前提：准备 kubernetes 集群

名词：

- CRD：自定义资源定义，Kubernetes 中的资源类型。
- CR：Custom Resource，对使用 CRD 创建出来的自定义资源的统称。

### 安装 Kubebuilder

详见：<https://book.kubebuilder.io/quick-start.html#installation>

### 创建项目

首先将使用自动配置创建一个项目，该项目在创建 CR 时不会触发任何资源生成

在项目路径下使用下面的命令初始化项目

```bash
mkdir test-prj && cd test-prj

kubebuilder init --domain code.liaosirui.com \
 --repo code.liaosirui.com/srliao/test-prj
# --domain string  domain for groups (default "my.domain")
# --repo string    name to use for go module (e.g., github.com/user/repo), defaults to the go package of the current working directory.
```

生成后会有如下提示

```bash
Writing kustomize manifests for you to edit...
Writing scaffold for you to edit...
Get controller runtime:
$ go get sigs.k8s.io/controller-runtime@v0.12.1
Update dependencies:
$ go mod tidy
Next: define a resource with:
$ kubebuilder create api
```

### 创建 API

在项目根目录下执行下面的命令创建 API

```bash
kubebuilder create api --group webapp --version v1 --kind Guestbook
```

按照提示进行生成即可

```text
> kubebuilder create api --group webapp --version v1 --kind Guestbook

Create Resource [y/n]
y
Create Controller [y/n]
y
Writing kustomize manifests for you to edit...
Writing scaffold for you to edit...
api/v1/guestbook_types.go
controllers/guestbook_controller.go
Update dependencies:
$ go mod tidy
go: downloading github.com/onsi/ginkgo/v2 v2.0.0
Running make:
$ make generate
mkdir -p /code/srliao/mytest/test-prj/bin
GOBIN=/code/srliao/mytest/test-prj/bin go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.9.0
go: downloading sigs.k8s.io/controller-tools v0.9.0
go: downloading github.com/spf13/cobra v1.4.0
go: downloading github.com/fatih/color v1.12.0
go: downloading golang.org/x/tools v0.1.10-0.20220218145154-897bd77cd717
go: downloading github.com/gobuffalo/flect v0.2.5
go: downloading github.com/mattn/go-isatty v0.0.12
go: downloading github.com/mattn/go-colorable v0.1.8
go: downloading golang.org/x/mod v0.6.0-dev.0.20220106191415-9b9b3d81d5e3
/code/srliao/mytest/test-prj/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
Next: implement your new API and generate the manifests (e.g. CRDs,CRs) with:
$ make manifests
```

### 项目结构

API 创建完成后，在项目根目录下查看目录结构

```text
.
├── api
│   └── v1
│       ├── groupversion_info.go
│       ├── guestbook_types.go
│       └── zz_generated.deepcopy.go
├── bin
│   └── controller-gen
├── config
│   ├── crd # 新增 CRD 定义
│   │   ├── kustomization.yaml
│   │   ├── kustomizeconfig.yaml
│   │   └── patches
│   │       ├── cainjection_in_guestbooks.yaml
│   │       └── webhook_in_guestbooks.yaml
│   ├── default
│   │   ├── kustomization.yaml
│   │   ├── manager_auth_proxy_patch.yaml
│   │   └── manager_config_patch.yaml
│   ├── manager
│   │   ├── controller_manager_config.yaml
│   │   ├── kustomization.yaml
│   │   └── manager.yaml
│   ├── prometheus
│   │   ├── kustomization.yaml
│   │   └── monitor.yaml
│   ├── rbac
│   │   ├── auth_proxy_client_clusterrole.yaml
│   │   ├── auth_proxy_role_binding.yaml
│   │   ├── auth_proxy_role.yaml
│   │   ├── auth_proxy_service.yaml
│   │   ├── guestbook_editor_role.yaml
│   │   ├── guestbook_viewer_role.yaml
│   │   ├── kustomization.yaml
│   │   ├── leader_election_role_binding.yaml
│   │   ├── leader_election_role.yaml
│   │   ├── role_binding.yaml
│   │   └── service_account.yaml
│   └── samples
│       └── webapp_v1_guestbook.yaml # CRD 示例
├── controllers # 新增 controller
│   ├── guestbook_controller.go
│   └── suite_test.go
├── Dockerfile # 用于构建 Operator 镜像
├── go.mod
├── go.sum
├── hack
│   └── boilerplate.go.txt
├── main.go # 新增处理逻辑
├── Makefile # 构建时使用
├── PROJECT # 项目配置
└── README.md

```

以上就是自动初始化出来的文件

### 安装 CRD

```bash
make install
```

安装完成后查看 CRD

```bash
kubectl get crd | grep code.liaosirui.com
```

```text
> kubectl get crd | grep code.liaosirui.com

guestbooks.webapp.code.liaosirui.com                  2022-08-05T03:34:05Z
```

### 部署 controller

有两种方式运行 controller：

- 本地运行，用于调试
- 部署到 Kubernetes 上运行，作为生产使用

#### 本地运行

要想在本地运行 controller，只需要执行下面的命令。

```bash
make run
```

将看到 controller 启动和运行时输出

#### 将 controller 部署到 Kubernetes

执行下面的命令部署 controller 到 Kubernetes 上，这一步将会在本地构建 controller 的镜像，并推送到 DockerHub 上，然后在 Kubernetes 上部署 Deployment 资源。

```bash
make docker-build docker-push IMG=registry.cn-chengdu.aliyuncs.com/custom-srliao/kubebuilder-example:latest
make deploy IMG=registry.cn-chengdu.aliyuncs.com/custom-srliao/kubebuilder-example:latest
```

如果要取消部署，使用

```bash
make undeploy
```

在初始化项目时，kubebuilder 会自动根据项目名称创建一个 Namespace，如本文中的 test-prj-system，查看 Deployment 对象和 Pod 资源。

```text
> kubectl get deployment -n test-prj-system

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
test-prj-controller-manager   1/1     1            1           6m40s

> kubectl get pod -n test-prj-system

NAME                                           READY   STATUS    RESTARTS   AGE
test-prj-controller-manager-65c54d5b56-zmqrx   2/2     Running   0          22s
```

### 创建 CR

Kubebuilder 在初始化项目的时候已生成了示例 CR，执行下面的命令部署 CR。

```bash
kubectl apply -f config/samples/webapp_v1_guestbook.yaml
```

查看新创建的 CR

```bash
kubectl get guestbook.webapp.code.liaosirui.com guestbook-sample -o yaml
```

```yaml
apiVersion: webapp.code.liaosirui.com/v1
kind: Guestbook
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"webapp.code.liaosirui.com/v1","kind":"Guestbook","metadata":{"annotations":{},"name":"guestbook-sample","namespace":"default"},"spec":null}
  creationTimestamp: "2022-08-05T06:13:11Z"
  generation: 1
  name: guestbook-sample
  namespace: default
  resourceVersion: "10125401"
  uid: 195559b3-9677-4bdc-b19a-e0301c9dbcee

```

至此一个基本的 Operator 框架已经创建完成，但这个 Operator 只是修改了 etcd 中的数据而已，实际上什么事情也没做，因为我们没有在 Operator 中的增加业务逻辑

### 增加业务逻辑

将修改 CRD 的数据结构并在 controller 中增加一些日志输出

#### 修改 CRD

将修改上文中使用 kubebuilder 命令生成的默认 CRD 配置，在 CRD 中增加 FirstName、LastName 和 Status 字段

```bash
code api/v1/guestbook_types.go
```

增加字段：

```go
// line 26
// GuestbookSpec defines the desired state of Guestbook
type GuestbookSpec struct {
    // INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
    // Important: Run "make" to regenerate code after modifying this file

    // Foo is an example field of Guestbook. Edit guestbook_types.go to remove/update
    FirstName string `json:"firstname"`
    LastName  string `json:"lastname"`
}

// GuestbookStatus defines the observed state of Guestbook
type GuestbookStatus struct {
    // INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
    // Important: Run "make" to regenerate code after modifying this file
    Status string `json:"Status"`
}

```

#### 修改 Reconcile 函数

Reconcile 函数是 Operator 的核心逻辑，Operator 的业务逻辑都位于 `controllers/guestbook_controller.go` 文件的 `func (r *GuestbookReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error)` 函数中。

```bash
code controllers/guestbook_controller.go
```

修改代码：

```go
func (r *GuestbookReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    logger := log.FromContext(ctx)

    // TODO(user): your logic here
    logger = logger.WithValues("api-example-a", req.NamespacedName)

    // 获取当前的 CR，并打印
    obj := &webappv1.Guestbook{}
    if err := r.Get(ctx, req.NamespacedName, obj); err != nil {
        logger.V(1).Info(err.Error(), "Unable to fetch object")
    } else {
        logger.V(1).Info(fmt.Sprintf("Greeting from Kubebuilder to <%v> <%v>", obj.Spec.FirstName, obj.Spec.LastName))
    }

    // 初始化 CR 的 Status 为 Running
    obj.Status.Status = "Running"
    if err := r.Status().Update(ctx, obj); err != nil {
        logger.V(1).Info(err.Error(), "unable to update status")
    }
    return ctrl.Result{}, nil
}

```

这段代码的业务逻辑是当发现有 `guestbook.webapp.code.liaosirui.com` 的 CR 变更时，在控制台中输出日志

#### 运行测试

修改好 Operator 的业务逻辑后，再测试一下新的逻辑是否可以正常运行。

- 部署 CRD

```bash
make install
```

- 运行 controller

```bash
make run
```

为了方便起见，将在本地运行 controller

保持该窗口在前台运行

- 部署 CR

修改 `config/samples/webapp_v1_guestbook.yaml` 文件中的配置。

```yaml
apiVersion: webapp.code.liaosirui.com/v1
kind: Guestbook
metadata:
  name: guestbook-sample
spec:
  # TODO(user): Add fields here
  firstname: Jimmy
  lastname: Song

```

将其应用到 Kubernetes

```bash
kubectl apply -f config/samples/webapp_v1_guestbook.yaml
```

此时转到上文中运行 controller 的窗口，将在命令行前台中看到如下输出

```text
1.6596835013825462e+09  DEBUG   Greeting from Kubebuilder to <Sirui> <Liao>  {"controller": "guestbook", "controllerGroup": "webapp.code.liaosirui.com", "controllerKind": "Guestbook", "guestbook": {"name":"guestbook-sample","namespace":"default"}, "namespace": "default", "name": "guestbook-sample", "reconcileID": "ee988ac2-2b26-4321-b5eb-49c22a2ffbf3", "api-example-a": "default/guestbook-sample", "Sirui": "Liao"}
```

- 获取当前的 CR

```yaml
apiVersion: webapp.code.liaosirui.com/v1
kind: Guestbook
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"webapp.code.liaosirui.com/v1","kind":"Guestbook","metadata":{"annotations":{},"name":"guestbook-sample","namespace":"default"},"spec":{"firstname":"Sirui","lastname":"Liao"}}
  creationTimestamp: "2022-08-05T07:05:56Z"
  generation: 2
  name: guestbook-sample
  namespace: default
  resourceVersion: "10141376"
  uid: ddaa4a3b-129f-4bde-bcff-0e2cbe823d89
spec:
  firstname: Sirui
  lastname: Liao
status:
  Status: Running

```
