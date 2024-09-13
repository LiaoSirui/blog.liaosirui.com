Keycloak 基于官方镜像定制：

```dockerfile
# syntax=harbor.alpha-quant.cc:5000/3rd_party/docker.io/docker/dockerfile:1.5.2

# FROM harbor.alpha-quant.cc:5000/3rd_party/quay.io/keycloak/keycloak:24.0.1
FROM harbor.alpha-quant.cc:5000/3rd_party/docker.io/bitnami/keycloak:23.0.7-debian-12-r3

# COPY libs/keywind/theme/keywind /opt/keycloak/themes/keywind
COPY libs/keywind/theme/keywind /opt/bitnami/keycloak/themes/keywind
# git@gitlab.alpha-quant.cc:mirrors/github.com/lukin/keywind.git
```

使用如下的 values

```yaml
global:
  imagePullSecrets:
    - name: platform-oci-image-pull-secrets

image:
  registry: harbor.alpha-quant.cc
  repository: 3rd_party/registry.cn-chengdu.aliyuncs.com/alpha-quant/keycloak
  tag: "main-94e51b0-240320180624"
  pullPolicy: IfNotPresent

customNodeSelector: &customNodeSelector
  kubernetes.io/os: linux
  kubernetes.io/arch: amd64

customTolerations: &customTolerations
  - key: node.kubernetes.io/not-ready
    operator: Exists
    effect: NoExecute
    tolerationSeconds: 60
  - key: node.kubernetes.io/unreachable
    operator: Exists
    effect: NoExecute
    tolerationSeconds: 60
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
  - key: node-role.kubernetes.io/platform
    operator: Exists

customNodeAffinity: &customNodeAffinity
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
          - key: node-role.kubernetes.io/platform
            operator: In
            values:
              - ""

nodeSelector: *customNodeSelector
tolerations: *customTolerations
affinity:
  nodeAffinity: *customNodeAffinity

auth:
  adminUser: admin
  adminPassword: "mTVPlBoISOXK"

tls:
  enabled: false

production: true
proxy: edge
httpRelativePath: "/platform/keycloak/"

resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    cpu: 3
    memory: 1024Mi

ingress:
  enabled: true
  ingressClassName: "nginx"
  hostname: platform.alpha-quant.cc

logging:
  output: default
  level: ERROR

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    labels:
      monitoring.platform.io/manage-by: prometheus

postgresql:
  enabled: true
  auth:
    postgresPassword: "ILUiQh08nwy3"
    username: keycloak
    password: "YLIqhFBqBVHV"
    database: keycloak
  architecture: standalone
  image:
    registry: harbor.alpha-quant.cc
    repository: 3rd_party/docker.io/bitnami/postgresql
    tag: 16.2.0-debian-12-r8
  nodeSelector: *customNodeSelector
  tolerations: *customTolerations
  affinity:
    nodeAffinity: *customNodeAffinity
  primary:
    resources:
      requests:
        cpu: 300m
        memory: 512Mi
      limits:
        cpu: 2
        memory: 2Gi
    persistence:
      enabled: true
      storageClass: "nfs-client"
```

安装

```bash
#!/usr/bin/env bash


helm pull \
    oci://registry-1.docker.io/bitnamicharts/keycloak \
    --version 19.3.3

helm push --insecure-skip-tls-verify \
    keycloak-19.3.3.tgz \
    oci://harbor.alpha-quant.cc/3rd_party/charts

helm upgrade \
    --install \
    --history-max 3 \
    --namespace=keycloak-system \
    --create-namespace \
    -f ./values.yaml \
    keycloak \
    --version 19.3.3 \
    oci://harbor.alpha-quant.cc/3rd_party/charts/keycloak
```



官方：

- <https://www.keycloak.org/getting-started/getting-started-kube>

- <https://www.keycloak.org/operator/installation>

参考文档：

- <http://support.supermap.com.cn/DataWarehouse/WebDocHelp/iPortal/Subject_introduce/Security/otherSecurity/Keycloak_install_config.htm>

- <https://juejin.cn/post/6992006371684122631>

- <https://www.cnblogs.com/wuyongyin/p/16108032.html>

- <https://springdoc.cn/keycloak-custom-login-page/>