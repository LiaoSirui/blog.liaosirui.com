## Operator 方案简介

- <https://github.com/zalando/postgres-operator>
  - postgres-operator 官方文档：<https://postgres-operator.readthedocs.io/en/latest/>
- <https://github.com/percona/percona-postgresql-operator>
- <https://github.com/CrunchyData/postgres-operator>

## Zalando Postgres Operator

Postgres Operator UI 提供了一个图形界面，方便用户体验数据库即服务。一旦 database 和/或 Kubernetes (K8s)  管理员设置了 operator，其他团队就很容易创建、克隆、监视、编辑和删除自己的 Postgres 集群

- 文档：<https://postgres-operator.readthedocs.io/en/latest/>

安装 operator

```bash
# Add the Zalando Helm repository

helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
helm repo update

# Install the operator
helm install postgres-operator postgres-operator-charts/postgres-operator \
  --namespace postgres-operator \
  --create-namespace

# Optionally install the UI
helm install postgres-operator-ui postgres-operator-charts/postgres-operator-ui \
  --namespace postgres-operator
```

### Basic Cluster

```yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: acid-postgres-cluster
  namespace: default
spec:
  teamId: "acid"
  volume:
    size: 10Gi
  numberOfInstances: 3
  users:
    myuser:
      - superuser
      - createdb
  databases:
    myapp: myuser
  postgresql:
    version: "16"
```

### Production-Ready Cluster

```yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: production-postgres
  namespace: production
  labels:
    environment: production
    team: platform
spec:
  teamId: "platform"

  # Cluster size
  numberOfInstances: 3

  # PostgreSQL version and Docker image
  postgresql:
    version: "16"
    parameters:
      # Memory settings
      shared_buffers: "2GB"
      effective_cache_size: "6GB"
      work_mem: "64MB"
      maintenance_work_mem: "512MB"

      # Connections
      max_connections: "300"

      # WAL
      wal_level: "replica"
      max_wal_size: "2GB"
      min_wal_size: "512MB"

      # Checkpoints
      checkpoint_completion_target: "0.9"

      # Query optimization
      random_page_cost: "1.1"
      effective_io_concurrency: "200"

      # Parallel queries
      max_parallel_workers_per_gather: "4"
      max_parallel_workers: "8"

      # Logging
      log_statement: "ddl"
      log_min_duration_statement: "1000"

  # Storage configuration
  volume:
    size: 100Gi
    storageClass: fast-ssd

  # Additional volumes for WAL
  additionalVolumes:
    - name: wal
      mountPath: /home/postgres/pgdata/pg_wal
      targetContainers:
        - postgres
      volumeSource:
        persistentVolumeClaim:
          claimName: wal-volume

  # Resource allocation
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"

  # Users and databases
  users:
    app_user:
      - login
      - createdb
    readonly_user:
      - login
    admin_user:
      - superuser
      - createdb
      - createrole

  databases:
    myapp: app_user
    analytics: app_user

  # Prepared databases with extensions
  preparedDatabases:
    myapp:
      defaultUsers: true
      extensions:
        uuid-ossp: public
        pg_stat_statements: public
        pgcrypto: public
      schemas:
        app:
          defaultUsers: true
          defaultRoles: true

  # Enable connection pooler
  enableConnectionPooler: true
  connectionPooler:
    numberOfInstances: 2
    mode: "transaction"
    schema: "pooler"
    user: "pooler"
    resources:
      requests:
        cpu: "500m"
        memory: "256Mi"
      limits:
        cpu: "1"
        memory: "512Mi"

  # Pod scheduling
  tolerations:
    - key: "database"
      operator: "Equal"
      value: "postgres"
      effect: "NoSchedule"

  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node-type
              operator: In
              values:
                - database

  # Patroni settings
  patroni:
    initdb:
      encoding: "UTF8"
      locale: "en_US.UTF-8"
      data-checksums: "true"
    pg_hba:
      - host all all 10.0.0.0/8 scram-sha-256
      - host all all 172.16.0.0/12 scram-sha-256
      - host all all 192.168.0.0/16 scram-sha-256
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 33554432  # 32MB

  # Sidecar containers
  sidecars:
    - name: exporter
      image: prometheuscommunity/postgres-exporter:v0.15.0
      ports:
        - name: metrics
          containerPort: 9187
          protocol: TCP
      env:
        - name: DATA_SOURCE_URI
          value: "localhost:5432/postgres?sslmode=disable"
        - name: DATA_SOURCE_USER
          value: "$(POSTGRES_USER)"
        - name: DATA_SOURCE_PASS
          value: "$(POSTGRES_PASSWORD)"
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "300m"
          memory: "512Mi"
```

### Monitoring

Servicemonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgres-metrics
  labels:
    team: platform
spec:
  selector:
    matchLabels:
      cluster-name: acid-postgres-cluster
  namespaceSelector:
    matchNames:
      - default
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```

PodMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: postgres-pod-monitor
spec:
  selector:
    matchLabels:
      cluster-name: acid-postgres-cluster
  podMetricsEndpoints:
    - port: metrics
      interval: 30s
```

