使用 fluxcd 完成部署，资源清单如下

本例中部署单点，均在一个节点完成

## helm chart

### `HelmRepository.yaml`

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: sentry
  namespace: sentry
spec:
  interval: 5m0s
  provider: generic
  timeout: 120s
  url: 'https://sentry-kubernetes.github.io/charts'

```

### `HelmChart.yaml`

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmChart
metadata:
  name: chart-sentry
  namespace: sentry
spec:
  chart: sentry
  interval: 5m0s
  reconcileStrategy: ChartVersion
  sourceRef:
    kind: HelmRepository
    name: sentry
  version: 19.0.0

```

## pv-pvc

### `sentry-zookeeper-pv-pvc.yaml`

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-zookeeper-data
  namespace: sentry
  labels:
    app: sentry-zookeeper
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-zookeeper
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-zookeeper-data-pv
  labels:
    app: sentry-zookeeper
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-zookeeper
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

### `sentry-zookeeper-clickhouse-pv-pvc.yaml`

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-zookeeper-clickhouse-data
  namespace: sentry
  labels:
    app: sentry-zookeeper-clickhouse
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-zookeeper-clickhouse
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-zookeeper-clickhouse-data-pv
  labels:
    app: sentry-zookeeper-clickhouse
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-zookeeper-clickhouse
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

### `sentry-web-pv-pvc.yaml`

```yaml
---
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
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry
      release: sentry


---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-data-pv
  labels:
    app: sentry
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /data/sentry-data
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

### `sentry-redis-pv-pvc.yaml`

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-redis-data
  namespace: sentry
  labels:
    app: sentry-redis
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-redis
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-redis-data-pv
  labels:
    app: sentry-redis
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-redis
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

### `sentry-rabbitmq-pv-pvc.yaml`

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-rabbitmq-data
  namespace: sentry
  labels:
    app: sentry-rabbitmq
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-rabbitmq
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-rabbitmq-data-pv
  labels:
    app: sentry-rabbitmq
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-rabbitmq
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

### `sentry-postgresql-pv-pvc.yaml`

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-postgresql-data
  namespace: sentry
  labels:
    app: sentry-postgresql
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-postgresql
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-postgresql-data-pv
  labels:
    app: sentry-postgresql
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-postgresql
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

### `sentry-kafka-pv-pvc.yaml`

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: data-sentry-kafka-0
  namespace: sentry
  labels:
    app: sentry-kafka-0
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-kafka-0
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-kafka-data-0-pv
  labels:
    app: sentry-kafka-0
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-kafka-0
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: data-sentry-kafka-1
  namespace: sentry
  labels:
    app: sentry-kafka-1
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-kafka-1
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-kafka-data-1-pv
  labels:
    app: sentry-kafka-1
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-kafka-1
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: data-sentry-kafka-2
  namespace: sentry
  labels:
    app: sentry-kafka-2
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-kafka-2
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-kafka-data-2-pv
  labels:
    app: sentry-kafka-2
    release: sentry
spec:
  capacity:
    storage: 100Gi
  hostPath:
    path: /var/lib/sentry-kafka-2
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

### `sentry-clickhouse-pv-pvc.yaml`

```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-clickhouse-logs-sentry-clickhouse-0
  namespace: sentry
  labels:
    app: sentry-clickhouse-logs
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-clickhouse-logs
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-clickhouse-logs-data-pv
  labels:
    app: sentry-clickhouse-logs
    release: sentry
spec:
  capacity:
    storage: 50Gi
  hostPath:
    path: /data/sentry-clickhouse-logs
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sentry-clickhouse-data-sentry-clickhouse-0
  namespace: sentry
  labels:
    app: sentry-clickhouse-data
    release: sentry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  volumeMode: Filesystem
  selector:
    matchLabels:
      app: sentry-clickhouse-data
      release: sentry

---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: sentry-clickhouse-data-data-pv
  labels:
    app: sentry-clickhouse-data
    release: sentry
spec:
  capacity:
    storage: 50Gi
  hostPath:
    path: /data/sentry-clickhouse-data
    type: DirectoryOrCreate
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - dev-sentry

