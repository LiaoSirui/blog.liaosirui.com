## 简介

https://zhuanlan.zhihu.com/p/472345879?utm_id=0



skopeo 是一个命令行实用程序，可对容器映像和映像存储库执行各种操作。

如果不想使用 docker 进行 images 镜像拉取上传，可以使用 skopeo 工具来完全替代 docker-cli 来搬运镜像。

skopeo 使用 API V2 Registry，例如 Docker Registry、Atomic Registry、私有Registry、本地目录和本地 OCI 镜像目录。skopeo 不需要运行守护进程，它可以执行的操作包括：

- 通过各种存储机制复制镜像，例如，可以在不需要特权的情况下将镜像从一个 Registry 复制到另一个 Registry
- 检测远程镜像并查看其属性，包括其图层，无需将镜像拉到本地
- 从镜像库中删除镜像
- 当存储库需要时，skopeo 可以传递适当的凭据和证书进行身份验证

## 项目信息

- Github 官方地址: <https://github.com/containers/skopeo>
- Gitee mirror: <https://gitee.com/mirrors/skopeo>

## 容器安装运行

Skopeo 容器镜像可在 `quay.io/skopeo/stable:latest` 获得, 例如我们采用 podman 命令进行如下操作:

```bash
podman run docker://quay.io/skopeo/stable:latest copy --help

# docker run -it --rm --privileged quay.io/skopeo/stable:latest copy --help
```

- 安装参考：<https://github.com/containers/skopeo/blob/main/install.md>

## 命令

其使用方法及其可用命令如下:

```text
> docker run -it --rm --privileged quay.io/skopeo/stable:latest --version
skopeo version 1.9.0

> docker run -it --rm --privileged quay.io/skopeo/stable:latest --help
Various operations with container images and container image registries

Usage:
  skopeo [flags]
  skopeo [command]

Available Commands:
# 复制一个镜像从 A 到 B, 这里的 A 和 B 可以为本地 docker 镜像或者 registry 上的镜像
  copy                                          Copy an IMAGE-NAME from one location to another
# 删除一个镜像 tag，可以是本地 docker 镜像或者 registry 上的镜像
  delete                                        Delete image IMAGE-NAME
# 帮助查看
  help                                          Help about any command
# 查看一个镜像的 manifest 或者 image config 详细信息
  inspect                                       Inspect image IMAGE-NAME
# 列出存储库名称指定的镜像的 tag
  list-tags                                     List tags in the transport/repository specified by the SOURCE-IMAGE
# 登陆某个镜像仓库, 类似于 docker login 命令
  login                                         Login to a container registry
# 退出某个已认证的镜像仓库, 类似于 docker logout 命令
  logout                                        Logout of a container registry
# 计算文件的清单摘要 sha256sum 值
  manifest-digest                               Compute a manifest digest of a file
# 使用本地文件创建签名
  standalone-sign                               Create a signature using local files
# 验证本地文件的签名
  standalone-verify                             Verify a signature using local files
# 将一个或多个 image 从一个位置同步到另一个位置
  sync                                          Synchronize one or more images from one location to another

Flags:
# 命令超时时间 (单位秒)
      --command-timeout duration   timeout for the command execution
# 启用 debug 模式
      --debug                      enable debug output
# 在不进行任何策略检查的情况下运行该工具（如果没有配置 policy 的话需要加上该参数）
      --insecure-policy            run the tool without any policy check
# 处理镜像时覆盖客户端 CPU 体系架构，如在 amd64 的机器上用 skopeo 处理 arm64 的镜像
      --override-arch ARCH         use ARCH instead of the architecture of the machine for choosing images
# 处理镜像时覆盖客户端 OS
      --override-os OS             use OS instead of the running OS for choosing images
# 处理镜像时使用 VARIANT 而不是运行架构变量
      --override-variant VARIANT   use VARIANT instead of the running architecture variant for choosing images
# 信任策略文件的路径 (为镜像配置安全策略情况下使用)
      --policy string              Path to a trust policy file
# 在目录中使用 Registry 配置文件（例如，用于容器签名存储）
      --registries.d DIR           use registry configuration files in DIR (e.g. for container signature storage)
# 用于存储临时文件的目录
      --tmpdir string              directory used to store temporary files
  -h, --help                       help for skopeo
  -v, --version                    Version for Skopeo

Use "skopeo [command] --help" for more information about a command.
```

