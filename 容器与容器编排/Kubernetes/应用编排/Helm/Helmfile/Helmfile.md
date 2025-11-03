## helmfile 简介

Helm 是 kubernetes 的包管理工具。在实际的使用场景中我们涉及同时部署多个chart、区分不同的部署环境、版本控制等需求。基于此需求，可以使用 helmfile 工具。

Helmfile 通过 helmfile 文件帮助用户管理和维护多个 helm chart，可以来区分环境、实现版本控制。

官方：

- Github 仓库：<https://github.com/helmfile/helmfile>

<https://mp.weixin.qq.com/s/5SAth6TjyvbLmDjHcxTWgw>

## 安装 helmfile

helmfile 提供了多种安装方式，具体可以参考：

- <https://github.com/helmfile/helmfile/releases>
- <https://github.com/helmfile/helmfile#installation>

```bash
cd $(mktemp -d)
curl -sL https://github.com/helmfile/helmfile/releases/download/v0.150.0/helmfile_0.150.0_linux_amd64.tar.gz \
  -o helmfile.tgz
tar zxvf helmfile.tgz    
chmod +x helmfile
mv helmfile /usr/local/bin/
```

Helmfile 还支持运行在容器中，可以很方便的集成到 CI/CD 的流程中：

```bash
# helm 2
docker run \
  --rm \
  --net=host \
  -v "${HOME}/.kube:/root/.kube" \
  -v "${HOME}/.helm:/root/.helm" \
  -v "${PWD}:/wd" \
  --workdir /wd \
  quay.io/roboll/helmfile:v0.150.0 helmfile sync

# helm 3
docker run \
  --rm \
  --net=host \
  -v "${HOME}/.kube:/root/.kube" \
  -v "${HOME}/.config/helm:/root/.config/helm" \
  -v "${PWD}:/wd" \
  --workdir /wd \
  quay.io/roboll/helmfile:helm3-v0.150.0 helmfile sync
```

## helmfile.yaml 介绍

helmfile.yaml 是 helmfile 的核心文件，其用来声明所有的配置。

可以参考官方文档：<https://github.com/roboll/helmfile#configuration>

