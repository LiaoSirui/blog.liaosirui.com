启用 BuildKit 之后，可以使用下面几个新的 Dockerfile 指令来加快镜像构建

语法文档：https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md

## 声明 BuildKit

由于 BuildKit 为实验特性，每个 Dockerfile 文件开头都必须加上如下指令

```dockerfile
# syntax=docker/dockerfile:experimental
```

也可以使用指定版本的 buildkit

```bash
# syntax=docker/dockerfile:1.4.3
```

也可以将镜像存放到自己的仓库中

```dockerfile
# syntax=docker-registry.local.liaosirui.com:5000/third/docker.io/docker/dockerfile:1.4.3
```

## 卷挂载

### cache

几乎所有的程序都会使用依赖管理工具，例如 `Go` 中的 `go mod`、`Node.js` 中的 `npm` 等等，当我们构建一个镜像时，往往会重复的从互联网中获取依赖包，难以缓存，大大降低了镜像的构建效率

例如一个前端工程需要用到 `npm`：

```dockerfile
FROM node:alpine as builder

WORKDIR /app

COPY package.json /app/

RUN npm i --registry=https://registry.npm.taobao.org \
        && rm -rf ~/.npm

COPY src /app/src

RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /app/dist
```

使用多阶段构建，构建的镜像中只包含了目标文件夹 `dist`，但仍然存在一些问题，当 `package.json` 文件变动时，`RUN npm i && rm -rf ~/.npm` 这一层会重新执行，变更多次后，生成了大量的中间层镜像。

为解决这个问题，进一步的我们可以设想一个类似 **数据卷** 的功能，在镜像构建时把 `node_modules` 文件夹挂载上去，在构建完成后，这个 `node_modules` 文件夹会自动卸载，实际的镜像中并不包含 `node_modules` 这个文件夹，这样我们就省去了每次获取依赖的时间，大大增加了镜像构建效率，同时也避免了生成了大量的中间层镜像。

`BuildKit` 提供了 `RUN --mount=type=cache` 指令，可以实现上边的设想。

```dockerfile
# syntax=docker/dockerfile:experimental

FROM node:alpine as builder

WORKDIR /app

COPY package.json /app/

RUN --mount=type=cache,target=/app/node_modules,id=my_app_npm_module,sharing=locked \
    --mount=type=cache,target=/root/.npm,id=npm_cache \
        npm i --registry=https://registry.npm.taobao.org

COPY src /app/src

RUN --mount=type=cache,target=/app/node_modules,id=my_app_npm_module,sharing=locked \
  # --mount=type=cache,target=/app/dist,id=my_app_dist,sharing=locked \
  npm run build

FROM nginx:alpine

# COPY --from=builder /app/dist /app/dist

# 为了更直观的说明 from 和 source 指令，这里使用 RUN 指令
RUN --mount=type=cache,target=/tmp/dist,from=builder,source=/app/dist \
    # --mount=type=cache,target/tmp/dist,from=my_app_dist,sharing=locked \
    mkdir -p /app/dist && cp -r /tmp/dist/* /app/dist
```

第一个 `RUN` 指令执行后，`id` 为 `my_app_npm_module` 的缓存文件夹挂载到了 `/app/node_modules` 文件夹中。多次执行也不会产生多个中间层镜像。

第二个 `RUN` 指令执行时需要用到 `node_modules` 文件夹，`node_modules` 已经挂载，命令也可以正确执行。

第三个 `RUN` 指令将上一阶段产生的文件复制到指定位置，`from` 指明缓存的来源，这里 `builder` 表示缓存来源于构建的第一阶段，`source` 指明缓存来源的文件夹。

上面的 `Dockerfile` 中 `--mount=type=cache,...` 中指令作用如下：

