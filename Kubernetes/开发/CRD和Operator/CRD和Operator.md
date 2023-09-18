## Kubernetes Operator 简介

Kubernetes Operator 是一种用来扩展 Kubernetes API 并实现自定义控制逻辑的应用程序

它由 Custom Resource Definitions (CRDs) 和（Custom Controller）控制器组成，能够在 Kubernetes 中创建、配置和管理复杂的有状态应用

### Operator 的核心组件

自定义资源（CR）、自定义资源定义（CRD）和自定义控制器是构建 Kubernetes 的关键部件，它们共同工作以对 Kubernetes 进行扩展，从而满足特定应用程序的需求

一个 Operator 中主要有以下几种对象：

- CRD、Custom Resource Definition（自定义资源定义）

Custom Resource Definition（CRD）是一种在 Kubernetes API 中声明新的自定义资源类型的方式

CRD 可以理解为自定义资源的模板，描述了新资源的名称、模式和验证规则等信息

一旦创建了 CRD，就可以跟其它内置资源一样操作 CRD 创建的自定义资源（CR）

简单的来说，CRD 定义了你想在 Kubernetes 中创建那种类型的自定义资源

- CR、Custom Resource（自定义资源）

Custom Resource（CR）是 Kubernetes API 中的扩展，允许创建自己的特定于应用程序的资源类型

可以像处理内置资源类型（如 Deploylent、Pod、Service 等）一样处理这些自定义资源

每一个 CR 都代表了 Kubernetes 集群中的一种资源对象，比如数据库实例、应用实例等

- Controller、Custom Controller（自定义控制器）

自定义控制器是 Kubernetes 的核心概念之一，它负责管理 CRD 创建的自定义资源

控制器是一个持续运行的循环，负责观察特定资源的状态，并确保当前状态符合资源规范定义的预期状态

如果两者不符，控制器将采取行动使当前状态与预期状态一致

自定义控制器通常与特定的 CRD 配套使用，作为 Operator 的一部分实现复杂的、自动化的管理逻辑

### Operator 的作用

Operator 模式的核心思想是将运维人员的知识编码到软件中。这意味 Operator 可以处理例如部署、升级、备份、恢复、故障排查等任务

例如，一个数据库可能有一个 Operator，该 Operator 知道如何正确的部署数据库、如何在磁盘空间不足时扩展存储、如何备份数据以及如何出现问题时恢复数据库等

通过 Operator，可以将复杂的应用 “原生化” 到 Kubernetes 中，让这些应用能够像基础设施一样被自动管理和调度

### Group、Version、Kind、Resource

GVK（Group, Version, Kind）用于标识 Kubernetes API 对象的类型，例如有可能有一个名称为 my-pod 的 Pod 对象，它的 GVK 就是 Pod，由以下三个部分组成：

- Group：资源的 API 对象属于哪个组，如 Deployment、Replicasets 等就属于 Apps 组
- Version：API 的版本，如 v1、v1beta1
- Kind：资源的类别，例如 Pod、Deployment、Service 等

GVR (Group, Version, Resource) 类似于 GVK，但它代表的是 API 资源实例，而不是类型，由以下三个部分组成：

- Group：资源的 API 组，如 apps、batch
- Version：API 的版本，如 v1、v1beta1
- Resource：资源的复数名称，例如 Pods、Deployments、Services 等

## 开发自己的 Operator

以下是一些库和工具，可以用于编写自己的云原生Operator

- kubebuilder：https://github.com/kubernetes-sigs/kubebuilder
- Operator Framework：https://github.com/operator-framework/operator-sdk
- shell-operator：https://github.com/flant/shell-operator
- Charmed Operator Framework：https://juju.is/
- Java Operator SDK：https://github.com/operator-framework/java-operator-sdk
- Kopf（kubernetes Operator Pythonic Framework）：https://github.com/nolar/kopf
- kube-rs（Rust）：https://kube.rs/
- KubeOps （.NET operator SDK）：https://buehler.github.io/dotnet-operator-sdk/
- KUDO（Kubernetes 通用声明式Operator）：https://kudo.dev/
- Mast：https://docs.ansi.services/mast/user_guide/operator/
- Metacontroller：https://metacontroller.github.io/metacontroller/intro.html

## CRD 简介

Custom Resource Define 简称 CRD，是 Kubernetes（v1.7+）为提高可扩展性，让开发者去自定义资源的一种方式

> `CRD（Custom Resource Definition）` 本身是一种 Kubernetes 内置的资源类型，即**自定义资源的定义**，用于描述用户定义的资源是什么样子。

官方文档：<https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/ >

CRD 的相关概念：

- CRD 是 `v1.7+` 新增的无需改变代码 就可以扩展 Kubernetes API 的机制，用来管理自定义对象。它实际上是 ThirdPartyResources（TPR） 的升级版本，而 TPR 已经在 v1.8 中删除。
- 从 Kubernetes 的用户角度来看，所有东西都叫资源 Resource，就是 Yaml 里的字段 Kind 的内容，例如 Service、Deployment 等。
- 除了常见内置资源之外，Kubernetes 允许用户自定义资源 Custom Resource，而 CRD 表示自定义资源的定义。
- 当你创建新的 CustomResourceDefinition（CRD）时，Kubernetes API 服务器会为你所指定的每个版本生成一个新的 RESTful 资源路径。
- 基于 CRD 对象所创建的自定义资源可以是名字空间作用域的，也可以是集群作用域的， 取决于 CRD 对象 spec.scope 字段的设置。
- 定义 CRD 对象的操作会使用你所设定的名字和模式定义（Schema）创建一个新的定制资源， Kubernetes API 负责为你的定制资源提供存储和访问服务。 CRD 对象的名称必须是合法的 DNS 子域名。

## 参考资料

- <https://mp.weixin.qq.com/s/KhiCfUR_HiC1sRZW6Z0N_g>
- <https://mp.weixin.qq.com/s/fonvqHKjTd6-zLSGvYn38A>
- <https://mp.weixin.qq.com/s/HuYwxy4-rb-rPOoQT_mOkw>

- <https://mp.weixin.qq.com/s/PtHgg2HPX26VItujj5YCuA>

- <https://mp.weixin.qq.com/s/FCzrhubJH_x8p-2FepWIJg>



