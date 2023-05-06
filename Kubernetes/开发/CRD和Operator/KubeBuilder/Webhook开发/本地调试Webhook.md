## 本地调试

创建的 webhook 默认使用的 service 的方式访问 webhook server，这需要将 webhook 部署到 k8s 上才能工作；对于开发的初级阶段，往往需要在反复修改调试代码，每次将 webhook 部署到 k8s 上很不方便；在使用 Kubebuilder 开发 Kubernetes Operator 的时候，通过在本地直接运行 Operator 进行功能调试往往更为方便、效率

一般情况下开发者仅需要执行 `make run` 即可在本地运行 Operator。但是当 Operator 启用了 webhook 服务时，就需要对配置内容进行一些调整，才能使 Operator 在本地正常运行

## 原理

webhook 分别为两部分

- 其一是能够处理 https 请求的 web 服务器，以及 webhook 请求的处理程序；
- 其二是在 k8s 上声明哪些资源对象状态变化需要调用 webhook 请求，该功能通过创建 mutatingwebhookconfigurations 和 validatingwebhookconfigurations 实现

所以原理上 web 服务器可以本地节点启动，然后修改 k8s 上的 webhook 配置，使其将请求发送给本地的 web 服务器

需要完成三个步骤：

- 生成认证证书，包括服务端和客户端，证书中必须包含本地节点的地址或域名
- 使用认证证书，在本地启动 webhook 的服务端程序；
- 在 k8s 创建 `MutatingAdmissionWebhook` 和 `ValidatingWebhookConfiguration` 对象，指定使用本地 webhook 服务，其中 clientConfig 字段指定为本地地址，例如：<https://10.24.9.99:9443/...>

## 配置变更

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

如果希望本地运行 webhook，需要放置证书 `/tmp/k8s-webhook-server/serving-certs/tls.{crt,key}`

使用如下命令创建一个证书文件夹

```bash
mkdir -p /tmp/k8s-webhook-server/serving-certs/
```

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
/code/aipaas-devops/kbdev-operator/bin/controller-gen rbac:roleName=manager-role crd webhook paths="./..." output:crd:artifacts:config=config/crd/bases
/code/aipaas-devops/kbdev-operator/bin/kustomize build config/overlays/dev | kubectl apply -f -
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

## 补充

controller 有两种运行方式，一种是在 kubernetes 环境内，一种是在 kubernetes 环境外独立运行；在编码阶段我们通常会在开发环境上运行 controller，但是如果使用了 webhook,由于其特殊的鉴权方式，需要将 kubernetes 签发的证书放置在本地的`tmp/k8s-webhook-server/serving-crets/ `目录

面对这种问题，官方给出的建议是：如果在开发阶段暂时用不到 webhook，那么在本地运行 controller 时屏蔽 webhook 的功能

具体操作是首先修改 `main.go` 文件，其实就是在 webhook 控制器这块添加一个环境变量的判断:

```go
if os.Getenv("ENABLE_WEBHOOKS") != "false" {
	if err = (&devopsv1.KBDev{}).SetupWebhookWithManager(mgr); err != nil {
		setupLog.Error(err, "unable to create webhook", "webhook", "KBDev")
		os.Exit(1)
	}
}
```

在本地启动 controller 的时候，使用`make run ENABLE_WEBHOOK=false`即可