测试环境说明：

```text
Docker 官方 hub 仓库 -> docker.io             # 官网地址: <https://hub.docker.com/>
临时创建的本地仓库     -> 192.168.31.100:5000   # docker run -itd -p 5000:5000 --name registry-tmp registry:2
```

为了防止后续执行 skopeo 命令操作镜像时出错, 建议忽略 policy 策略：

```bash
alias skopeo='skopeo --insecure-policy --tls-verify=false '
```

### Skopeo login / logout - 远程仓库 Auth

在使用 skopeo 前如果 src 或 dest 镜像是在 registry 仓库中的并且配置了非 public 的镜像需要相应的 auth 认证。

可以使用 docker login 或者 skopeo login 的方式登录到 registry 仓库，然后默认会在 ~/.docker 目录下生成 registry 登录配置文件 config.json，该文件里保存了登录需要的验证信息，skopeo 拿到该验证信息才有权限往 registry push 镜像。

```bash
# 实际上临时仓库没有配置认证, 账号密码随意即可
skopeo login --tls-verify=false -u anonymous -p anonymous 192.168.31.75:5000
```

### Skopeo inspect - 检查存储库中的镜像

skopeo 能够检查容器 Registry 上的存储库并获取图像层。

检查命令获取存储库的清单，能够向您显示有关整个存储库或标签的类似 docker inspect 的 json 输出。

与 docker inspect 相比，此工具可帮助在拉取存储库或标签之前收集有用的信息(使用磁盘空间)，检查命令可以显示给定存储库可用的标签、映像具有的标签、映像的创建日期和操作系统等。

支持传输的类型：`containers-storage, dir, docker, docker-archive, docker-daemon, oci, oci-archive, ostree, tarball`

- 显示 busybox:latest 镜像的属性相关信息

```bash
skopeo inspect docker://docker.io/busybox:latest
```

```json
{
    "Name": "docker.io/library/busybox",
    "Digest": "sha256:ef320ff10026a50cf5f0213d35537ce0041ac1d96e9b7800bafd8bc9eff6c693",
    "RepoTags": [
        ....
        "1.35.0",
        "1.35.0-glibc",
        "1.35.0-musl",
        "1.35.0-uclibc",
        "buildroot-2013.08.1",
        "buildroot-2014.02",
        ...
    ],
    "Created": "2022-07-29T20:26:22.673054623Z",
    "DockerVersion": "20.10.12",
    "Labels": null,
    "Architecture": "amd64",
    "Os": "linux",
    "Layers": [
        "sha256:50783e0dfb64b73019e973e7bce2c0d5a882301b781327ca153b876ad758dbd3"
    ],
    "Env": [
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ]
}
```

- 显示 busybox:latest 镜像的容器配置相关信息

```bash
skopeo inspect --config docker://docker.io/busybox:latest | jq
```

```json
{
  "created": "2022-07-29T20:26:22.673054623Z",
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": [
      "sh"
    ]
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:084326605ab6715ca698453e530e4d0319d4e402b468894a06affef944b4ef04"
    ]
  },
  "history": [
    {
      "created": "2022-07-29T20:26:22.583424528Z",
      "created_by": "/bin/sh -c #(nop) ADD file:03ed8a1a0e4c80308b22305fe0d00ebbb9e1f626c2b2fd91d3a50a98fc11b2f7 in / "
    },
    {
      "created": "2022-07-29T20:26:22.673054623Z",
      "created_by": "/bin/sh -c #(nop)  CMD [\"sh\"]",
      "empty_layer": true
    }
  ]
}
```

- 显示指定格式的 image digest（摘要）

```bash
skopeo inspect --format "Name: {{.Name}} Digest: {{.Digest}}" docker://docker.io/busybox:latest
```

