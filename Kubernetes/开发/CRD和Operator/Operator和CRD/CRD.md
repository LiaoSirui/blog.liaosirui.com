Custom Resource Define 简称 CRD，是 Kubernetes（v1.7+）为提高可扩展性，让开发者去自定义资源的一种方式

## CRD 简介

> `CRD（Custom Resource Definition）` 本身是一种 Kubernetes 内置的资源类型，即**自定义资源的定义**，用于描述用户定义的资源是什么样子。

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



