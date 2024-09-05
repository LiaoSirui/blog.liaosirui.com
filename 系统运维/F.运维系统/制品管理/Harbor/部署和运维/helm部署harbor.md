Harbor 官方提供了 Helm chart 仓库，可使用其来部署 Harbor

```bash
helm repo add harbor https://helm.goharbor.io
```

values 参考：

```yaml
# values-prod.yaml
externalURL: https://harbor.k8s.local
harborAdminPassword: Harbor12345
logLevel: debug

expose:
  type: ingress
  tls:
    enabled: true
  ingress:
    className: nginx  # 指定 ingress class
    hosts:
      core: harbor.k8s.local
      notary: notary.k8s.local

persistence:
  enabled: true
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      # 如果需要做高可用，多个副本的组件则需要使用支持 ReadWriteMany 的后端
      # 这里我们使用nfs，生产环境不建议使用nfs
      storageClass: "nfs-client"
      # 如果是高可用的，多个副本组件需要使用 ReadWriteMany，默认为 ReadWriteOnce
      accessMode: ReadWriteMany
      size: 5Gi
    chartmuseum:
      storageClass: "nfs-client"
      accessMode: ReadWriteMany
      size: 5Gi
    jobservice:
      storageClass: "nfs-client"
      accessMode: ReadWriteMany
      size: 1Gi
    trivy:
      storageClass: "nfs-client"
      accessMode: ReadWriteMany
      size: 2Gi

database:
  type: external
  external:
    host: "postgresql.kube-ops.svc.cluster.local"
    port: "5432"
    username: "gitlab"
    password: "passw0rd"
    coreDatabase: "harbor"
    notaryServerDatabase: "notary_server"
    notarySignerDatabase: "notary_signer"

redis:
  type: external
  external:
    addr: "redis.kube-ops.svc.cluster.local:6379"

# 默认为一个副本，如果要做高可用，只需要设置为 replicas >= 2 即可
portal:
  replicas: 1
core:
  replicas: 1
jobservice:
  replicas: 1
registry:
  replicas: 1
chartmuseum:
  replicas: 1
trivy:
  replicas: 1
notary:
  server:
    replicas: 1
  signer:
    replicas: 1
```