```text
Name: docker.io/library/busybox Digest: sha256:ef320ff10026a50cf5f0213d35537ce0041ac1d96e9b7800bafd8bc9eff6c693
```

### Skopeo copy - 仓库镜像拷贝

skopeo 可以在各种存储机制之间复制容器镜像，支持包括容器仓库 (The Quay, Docker Hub, OpenShift, GCR, ，Artifactory ...) 以及容器存储后端 (Podman, CRI-O, Docker) 等、本地目录、本地 OCI-layout 目录。

- 从 registry A 到 registry B 复制 busybox:latest 镜像

```bash
skopeo copy \
  --insecure-policy --src-tls-verify=false --dest-tls-verify=false \
  --dest-authfile /root/.docker/config.json \
  docker://docker.io/busybox:latest docker://192.168.31.100:5000/devops/busybox:latest
```

```text
Getting image source signatures
Copying blob 50783e0dfb64 done  
Copying config 7a80323521 done  
Writing manifest to image destination
Storing signatures
```

由上述日志可以看到 skopeo 是直接从 registry 中 copy 镜像 layer 的 blob 文件，传输是镜像在 registry 中存储的原始格式

- 从 registry B 复制 busybox:latest 镜像到本地 busybox:latest 目录中

```bash
skopeo copy \
  --insecure-policy --src-tls-verify=false \
  docker://192.168.31.100:5000/devops/busybox:latest dir:busybox:latest
```

```bash
> tree busybox:latest

busybox:latest
├── 50783e0dfb64b73019e973e7bce2c0d5a882301b781327ca153b876ad758dbd3 # blob 块文件
├── 7a80323521ccd4c2b4b423fa6e38e5cea156600f40cd855e464cc52a321a24dd # 镜像配置信息文件
├── manifest.json # 镜像的 manifest 文件
└── version

0 directories, 4 files
```

- 将 busybox:latest 镜像从 registry B 复制到本地目录，并以 OCI 格式保存

```bash
skopeo copy \
  --insecure-policy --src-tls-verify=false \
  docker://192.168.31.100:5000/devops/busybox:latest oci:busybox:latest
```

```bash
> tree busybox

busybox
├── blobs
│   └── sha256
│       ├── 50783e0dfb64b73019e973e7bce2c0d5a882301b781327ca153b876ad758dbd3 # Blob 块
│       ├── 84016b10d6ad983b67f95a3f6cfc993e074923a865840adec4c4ebe7fd51c511
│       └── b07775592c9e68db93e71eba8e1a8277b3041e9d115fb6bd745409b138bc928c
├── index.json
└── oci-layout

2 directories, 5 files
```

- 将镜像从 docker 本地存储 push 到 registry B中 （实际上替代 docker push 功能）

```bash
skopeo copy \
  --insecure-policy --dest-tls-verify=false \
  --dest-authfile /root/.docker/config.json \
  docker-daemon:openresty/openresty:1.21.4.1-2-alpine docker://192.168.31.100:5000/openresty/openresty:1.21.4.1-2-alpine
```

### Skopeo sync - 镜像同步命令

