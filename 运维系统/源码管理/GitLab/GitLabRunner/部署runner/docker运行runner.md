## Docker 运行

和 k8s 部署 runner 相比，Docker 部署 runner 的优势

- 缓存，项目里用到的各种依赖，不可能每次都重新下载。同时构建应用、语法检测等也会产生缓存文件
- 某个项目在 k8s runner 中使用分布式存储来保存这些文件，大概 700m。每次使用时特别慢，大部分时间都花在下载缓存，解压缓存，流水线结束时压缩缓存，上传缓存
- 整个流水线跑下来需要 10 多分钟，但如果用 docker 部署的 runner，时间将减少到 3  分钟。主要原因是因为使用挂载本地目录的形式来保存缓存文件，而不是使用 gitlab  的缓存关键字，从而跳过了上面提到的下载、解压、压缩、上传缓存文件这几个耗时的步骤
- 在 k8s 中部署 runner 也可以选择挂载 hostPath 存储卷，不过那样的话，k8s 灵活调度，充分利用资源的特性就用不到了。同时部署复杂度还提升不少，得不偿失

## 部署过程

```yaml
x-extras: &extras
  restart: unless-stopped
  networks:
    - public
  logging:
    driver: "json-file"
    options:
      max-size: "1m"
      max-file: "1"

networks:
  public:
    name: public
    external: true

services:
  gitlab-runner:
    image: registry.gitlab.com/gitlab-org/gitlab-runner:alpine-v18.5.0
    container_name: gitlab-runner
    volumes:
      - "./config:/etc/gitlab-runner"
      - "/data/gitlab-runner-manager/cache:/tmp/cache"
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      resources:
        limits:
          cpus: "2.00"
          memory: 4G
    <<: *extras

```

初始化命令

```bash
# 不再支持
# --tag-list="docker-runner" \
# --run-untagged="true" \
# --locked="false" \
# --access-level="not_protected" \
docker compose run -it --rm gitlab-runner \
  register \
  --non-interactive \
  --url="https://gitlab.alpha-quant.tech" \
  --token="$RUNNER_TOKEN" \
  --executor="docker" \
  --docker-image="harbor.alpha-quant.tech/3rd_party/docker.io/library/alpine:3.19.8" \
  --description="docker-runner" \
  --request-concurrency=10 \
  --docker-volumes="/var/run/docker.sock:/var/run/docker.sock" \
  --docker-volumes="/data/gitlab-runner/builds:/builds" \
  --docker-volumes="/data/gitlab-runner/cache:/cache" \
  --docker-pull-policy="if-not-present"
```

进入 config 目录，会发现一个 config.toml 文件，里面是 gitlab-runner 相关的配置信息

```toml
concurrent = 1
check_interval = 0
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "docker-runner"
  url = "https://gitlab.alpha-quant.tech"
  id = 1
  token = "glrt-h22AT0Z_Z1qwYp2mI6bYTW86MQp0OjEKdTo2Cw.01.1212bkzkg"
  token_obtained_at = 2025-10-24T09:40:44Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker"
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "harbor.alpha-quant.tech/3rd_party/docker.io/library/alpine:3.19.8"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/data/gitlab-runner/builds:/builds", "/data/gitlab-runner/cache:/cache"]
    pull_policy = ["if-not-present"]
    shm_size = 0
    network_mtu = 0

```

- `concurrent`：默认为 1，结合服务器配置自行修改

- 用于每个流水线容器都会挂载的目录，实现缓存功能的关键：`[runners.docker]` 下的 volumes 更改为

  ```yaml
  volumes:
    - "/var/run/docker.sock:/var/run/docker.sock"
    - "/data/gitlab-runner/builds:/builds"
    - "/data/gitlab-runner/cache:/cache"
    # 以下 cache 建议在各个项目中声明
    # - "/data/gitlab-runner/data/maven/.m2:/root/.m2"
    # - "/data/gitlab-runner/data/go-mode/mod:/go/pkg/mod"
  
  ```

- 修改镜像拉取策略，`[runners.docker]` 下增加

  ```yaml
  pull_policy = "if-not-present"
  ```

然后启动 runner 即可