```

## HelmRelease

部署 helm release

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: chart-sentry
  namespace: sentry
spec:
  chart:
    spec:
      chart: sentry
      interval: 1m
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: sentry
        namespace: sentry
      version: 19.0.0
  install:
    crds: CreateReplace
  interval: 5m
  releaseName: sentry
  test:
    enable: true
  upgrade:
    crds: CreateReplace
    remediation:
      remediateLastFailure: true
  values:
    user: 
      create: "true"
      email: "admin@yourdomain.com"
      password: "AgoodPassword"

    containerSecurityContext:
      enabled: true
      runAsNonRoot: false
      runAsUser: 0

    nginx:
      tolerations:
        - key: "node.kubernetes.io/sentry"
          operator: "Exists"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - dev-sentry

    sentry:
      cron:
        replicas: 1
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      worker:
        replicas: 1
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      web:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      ingestConsumer:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      ingestMetricsConsumerPerf:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      ingestMetricsConsumerRh:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      ingestReplayRecordings:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      postProcessForwardErrors:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      postProcessForwardTransactions:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      subscriptionConsumerEvents:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      subscriptionConsumerSessions:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      subscriptionConsumerTransactions:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry

    snuba:
      api:
        replicas: 1
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      consumer:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      outcomesConsumer:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      replacer:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      replaysConsumer:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      sessionsConsumer:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      subscriptionConsumerEvents:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      subscriptionConsumerSessions:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      subscriptionConsumerTransactions:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry
      transactionsConsumer:
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry

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

    clickhouse:
      tolerations:
        - key: "node.kubernetes.io/sentry"
          operator: "Exists"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - dev-sentry
      clickhouse:
        replicas: 1 # 3
        configmap:
          remote_servers:
            replica:
              backup:
                enabled: false
        persistentVolumeClaim:
          enabled: true
          dataPersistentVolume:
            accessModes:
            - ReadWriteOnce
            enabled: true
            storage: 50Gi
            # storageClassName: "csi-notfound"
          logsPersistentVolume:
            accessModes:
            - ReadWriteOnce
            enabled: true
            storage: 50Gi
            # storageClassName: "csi-notfound"
        tabix:
          enabled: false

    kafka:
      replicaCount: 3
      tolerations:
        - key: "node.kubernetes.io/sentry"
          operator: "Exists"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - dev-sentry
      volumePermissions: 
        enabled: true
      persistence:
        # storageClass: "csi-notfound"
        # existingClaim: sentry-kafka-data
      zookeeper:
        volumePermissions:
          enabled: true
        persistence:
          # storageClass: "csi-notfound"
          existingClaim: "sentry-zookeeper-data"
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry

    # zookeeper-clickhouse
    zookeeper:
      replicaCount: 1
      volumePermissions:
        enabled: true
      persistence:
        enabled: true
        # storageClass: "csi-notfound"
        existingClaim: "sentry-zookeeper-clickhouse-data"
      tolerations:
        - key: "node.kubernetes.io/sentry"
          operator: "Exists"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - dev-sentry

    sourcemaps:
      enabled: false
    # memcached:
    #   persistence:
    #     enabled: false
    #     # volumePermissions:
    #     #   enabled: true
    #     # storageClass: "csi-notfound"
    #   tolerations:
    #     - key: "node.kubernetes.io/sentry"
    #       operator: "Exists"
    #   affinity:
    #     nodeAffinity:
    #       requiredDuringSchedulingIgnoredDuringExecution:
    #         nodeSelectorTerms:
    #           - matchExpressions:
    #               - key: kubernetes.io/hostname
    #                 operator: In
    #                 values:
    #                   - dev-sentry

    postgresql:
      architecture: standalone
      volumePermissions:
        enabled: true
      auth:
        existingSecret: sentry-sentry-postgresql
      primary:
        persistence:
          # storageClass: "csi-notfound"
          existingClaim: sentry-postgresql-data
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry

    rabbitmq:
      replicaCount: 1
      podSecurityContext:
        enabled: true
        fsGroup: 1001
        runAsUser: 1001
      persistence:
        enabled: true
        # storageClass: "csi-notfound"
        existingClaim: sentry-rabbitmq-data
      serviceAccount:
        automountServiceAccountToken: true
        create: true
      volumePermissions:
        enabled: true
      tolerations:
        - key: "node.kubernetes.io/sentry"
          operator: "Exists"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - dev-sentry

    redis:
      architecture: standalone
      volumePermissions:
        enabled: true
      master:
        containerSecurityContext:
          enabled: true
          runAsUser: 0
        persistence:
          # storageClass: "csi-notfound"
          existingClaim: sentry-redis-data
        tolerations:
          - key: "node.kubernetes.io/sentry"
            operator: "Exists"
        affinity:
          nodeAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              nodeSelectorTerms:
                - matchExpressions:
                    - key: kubernetes.io/hostname
                      operator: In
                      values:
                        - dev-sentry

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

```

