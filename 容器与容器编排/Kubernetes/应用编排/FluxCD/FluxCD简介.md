## fluxcd2 简介

官方：

- Git 仓库：<https://github.com/fluxcd/flux2>
- 官方文档：<https://fluxcd.io/flux/>

## 部署 fluxcd2

### Flux CLI 部署

官方的方式是推荐使用 Flux CLI

官方文档：<https://fluxcd.io/flux/installation/>

首先是安装 Flux CLI （即 Flux）

```bash
curl -s https://fluxcd.io/install.sh | bash

# 设置补全
. <(flux completion bash)
```

 在启动前，先 check 下 flux 的版本等信息是否已经可以了；使用命令 `flux check --pre` 检查

```bash
> flux check --pre
► checking prerequisites
✔ Kubernetes 1.27.1 >=1.20.6-0
✔ prerequisites checks passed
```

可以看到版本符合，prerequisites checks passed

执行安装命令

```bash
> flux install

✚ generating manifests
✔ manifests build completed
► installing components in flux-system namespace
CustomResourceDefinition/alerts.notification.toolkit.fluxcd.io created
CustomResourceDefinition/buckets.source.toolkit.fluxcd.io created
CustomResourceDefinition/gitrepositories.source.toolkit.fluxcd.io created
CustomResourceDefinition/helmcharts.source.toolkit.fluxcd.io created
CustomResourceDefinition/helmreleases.helm.toolkit.fluxcd.io created
CustomResourceDefinition/helmrepositories.source.toolkit.fluxcd.io created
CustomResourceDefinition/kustomizations.kustomize.toolkit.fluxcd.io created
CustomResourceDefinition/ocirepositories.source.toolkit.fluxcd.io created
CustomResourceDefinition/providers.notification.toolkit.fluxcd.io created
CustomResourceDefinition/receivers.notification.toolkit.fluxcd.io created
Namespace/flux-system created
ServiceAccount/flux-system/helm-controller created
ServiceAccount/flux-system/kustomize-controller created
ServiceAccount/flux-system/notification-controller created
ServiceAccount/flux-system/source-controller created
ClusterRole/crd-controller-flux-system created
ClusterRole/flux-edit-flux-system created
ClusterRole/flux-view-flux-system created
ClusterRoleBinding/cluster-reconciler-flux-system created
ClusterRoleBinding/crd-controller-flux-system created
Service/flux-system/notification-controller created
Service/flux-system/source-controller created
Service/flux-system/webhook-receiver created
Deployment/flux-system/helm-controller created
Deployment/flux-system/kustomize-controller created
Deployment/flux-system/notification-controller created
Deployment/flux-system/source-controller created
NetworkPolicy/flux-system/allow-egress created
NetworkPolicy/flux-system/allow-scraping created
NetworkPolicy/flux-system/allow-webhooks created
◎ verifying installation
✔ helm-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ install finished
```

更多安装命令

```bash
flux install \
--registry harbor.alpha-quant.com.cn:5000/3rd_party/ghcr.io/fluxcd \
--image-pull-secret platform-oci-image-pull-secret \
--namespace flux-system \
--components helm-controller
```

### 使用 helm 部署 

非官方仓库：<https://github.com/fluxcd-community/helm-charts>

添加仓库：

```bash
helm repo add fluxcd-community https://fluxcd-community.github.io/helm-charts
```

查看版本

```bash
> helm search repo fluxcd-community

NAME                                	CHART VERSION	APP VERSION	DESCRIPTION
fluxcd-community/flux2              	2.7.0        	0.41.1     	A Helm chart for flux2
fluxcd-community/flux2-multi-tenancy	0.0.4        	           	A Helm chart for flux2-multi-tenancy
fluxcd-community/flux2-notification 	1.8.0        	0.41.1     	A Helm chart for flux2 alerts and the needed pr...
fluxcd-community/flux2-sync         	1.4.0        	0.41.1     	A Helm chart for flux2 GitRepository to sync with
```

该 chart 中的版本各组件的镜像稍微落后官方
