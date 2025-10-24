## Runner 的并发性

1. 每个 job 会单独起一个容器
2. 不同流水线的 job 是并行处理
3. 同一流水线同一阶段的 job 也是并行处理

## 安装过程

### 同步 chart

```bash
#!/usr/bin/env bash

# helm repo add gitlab https://charts.gitlab.io
# helm search repo gitlab

helm pull \
    --repo https://charts.gitlab.io \
    gitlab-runner \
    --version v0.82.0

helm push --insecure-skip-tls-verify \
    gitlab-runner-0.82.0.tgz \
    oci://harbor.alpha-quant.tech/3rd_party/charts

```

### runner 镜像注入自签证书

Runner 注入自签证书

```dockerfile
FROM harbor.alpha-quant.tech/3rd_party/registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.5.0

COPY certs/alpha-quant.tech.CA.crt \
    /usr/local/share/ca-certificates/alpha-quant.tech.CA.crt
RUN update-ca-certificates

```

helper 镜像也要注入

```dockerfile
FROM harbor.alpha-quant.tech/3rd_party/registry.gitlab.com/gitlab-org/gitlab-runner/gitlab-runner-helper:x86_64-b72e108d

COPY certs/alpha-quant.tech.CA.crt \
    /usr/local/share/ca-certificates/alpha-quant.tech.CA.crt
RUN update-ca-certificates

```

### 部署 values

- 注意要预先填写 runnerToken

- 这里选用本地存储，也可以选用 S3 作为 cache（直接挂载目录来实现缓存功能是最高效的，而不是使用 gitlab 的缓存关键字。所以建议使用 Docker 安装 Gitlab Runner，并通过挂载目录实现缓存功能）

```yaml
image:
  registry: harbor.alpha-quant.tech
  image: 3rd_party/registry.gitlab.com/gitlab-org/gitlab-runner
  tag: alpine-v18.5.0

imagePullSecrets:
  - name: "image-pull-secrets"

gitlabUrl: https://gitlab.alpha-quant.tech

runnerToken: "JxzhgJy3jiyDYD2-djVP"

unregisterRunners: true

concurrent: 10

rbac:
  create: true
  imagePullSecrets:
    - name: "image-pull-secrets"

replicas: 3

runners:
  privileged: true
  config: |
    [[runners]]
        [runners.kubernetes]
            helper_image                 = "gitlab-runner-helper:main-latest"
            image                        = "pipeline-runner:main-latest"
            image_pull_secrets           = ["image-pull-secrets"]
            namespace                    = "{{.Release.Namespace}}"
            pod_labels_overwrite_allowed = "true"
            [runners.kubernetes.node_selector]
                "node-role.kubernetes.io/gitlab-runner" = ""
            [runners.kubernetes.node_tolerations]
                "node-role.kubernetes.io/gitlab-runner" = ""
                "node-role.kubernetes.io/control-plane" = ""
            [[runners.kubernetes.volumes.host_path]]
                host_path  = "/var/run/docker.sock"
                mount_path = "/var/run/docker.sock"
                name       = "docker"
                read_only  = true
            [[runners.kubernetes.volumes.host_path]]
                host_path  = "/data/gitlab-runner/builds"
                mount_path = "/builds"
                name       = "builds"
            [[runners.kubernetes.volumes.host_path]]
                host_path  = "/data/gitlab-runner/cache"
                mount_path = "/cache"
                name       = "cache"
            [[runners.kubernetes.volumes.secret]]
                mount_path = "/root/.docker/config.json"
                name       = "image-pull-secrets"
                sub_path   = ".dockerconfigjson"

nodeSelector:
  kubernetes.io/os: linux
  kubernetes.io/arch: amd64

tolerations:
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
  - key: node-role.kubernetes.io/gitlab-runner
    operator: Exists

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node-role.kubernetes.io/gitlab-runner
              operator: In
              values:
                - ""

```

### 安装 chart

```bash
helm \
    upgrade \
    --insecure-skip-tls-verify=true \
    --history-max 3 \
    --plain-http=true \
    --install \
    --namespace=gitlab-runner \
    -f ./values.yaml \
    gitlab-runner \
    --version 0.82.0 \
    oci://harbor.alpha-quant.tech/3rd_party/charts/gitlab-runner 

```