```yaml
# 声明 repo 配置
repositories:
- name: <repo-name>
  # url: repo url
  # 可以设置基础配置 或 tls 认证
  # certFile: certificate 文件
  # keyFile: key 文件
  # username: 用户名
  # password: 密码

# helm 二进制文件的路径
helmBinary: path/to/helm3

# helm 的一些默认设置，这些配置与 `helm SUBCOMMAND` 相同，可以通过这个配置声明一些，默认的配置
helmDefaults:
  tillerNamespace: tiller-namespace  #dedicated default key for tiller-namespace
  tillerless: false                  #dedicated default key for tillerless
  kubeContext: kube-context          #dedicated default key for kube-context (--kube-context)
  cleanupOnFail: false               #dedicated default key for helm flag --cleanup-on-fail
  # additional and global args passed to helm (default "")
  args:
    - "--set k=v"
  # verify the chart before upgrading (only works with packaged charts not directories) (default false)
  verify: true
  # wait for k8s resources via --wait. (default false)
  wait: true
  # time in seconds to wait for any individual Kubernetes operation (like Jobs for hooks, and waits on pod/pvc/svc/deployment readiness) (default 300)
  timeout: 600
  # performs pods restart for the resource if applicable (default false)
  recreatePods: true
  # forces resource update through delete/recreate if needed (default false)
  force: false
  # when using helm 3.2+, automatically create release namespaces if they do not exist (default true)
  createNamespace: true
  ...

# 为 helmfile 中所有的 release 设置相同的 label，可用于为所有 release 标记相同的版本
commonLabels:
  hello: world

# 设置 release 配置（支持多 release）
releases:
  # 远程 chart 示例（chart 已经上传到 remote 仓库）
  - name: vault                            # name of this release
    namespace: vault                       # target namespace
    createNamespace: true                  # helm 3.2+ automatically create release namespace (default true)
    labels:                                # Arbitrary key value pairs for filtering releases
      foo: bar
    chart: roboll/vault-secret-manager     # the chart being installed to create this release, referenced by `repository/chart` syntax
    version: ~1.24.1                       # the semver of the chart. range constraint is supported
    condition: vault.enabled               # The values lookup key for filtering releases. Corresponds to the boolean value of `vault.enabled`, where `vault` is an arbitrary value
    missingFileHandler: Warn # set to either "Error" or "Warn". "Error" instructs helmfile to fail when unable to find a values or secrets file. When "Warn", it prints the file and continues.
    # Values files used for rendering the chart
    values:
      # Value files passed via --values
      - vault.yaml
      # Inline values, passed via a temporary values file and --values, so that it doesn't suffer from type issues like --set
      - address: https://vault.example.com
      # Go template available in inline values and values files.
      - image:
          # The end result is more or less YAML. So do `quote` to prevent number-like strings from accidentally parsed into numbers!
          # See https://github.com/roboll/helmfile/issues/608
          tag: {{ requiredEnv "IMAGE_TAG" | quote }}
          # Otherwise:
          #   tag: "{{ requiredEnv "IMAGE_TAG" }}"
          #   tag: !!string {{ requiredEnv "IMAGE_TAG" }}
        db:
          username: {{ requiredEnv "DB_USERNAME" }}
          # value taken from environment variable. Quotes are necessary. Will throw an error if the environment variable is not set. $DB_PASSWORD needs to be set in the calling environment ex: export DB_PASSWORD='password1'
          password: {{ requiredEnv "DB_PASSWORD" }}
        proxy:
          # Interpolate environment variable with a fixed string
          domain: {{ requiredEnv "PLATFORM_ID" }}.my-domain.com
          scheme: {{ env "SCHEME" | default "https" }}
    # Use `values` whenever possible!
    # `set` translates to helm's `--set key=val`, that is known to suffer from type issues like https://github.com/roboll/helmfile/issues/608
    set:
    # single value loaded from a local file, translates to --set-file foo.config=path/to/file
    - name: foo.config
      file: path/to/file
    # set a single array value in an array, translates to --set bar[0]={1,2}
    - name: bar[0]
      values:
      - 1
      - 2
    # set a templated value
    - name: namespace
      value: {{ .Namespace }}
    # will attempt to decrypt it using helm-secrets plugin
    
  # 本地 chart 示例（chart 保存在本地）
  - name: grafana                            # name of this release
    namespace: another                       # target namespace
    chart: ../my-charts/grafana              # the chart being installed to create this release, referenced by relative path to local helmfile
    values:
    - "../../my-values/grafana/values.yaml"             # Values file (relative path to manifest)
    - ./values/{{ requiredEnv "PLATFORM_ENV" }}/config.yaml # Values file taken from path with environment variable. $PLATFORM_ENV must be set in the calling environment.
    wait: true

# 可以嵌套其他的 helmfiles，支持从本地和远程拉取 helmfile
helmfiles:
- path: path/to/subhelmfile.yaml
  # label 选择器可以过滤需要覆盖的 release
  selectors:
  - name=prometheus
  # 覆盖 value
  values:
  # 使用文件覆盖
  - additional.values.yaml
  # 覆盖单独的 key
  - key1: val1
- # 远程拉取配置
  path: git::https://github.com/cloudposse/helmfiles.git@releases/kiam.yaml?ref=0.40.0
# 如果指向不存在路径，则打印告警错误
missingFileHandler: Error

# 多环境管理
environments:
  # 当没有设置 `--environment NAME` 时，使用 default 
  default:
    values:
    # 内容可以是文件路径或者 key:value
    - environments/default/values.yaml
    - myChartVer: 1.0.0-dev
  # "production" 环境，当设置了 `helmfile --environment production sync` 时
  production:
    values:
    - environment/production/values.yaml
    - myChartVer: 1.0.0
    # disable vault release processing
    - vault:
        enabled: false
    ## `secrets.yaml` is decrypted by `helm-secrets` and available via `{{ .Environment.Values.KEY }}`
    secrets:
    - environment/production/secrets.yaml
    # 当占不到 `environments.NAME.values` 时，可以设置为 "Error", "Warn", "Info", "Debug"，默认是 "Error"
    missingFileHandler: Error

# 分层管理，可以将所有文件合并，顺序为：environments.yaml <- defaults.yaml <- templates.yaml <- helmfile.yaml
bases:
- environments.yaml
- defaults.yaml
- templates.yaml

# API 功能
apiVersions:
- example/v1
```

- Helm 调试

这里，编排好相关的 helmfile 后，我们可以使用下面的命令进行调试

```bash
# 查看目录结构
> ls
README.org    environments  helm          helmfile      helmfile.yaml releases

# 查看 helmfile.yaml
> cat helmfile.yaml
environments:
  # 不指定环境时，默认使用默认测试环境
  default:
    values:
       - environments/test/config.yaml
       - environments/test/versions.yaml
       - environments/test//namespaces.yaml
    secrets:
       - environments/test/secrets.yaml
  test:
    values:
      - environments/test/config.yaml
      - environments/test/versions.yaml
      - environments/test/namespaces.yaml
    secrets:
       - environments/test/secrets.yaml
helmDefaults:
  createNamespace: true
releases:
  - name: password-secrets
    kubeContext: {{ .Values.kubeContext.service }}
    namespace: {{ .Values.namespaces.service }}
    chart: helm/charts/secrets
    values:
      - releases/secrets.yaml.gotmpl
    labels:
      app: secrets

  - name: web
    kubeContext: {{ .Values.kubeContext.business }}
    namespace: {{ .Values.namespaces.business }}
    chart: helm/charts/web
    values:
      - releases/web.yaml.gotmpl
    labels:
      app: web

# helmfile 调试
> helmfile -e test template 
```

- 安装 Chart

```bash
helmfile -e test sync
```

- helmfile 更新或者删除某个 Chart

这里可以通过 `--selector` 指定 label 来进行更新或者删除：

```bash
# 更新 web 服务
helmfile -e test --selector app=web sync

# 删除 web 服务
helmfile -e test --selector app=web delete
```

- 查看变更

```bash
# 查看文件的变更信息
helmfile -e test --selector app=web diff

# 只查看文件的变更部分信息
helmfile -e test --selector app=web diff --context 4
```