Skopeo sync 可以在容器仓库和本地目录之间同步镜像，其功能类似于阿里云的 image-syncer (<https://github.com/AliyunContainerService/image-syncer>) 工具, 实际上其比 image-syncer 更强大、灵活性更强

- 将仓库中所有 busybox 镜像版本同步到本地目录

```bash
skopeo sync \
  --insecure-policy --src-tls-verify=false \
  --src docker --dest dir \
  192.168.31.100:5000/devops/busybox /tmp
```

```text
INFO[0000] Tag presence check                            imagename="192.168.31.100:5000/devops/busybox" tagged=false
INFO[0000] Getting tags                                  image="192.168.31.100:5000/devops/busybox"
INFO[0000] Copying image ref 1/1                         from="docker://192.168.31.100:5000/devops/busybox:latest" to="dir:/tmp/busybox:latest"
Getting image source signatures
Copying blob 50783e0dfb64 done
Copying config 7a80323521 done
Writing manifest to image destination
Storing signatures
INFO[0000] Synced 1 images from 1 sources

```

```text
> tree /tmp/busybox:latest

/tmp/busybox:latest
├── 50783e0dfb64b73019e973e7bce2c0d5a882301b781327ca153b876ad758dbd3
├── 7a80323521ccd4c2b4b423fa6e38e5cea156600f40cd855e464cc52a321a24dd
├── manifest.json
└── version

0 directories, 4 files

```

- 从本地目录 /tmp/ 同步到 docker 的 hub 容器仓库

```bash
skopeo sync \
  --insecure-policy --dest-tls-verify=false \
  --src dir --dest docker \
  /tmp 192.168.31.100:5000/devops/busybox1
```

```text
INFO[0000] Copying image ref 1/1                         from="dir:/tmp/busybox:latest" to="docker://192.168.31.100:5000/devops/busybox1/busybox:latest"
Getting image source signatures
Copying blob 50783e0dfb64 skipped: already exists
Copying config 7a80323521 done
Writing manifest to image destination
Storing signatures
INFO[0000] Synced 1 images from 1 sources

```

- 还可以在不同的仓库之间同步

```bash
skopeo sync \
  --insecure-policy --src-tls-verify=false --dest-tls-verify=false \
  --src docker --dest docker \
  docker.io/busybox:1.35 192.168.31.100:5000/
```

```text
INFO[0000] Tag presence check                            imagename="docker.io/busybox:1.35" tagged=true
INFO[0000] Copying image ref 1/1                         from="docker://busybox:1.35" to="docker://192.168.31.100:5000/busybox:1.35"
Getting image source signatures
Copying blob aa49f28a0db9 done
Copying config 2a2aa8b20c done
Writing manifest to image destination
Storing signatures
INFO[0013] Synced 1 images from 1 sources
```

- 以配置文件方式进行同步

首先我们需要准备一个需要同步的资源清单

```yaml
registry.example.com:
  images:
    busybox: []
    redis:
      - "1.0"
      - "2.0"
      - "sha256:111111"
  images-by-tag-regex:
      nginx: ^1\.13\.[12]-alpine-perl$
  credentials:
    username: john
    password: this is a secret
  tls-verify: true
  cert-dir: /home/john/certs
quay.io:
  tls-verify: false
  images:
    coreos/etcd:
      - latest
```

skopeo-sync.yml 文件中镜像匹配复制镜像说明:

1. registry.example.com/busybox : 所有版本的镜像
2. registry.example.com/redis : 标记为“1.0”和“2.0”的图像以及带有摘要的图像"sha256:0000000000000000000000000000000011111111111111111111111111111111"
3. registry.example.com/nginx : 镜像标记为“1.13.1-alpine-perl”和“1.13.2-alpine-perl”
4. quay.io/coreos/etcd : 拉取最新版本的镜像

以 yaml 文件方式进行同步镜像到 `my-registry.local.lan/repo/` 仓库中

```bash
skopeo sync \
  --src yaml --dest docker \
  skopeo-sync.yml my-registry.local.lan/repo/
```

### Skopeo delete - 删除仓库中镜像 Tag

使用该命令我们可以删除镜像 Tag。

注意此处仅仅只是通过 registry API 来删除镜像的 tag（即删除了 tag 对 manifests 文件的引用）并非真正将镜像删除掉，如果想要删除镜像的 layer 还是需要通过 registry GC 的方式。

```bash
skopeo delete docker://192.168.31.100:5000/devops/busybox:latest --debug

# 利用 curl 命令进行 registry 进行删除 Tag
curl --header "Accept: application/vnd.docker.distribution.manifest.v2+json" -I -X GET http://192.168.31.100:5000/v2/busybox/manifests/latest

# 
export Docker-Content-Digest=$(curl -s --header "Accept: application/vnd.docker.distribution.manifest.v2+json" -I -X GET http://192.168.31.100:5000/v2/busybox/manifests/latest | grep "Docker-Content-Digest" | cut -d ' ' -f 2)
curl -I -X DELETE http://192.168.31.100:5000/v2/busybox/manifests/${Docker-Content-Digest}
```
