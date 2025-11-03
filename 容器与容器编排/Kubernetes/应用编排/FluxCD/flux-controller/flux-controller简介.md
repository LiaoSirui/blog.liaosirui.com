官方：

- <https://fluxcd.io/docs/components/>
- <https://github.com/fluxcd/flux2#components>

在 flux-system 下，运行了 4 个 pod，即：

- `source-countroller`
- `kustomize-controller`
- `helm-controller`
- `notification-controller`

另，官方新增了：

- `image-automation-controller`

## Source Controller

官方文档：<https://fluxcd.io/flux/components/source/gitrepositories/>

source-controller 是 Kubernetes 的 operator，定义了可以从外部比如 Git Repository，也可以定义 Helm Repository 拉取资源。即我们需要告诉 flux v2 我们的配置文件的位置

## Kustomize Controller

官方文档：<https://fluxcd.io/flux/components/kustomize/>

## Helm Controller

官方文档：<https://fluxcd.io/flux/components/helm/>

![Helm Controller Diagram](.assets/flux-controller%E7%AE%80%E4%BB%8B/helm-controller.png)

## Notification Controller

官方文档：<https://fluxcd.io/flux/components/notification/>

## Image reflector and automation controllers

官方文档：<https://fluxcd.io/flux/components/image/>