| Option            | Description                                                  |
| :---------------- | :----------------------------------------------------------- |
| `id`              | `id` 设置一个标志，以便区分缓存。                            |
| `target` (必填项) | 缓存的挂载目标文件夹。                                       |
| `ro`,`readonly`   | 只读，缓存文件夹不能被写入。                                 |
| `sharing`         | 有 `shared` `private` `locked` 值可供选择。`sharing` 设置当一个缓存被多次使用时的表现，由于 `BuildKit` 支持并行构建，当多个步骤使用同一缓存时（同一 `id`）会发生冲突。`shared` 表示多个步骤可以同时读写，`private` 表示当多个步骤使用同一缓存时，每个步骤使用不同的缓存，`locked` 表示当一个步骤完成释放缓存后，后一个步骤才能继续使用该缓存。 |
| `from`            | 缓存来源（构建阶段），不填写时为空文件夹。                   |
| `source`          | 来源的文件夹路径。                                           |

### bind

该指令可以将一个镜像（或上一构建阶段）的文件挂载到指定位置

```dockerfile
RUN --mount=type=bind,from=php:alpine,source=/usr/local/bin/docker-php-entrypoint,target=/docker-php-entrypoint \
  cat /docker-php-entrypoint
```

### tmpfs

该指令可以将一个 `tmpfs` 文件系统挂载到指定位置

```dockerfile
RUN --mount=type=tmpfs,target=/temp \
        mount | grep /temp
```

### secret

该指令可以将一个文件（例如密钥）挂载到指定位置

```dockerfile
RUN --mount=type=secret,id=aws,target=/root/.aws/credentials \
        cat /root/.aws/credentials
```

### ssh

该指令可以挂载 `ssh` 密钥

```dockerfile
FROM alpine

RUN apk add --no-cache openssh-client

RUN \
	mkdir -p -m 0700 ~/.ssh ] \
	&& ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

RUN --mount=type=ssh \
	ssh git@gitlab.com | tee /hello
```

## 架构相关变量

### 与架构相关的变量

`Dockerfile` 支持如下架构相关的变量

- TARGETPLATFORM

构建镜像的目标平台，例如 `linux/amd64`, `linux/arm/v7`, `windows/amd64`。

- TARGETOS

`TARGETPLATFORM` 的 OS 类型，例如 `linux`, `windows`

- TARGETARCH

`TARGETPLATFORM` 的架构类型，例如 `amd64`, `arm`

- TARGETVARIANT

`TARGETPLATFORM` 的变种，该变量可能为空，例如 `v7`

- BUILDPLATFORM

构建镜像主机平台，例如 `linux/amd64`

- BUILDOS

`BUILDPLATFORM` 的 OS 类型，例如 `linux`

- BUILDARCH

`BUILDPLATFORM` 的架构类型，例如 `amd64`

- BUILDVARIANT

`BUILDPLATFORM` 的变种，该变量可能为空，例如 `v7`

### 例子

例如要构建支持 `linux/arm/v7` 和 `linux/amd64` 两种架构的镜像。假设已经生成了两个平台对应的二进制文件：

* `bin/dist-linux-arm`
* `bin/dist-linux-amd64`

那么 `Dockerfile` 可以这样书写：

```
FROM scratch

# 使用变量必须申明
ARG TARGETOS

ARG TARGETARCH

COPY bin/dist-${TARGETOS}-${TARGETARCH} /dist

ENTRYPOINT ["dist"]
```

## HEREDOC

Dockerfile 还支持 heredoc 语法。如果我们有多个 RUN 命令，那么我们可以使用 heredoc 如下所示的语法

```dockerfile
RUN <<EOF
apt-get update
apt-get upgrade -y
apt-get install -y ...
EOF
```

假设想从 Dockerfile 执行 python 脚本，可以使用以下语法

```dockerfile
RUN python3 <<EOF
with open("/hello", "w") as f:
    print("Hello", file=f)
    print("World", file=f)
EOF
```

还可以使用 heredoc 语法来创建文件。这是一个 Nginx 示例。

```dockerfile
FROM nginx

COPY <<EOF /usr/share/nginx/html/index.html
(your index page goes here)
EOF
```

写入多个文件

```dockerfile
COPY <<robots.txt <<humans.txt /usr/share/nginx/html/
(robots content)
robots.txt
(humans content)
humans.txt
```

