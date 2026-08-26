## Zot

- <https://github.com/project-zot/zot>
- <https://zotregistry.dev/>

Zot 可以对多个容器镜像仓库代理

## 使用

新建一个基础配置

```json
{
  "storage": {
    "rootDirectory": "/var/lib/registry"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000"
  }
}
```

前台启动

```bash
zot serve /etc/zot/config.json
```

更多配置

```json
{
  # "distSpecVersion": "1.1.1",
  "storage": {
    "rootDirectory": "/var/lib/zot",
    "dedupe": true,
    "gc": true,
    "gcDelay": "24h",
    "gcInterval": "24h"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "8080",
    "realm": "zot-offline"
  },
  "log": {
    "level": "info",
    "output": "/var/log/zot/zot.log"
  }
}

```

- storage.rootDirectory：镜像存储目录，确保有足够磁盘空间
- storage.dedupe：启用去重，节省存储空间
- storage.gc：启用垃圾回收，自动清理未引用层
- http.address：绑定地址，`0.0.0.0`表示监听所有接口
- log.level：日志级别，生产环境建议使用`info`

## Zot 同步功能

```json
{
  "extensions": {
    "sync": {
      "registries": [
        {
          "urls": ["https://registry-1.docker.io"],
          "content": [
            {
              "prefix": "library/**"
            }
          ],
          "onDemand": false,
          "tlsVerify": true
        }
      ]
    }
  }
}

```

## 批量迁移

```bash
IMAGES=(
  "registry.k8s.io/kube-apiserver:v1.34.10"
  "registry.k8s.io/kube-controller-manager:v1.34.10"
  "registry.k8s.io/kube-scheduler:v1.34.10"
  "registry.k8s.io/kube-proxy:v1.34.10"
  "registry.k8s.io/coredns/coredns:v1.12.1"
  "registry.k8s.io/pause:3.10.1"
  "registry.k8s.io/etcd:3.6.5-0"
)

strip_registry() {
  local ref="$1" first="${1%%/*}"
  if [[ "$ref" == */* && ( "$first" == *.* || "$first" == *:* || "$first" == "localhost" ) ]]; then
    printf '%s' "${ref#*/}"
  else
    printf '%s' "$ref"
  fi
}

for img in "${IMAGES[@]}"; do
  stor_path=/registry/$(strip_registry "$img")
  if [[ ! -d $(dirname "${stor_path}") ]]; then
    mkdir -p "$(dirname "${stor_path}")"
  fi
  skopeo copy --override-arch amd64 --override-os linux --preserve-digests \
    "docker://${img}" "oci:/registry/$(strip_registry "$img")"
  # skopeo copy --override-arch amd64 --override-os linux --preserve-digests \
  #   docker://registry.k8s.io/kube-proxy:v1.34.10 oci:/registry/kube-proxy:v1.34.10
done

```

## 安全配置

TLS 证书

在离线环境中，使用自签名证书确保通信安全：

```json
{
  "http": {
    "address": "0.0.0.0",
    "port": "8443",
    "tls": {
      "cert": "/etc/zot/certs/server.crt",
      "key": "/etc/zot/certs/server.key"
    }
  }
}

```

认证授权

```json
{
  "http": {
    "auth": {
      "htpasswd": {
        "path": "/etc/zot/auth/htpasswd"
      }
    }
  }
}

# htpasswd -B -c /etc/zot/auth/htpasswd admin
```

启用监控指标

在配置文件中启用 Prometheus 指标：

```json
{
  "extensions": {
    "metrics": {
      "enable": true,
      "prometheus": {
        "path": "/metrics"
      }
    }
  }
}

```

日志轮转配置

使用 logrotate 管理日志文件：

```plain
# /etc/logrotate.d/zot
/var/log/zot/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 zot zot
}
```

UI

```json
{
  "extensions": {
    "search": {
      "enable": true
    },
    "ui": {
      "enable": true
    }
  }
}
```

## zot 磁盘布局

```bash
<rootDirectory>/
└── library/nginx/            # repo 名 = 目录路径，支持多级
    ├── oci-layout            # {"imageLayoutVersion":"1.0.0"}
    ├── index.json            # 每个 manifest 描述符带 org.opencontainers.image.ref.name = tag
    └── blobs/sha256/<hex>    # 注意：文件名直接是 hex，没有 /data 子目录

```

离线生成目录

```bash
# skopeo
skopeo copy --all docker://docker.io/library/nginx:1.25 \
  oci:/data/zot/library/nginx:1.25

# oras
oras cp -r docker.io/library/nginx:1.25 --to-oci-layout /data/zot/library/nginx:1.25

# crane
crane pull --format=oci docker.io/library/nginx:1.25 /data/zot/library/nginx

```