### Password Rotation

```bash
# Generate new password
NEW_PASSWORD=$(openssl rand -base64 24)

# Update secret
kubectl patch secret myuser.acid-postgres-cluster.credentials.postgresql.acid.zalan.do \
  --type='json' \
  -p="[{\"op\": \"replace\", \"path\": \"/data/password\", \"value\": \"$(echo -n $NEW_PASSWORD | base64)\"}]"
```

### Backup Configuration

创建备份配置

```yaml
# In operator ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-operator
  namespace: postgres-operator
data:
  logical_backup_docker_image: "registry.opensource.zalan.do/acid/logical-backup:v1.10.1"
  logical_backup_s3_bucket: "my-postgres-backups"
  logical_backup_s3_region: "us-east-1"
  logical_backup_s3_endpoint: ""
  logical_backup_s3_access_key_id: "your-access-key"
  logical_backup_s3_secret_access_key: "your-secret-key"
  logical_backup_schedule: "0 0 * * *"  # Daily at midnight
```

集群启用备份

```yaml
spec:
  enableLogicalBackup: true
  logicalBackupSchedule: "0 0 * * *"
```

### WAL-E/WAL-G 归档

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-operator
  namespace: postgres-operator
data:
  # WAL-G settings
  wal_gs_bucket: "my-bucket"
  wal_s3_bucket: "my-bucket"
  aws_region: "us-east-1"

  # Enable continuous archiving
  enable_spilo_wal_path_compat: "true"

```

同样的配置 S3

```bash
kubectl create secret generic postgres-pod-env \
  --from-literal=AWS_ACCESS_KEY_ID=your-key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret \
  --from-literal=AWS_REGION=us-east-1 \
  --from-literal=WAL_S3_BUCKET=my-backup-bucket \
  -n postgres-operator
```

集群启用：

```yaml
spec:
  env:
    - name: WAL_S3_BUCKET
      value: "my-backup-bucket"
    - name: AWS_REGION
      value: "us-east-1"
    - name: USE_WALG_BACKUP
      value: "true"
    - name: USE_WALG_RESTORE
      value: "true"
    - name: BACKUP_SCHEDULE
      value: "0 0 * * *"
```

### 克隆集群

Clone from Existing Cluster

```yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres-clone
spec:
  teamId: "acid"
  numberOfInstances: 3
  volume:
    size: 100Gi
  postgresql:
    version: "16"

  clone:
    cluster: "acid-postgres-cluster"
    timestamp: "2026-01-20T12:00:00+00:00"  # Optional PITR
```

Clone from S3 Backup

```yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres-restored
spec:
  teamId: "acid"
  numberOfInstances: 3
  volume:
    size: 100Gi
  postgresql:
    version: "16"

  clone:
    cluster: "source-cluster"
    s3_wal_path: "s3://bucket/spilo/source-cluster/wal/"
    s3_endpoint: "https://s3.amazonaws.com"
    timestamp: "2026-01-20T12:00:00+00:00"

  env:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: access-key
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: secret-key
```

### HA 运维

检查集群状态

```bash
# Check Patroni status
kubectl exec acid-postgres-cluster-0 -- patronictl list

# Sample output:
# + Cluster: acid-postgres-cluster (7123456789012345678) ---+----+-----------+
# | Member                   | Host        | Role    | State     | TL | Lag in MB |
# +--------------------------+-------------+---------+-----------+----+-----------+
# | acid-postgres-cluster-0  | 10.0.0.10   | Leader  | running   | 3  |           |
# | acid-postgres-cluster-1  | 10.0.0.11   | Replica | streaming | 3  |       0.0 |
# | acid-postgres-cluster-2  | 10.0.0.12   | Replica | streaming | 3  |       0.0 |
# +--------------------------+-------------+---------+-----------+----+-----------+
```

手动切换

```bash
# Switchover to specific member
kubectl exec acid-postgres-cluster-0 -- patronictl switchover acid-postgres-cluster \
  --master acid-postgres-cluster-0 \
  --candidate acid-postgres-cluster-1 \
  --force
```

重启集群

```bash
# Rolling restart
kubectl exec acid-postgres-cluster-0 -- patronictl restart acid-postgres-cluster

# Restart specific member
kubectl exec acid-postgres-cluster-0 -- patronictl restart acid-postgres-cluster acid-postgres-cluster-1
```

查看集群事件

```bash
kubectl describe postgresql acid-postgres-cluster
kubectl get events --field-selector involvedObject.name=acid-postgres-cluster
```

复制延迟

```bash
# Check replication status
kubectl exec acid-postgres-cluster-0 -- patronictl list

# Check postgres replication
kubectl exec acid-postgres-cluster-0 -- psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

故障切换无法成功：

```bash
# Check Patroni configuration
kubectl exec acid-postgres-cluster-0 -- patronictl show-config

# Check pod distribution
kubectl get pods -l cluster-name=acid-postgres-cluster -o wide
```

