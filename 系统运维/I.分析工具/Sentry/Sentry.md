## Sentry 简介

官方：

- 官网：<https://sentry.io/>
- GitHub 仓库：<https://github.com/getsentry/sentry>

## 安装

目前没有官方的 chart，可选用的第三方方案：

- <https://github.com/sentry-kubernetes/charts>
- <https://github.com/helm/charts/blob/master/stable/sentry/values.yaml>（已弃用）

官方推荐的 self hosted 仓库：<https://github.com/getsentry/self-hosted>

添加仓库

```bash
helm repo add sentry https://sentry-kubernetes.github.io/charts
```

查看最新的 chart 版本

```bash
> helm search repo sentry

NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
sentry/sentry                   19.0.0          23.5.0          A Helm chart for Kubernetes                       
sentry/sentry-db                0.9.4           10.0.0          A Helm chart for Kubernetes                       
sentry/sentry-kubernetes        0.3.2           latest          A Helm chart for sentry-kubernetes (https://git...
sentry/clickhouse               3.3.0           19.14           ClickHouse is an open source column-oriented da...
```

下载最新的 chart 版本

```bash
helm pull sentry/sentry --version 19.0.0

# 下载并解压
helm pull sentry/sentry --version 19.0.0 --untar
```

Sentry web 需要一个单独手动建立的 pvc

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-data
  namespace: sentry
  labels:
    app: sentry
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  volumeMode: Filesystem
  storageClassName: "csi-local-data-path"

```

参考 values：

```yaml
user: 
  create: "true"
  email: "admin@yourdomain.com"
  password: "AgoodPassword"

containerSecurityContext:
  enabled: true
  runAsNonRoot: false
  runAsUser: 0

sentry:
  worker:
    affinity:
      nodeAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 10
            preference:
              matchExpressions:
                - key: kubernetes.io/hostname
                  operator: In
                  values: 
                  - devnode2
  web:
    affinity:
      nodeAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 10
            preference:
              matchExpressions:
                - key: kubernetes.io/hostname
                  operator: In
                  values: 
                  - devnode2

clickhouse:
  clickhouse:
    persistentVolumeClaim:
      enabled: true
      dataPersistentVolume:
        accessModes:
        - ReadWriteOnce
        enabled: true
        storage: 500Gi
        storageClassName: "csi-local-data-path"
      logsPersistentVolume:
        accessModes:
        - ReadWriteOnce
        enabled: true
        storage: 50Gi
        storageClassName: "csi-local-data-path"

kafka:
  common:
    global:
      storageClass: "csi-local-data-path"
  containerSecurityContext:
    enabled: true
    runAsNonRoot: false
    runAsUser: 0
  global:
    storageClass: "csi-local-data-path"
  logPersistence:
    storageClass: "csi-local-data-path"
  persistence:
    storageClass: "csi-local-data-path"
  zookeeper:
    containerSecurityContext:
      enabled: false
      runAsNonRoot: false
      runAsUser: 0
    common:
      global:
        storageClass: "csi-local-data-path"
    global:
      storageClass: "csi-local-data-path"
    persistence:
      storageClass: "csi-local-data-path"

memcached:
  common:
    global:
      storageClass: "csi-local-data-path"
  global:
    storageClass: "csi-local-data-path"
  persistence:
    storageClass: "csi-local-data-path"
  containerSecurityContext:
    enabled: true
    runAsNonRoot: false
    runAsUser: 0

postgresql:
  common:
    global:
      storageClass: "csi-local-data-path"
  containerSecurityContext:
    enabled: true
    runAsUser: 0
  global:
    storageClass: "csi-local-data-path"
  persistence:
    storageClass: "csi-local-data-path"
  primary:
    affinity:
      nodeAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 10
            preference:
              matchExpressions:
                - key: kubernetes.io/hostname
                  operator: In
                  values: 
                  - devnode2

rabbitmq:
  podSecurityContext:
    enabled: true
    fsGroup: 1001
    runAsUser: 1001
  common:
    global:
      storageClass: "csi-local-data-path"
  global:
    storageClass: "csi-local-data-path"
  persistence:
    storageClass: "csi-local-data-path"
  serviceAccount:
    automountServiceAccountToken: true
    create: true
  volumePermissions:
    enable: true

redis:
  common:
    global:
      storageClass: "csi-local-data-path"
  global:
    storageClass: "csi-local-data-path"
  master:
    containerSecurityContext:
      enabled: true
      runAsUser: 0
    persistence:
      storageClass: "csi-local-data-path"
  replica:
    containerSecurityContext:
      enabled: true
      runAsUser: 0
    persistence:
      storageClass: "csi-local-data-path"
  sentinel:
    containerSecurityContext:
      enabled: true
      runAsUser: 0
    persistence:
      storageClass: "csi-local-data-path"

zookeeper:
  common:
    global:
      storageClass: "csi-local-data-path"
  persistence:
    storageClass: "csi-local-data-path"
  containerSecurityContext:
    enabled: true
    runAsNonRoot: false
    runAsUser: 0

ingress:
  alb:
    httpRedirect: false
  enabled: true
  regexPathStyle: nginx
  ingressClassName: nginx
  annotations:
    cert-manager.io/cluster-issuer: cert-http01
    nginx.ingress.kubernetes.io/proxy-body-size: 1024m
  hostname: sentry.local.liaosirui.com
  tls:
    - hosts:
        - sentry.local.liaosirui.com
      secretName: sentry-https-tls

filestore:
  backend: filesystem
  filesystem:
    path: /var/lib/sentry/files
    persistence:
      accessMode: ReadWriteOnce
      enabled: true
      existingClaim: "sentry-data"
      persistentWorkers: false
      size: 10Gi

```

安装：

```bash
helm upgrade --install sentry  \
    --namespace sentry \
    --create-namespace \
    -f ./values.yaml \
    sentry/sentry --version 19.0.0
```

## 参考资料

- sentry 架构：<https://juejin.cn/post/7139006619043495973#heading-10>
