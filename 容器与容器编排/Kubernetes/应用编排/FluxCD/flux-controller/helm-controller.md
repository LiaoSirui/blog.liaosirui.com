## 部署 helm chart

### Helm Repository

官方文档：<https://fluxcd.io/flux/components/source/helmrepositories/>

创建一个 helm 仓库

- Helm HTTP/S repository，官方文档：<https://fluxcd.io/flux/components/source/helmrepositories/#helm-https-repository>

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 5m0s
  url: https://stefanprodan.github.io/podinfo
```

- OCI Helm Repositories，官方文档：<https://fluxcd.io/flux/components/source/helmrepositories/#helm-oci-repository>

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: podinfo
spec:
  interval: 1m0s
  url: oci://ghcr.io/stefanprodan/charts
  type: "oci"

```

### Helm chart

官方文档：<https://fluxcd.io/flux/components/source/helmcharts/#example>

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmChart
metadata:
  name: podinfo
  namespace: default
spec:
  interval: 5m0s
  chart: podinfo
  reconcileStrategy: ChartVersion
  sourceRef:
    kind: HelmRepository
    name: podinfo
  version: '5.*'

```

### helm release

官方文档：<https://fluxcd.io/flux/components/helm/helmreleases/>

## 示例

oci helm chart 和 release

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: paas-testing
  namespace: paas-system
spec:
  type: "oci"
  interval: 5m0s
  url: oci://dockerhub.local.liaosirui.com:5000/paas-testing
  provider: generic
  secretRef:
    name: paas-image-pull-pass-secrets

---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: chart-kube-monkey
  namespace: paas-system
spec:
  interval: 5m
  releaseName: kube-monkey
  chart:
    spec:
      chart: chart-kube-monkey
      version: '5.11.2-master-11fc58b71134'
      sourceRef:
        kind: HelmRepository
        name: paas-testing
        namespace: paas-system
      interval: 1m
  install:
    crds: CreateReplace
  upgrade:
    crds: CreateReplace
    remediation:
      remediateLastFailure: true
  test:
    enable: true
  values:
    kubeMonkey:
      config:
        debug:
          enabled: false
        dryRun: false

```

