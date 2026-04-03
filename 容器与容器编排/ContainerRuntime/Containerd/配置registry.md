## 配置概述

镜像仓库配置文件由两大部分组成：`mirrors`和`configs`: 见 <https://github.com/containerd/containerd/blob/main/docs/cri/registry.md>

- Mirrors 是一个用于定义专用镜像仓库的名称和 endpoint 的指令
- Configs 部分定义了每个 mirror 的 TLS 和证书配置

```toml
version = 2

[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["https://registry-1.docker.io"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
      endpoint = ["https://gcr.io"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."gcr.io".auth]
      username = "_json_key"
      password = 'paste output from jq'
```



## 配置私有镜像仓库

mirror 配置就是一个反向代理，它把客户端的请求代理到 endpoint 配置的后端镜像仓库。mirror 名称可以随意填写，但是必须符合 IP 或域名的定义规则。并且可以配置多个 endpoint，默认解析到第一个 endpoint，如果第一个 endpoint 没有返回数据，则自动切换到第二个 endpoint，以此类推

## 非安全（http）私有仓库配置

配置非安全（http）私有仓库，只需要在 endpoint 中指定 http 协议头的地址即可。

在没有 TLS 通信的情况下，需要为 endpoints 指定 `http://`，否则将默认为 https。

## `hosts.toml`

文档：<https://github.com/containerd/containerd/blob/main/docs/hosts.md>

```bash
ctr images pull --hosts-dir "/etc/containerd/certs.d" myregistry.io:5000/image_name:tag
```

修改 `config.toml`（默认位置: `/etc/containerd/config.toml`）

```toml
version = 2

[plugins."io.containerd.grpc.v1.cri".registry]
   config_path = "/etc/containerd/certs.d"

```

通常存放在 `/etc/containerd/certs.d/<registry-domain>/hosts.toml`

DockerHub 加速，创建后的文件路径为`/etc/containerd/certs.d/docker.io/hosts.toml`。

```bash
server = "https://registry-1.docker.io"

[host."$(镜像加速器地址，如 https://nexus-mirror-01.alpha-quant.tech)"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true

```

绕开 TLS

```toml
server = "https://registry-1.docker.io"

[host."http://192.168.31.250:5000"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
```

