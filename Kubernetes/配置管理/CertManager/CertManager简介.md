
## 简介

Cert-manager 是一个Kubernetes addon 插件，用于从不同的证书颁发者自动化管理和签发 TLS 证书。Cert-manager 会保证证书的合法性，并试图在到期前轮转更新证书。

主要作用：给 k8s 集群中的应用生成证书，让应用可以通过 https 访问。

主要解决的几个痛点如下：

- 如果 k8s 集群上部署的应用较多，要为每个应用的不同域名生成 https 证书，操作太麻烦。
- 上述这些手动操作没有跟 k8s 的 deployment 描述文件放在一起记录下来，很容易遗忘。
- 证书过期后，又得手动执行命令重新生成证书。

cert-manager 则可以解决上面的那些问题，实现证书的自动生成和更新。

## 相关

- 官方文档：<https://cert-manager.io/docs/>
- 代码仓库：<https://github.com/cert-manager/cert-manager>

## 架构

cert-manager 也是一个 controller，部署起来后，会像其它 controller 一样，监听着资源的变化，然后执行相应的逻辑。

它会监听的资源有如下三种，它们都属于分组 `certmanager.k8s.io`：

- certificates
- clusterissuers
- issuers

<img src=".assets/image-20221217124255398.png" alt="image-20221217124255398" style="zoom: 67%;" />

查看所有的 crd：

```bash
kubectl get crd | grep cert-manager
```

目前有：

```text
certificaterequests.cert-manager.io                   2022-07-30T14:46:33Z
certificates.cert-manager.io                          2022-07-30T14:46:32Z
challenges.acme.cert-manager.io                       2022-07-30T14:46:33Z
clusterissuers.cert-manager.io                        2022-07-30T14:46:32Z
issuers.cert-manager.io                               2022-07-30T14:46:33Z
orders.acme.cert-manager.io                           2022-07-30T14:46:32Z

```

Cert-manager 定义了几个 CRD 资源，用于证书的管理。如下：

- issuers.cert-manager.io：命名空间级别的证书签发者，它只能为同命名空间的证书请求签发证书。更多参考： <https://cert-manager.io/docs/configuration/>
- clusterissuers.cert-manager.io：集群级别的证书签发者，它可以为多个命名空间的证书请求签发证书，配置与 issuers 完全一致。
- certificates.cert-manager.io： 一个人类可读的证书请求的定义，其需要指定一个 issuer，Cert-manager 使用相应 issuer 为 Certificate 签发证书。签发的证书存储在指定的 secret 中。

certificates 是自定义证书资源，其中存储了证书的类型，以及证书信息存到哪个 secret 等信息。

clusterissuers 和 issuers 是生产者，负责生成 certificates，然后 certificates 负责生成 tls 类型的 secret，secret 最终被 ingress 引用，实现 https 访问。

## 参考资料

- <https://cloud.tencent.com/developer/article/1326543>
- <https://jeremyxu2010.github.io/2018/08/k8s%E4%B8%AD%E4%BD%BF%E7%94%A8cert-manager%E7%8E%A9%E8%BD%AC%E8%AF%81%E4%B9%A6/>
- <https://blog.51cto.com/liuzhengwei521/2120535?utm_source=oschina-app>
