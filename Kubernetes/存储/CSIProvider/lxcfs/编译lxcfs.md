添加为项目子模块

```bash
git submodule add --force https://github.com/lxc/lxcfs.git lib/lxcfs

git submodule update --init  
```

将子模块切换到最新的分支

```bash
cd lib/lxcfs

git checkout lxcfs-5.0.2
```

添加 dockerfile 文件

```bash
mkdir -p docker/build

touch docker/build/Dockerfile
```

Dockerfile 内容如下（基于 centos 7 进行编译）

```dockerfile
# syntax=dockerhub.bigquant.ai:5000/aipaas-devops/3rdparty/docker.io/docker/dockerfile:1.4

ARG APP_VERSION=v5.0.2

ARG THIRDPARTY_REPO=dockerhub.bigquant.ai:5000/aipaas-devops/3rdparty

FROM --platform=$TARGETPLATFORM dockerhub.bigquant.ai:5000/dockerstacks/centos-base:master_latest as builder

ARG AIPAAS_UID=1713
ARG AIPAAS_GID=1713

COPY lib/lxcfs /app/lxcfs

WORKDIR /app/lxcfs

RUN --mount=type=cache,target=/var/cache,id=buildx-cache \
    --mount=type=cache,target=/tmp,id=build-tmp \
    \
    # fix yum gets stuck at Running Transaction
    rpm --rebuilddb \
    \
    # update packages
    && yum makecache fast \
    && yum update --exclude=centos-release* --skip-broken -y \
    \
    && yum install -y meson fuse-devel pam-devel help2man \
    && pip3 install jinja2

RUN --mount=type=cache,target=/var/cache,id=buildx-cache \
    --mount=type=cache,target=/tmp,id=build-tmp \
    \
    meson setup -Dinit-script=systemd --prefix=/usr build/ \
    && meson compile -C build \
    && meson install -C build

FROM --platform=$TARGETPLATFORM dockerhub.bigquant.ai:5000/dockerstacks/centos-base:master_latest

ENV LXCFS_VERSION=${APP_VERSION}

# Installing lxcfs to /usr/bin
# Installing liblxcfs.so to /usr/lib64/lxcfs

COPY --from=builder /usr/bin/lxcfs /usr/bin/lxcfs
COPY --from=builder /usr/lib64/lxcfs /usr/lib64/lxcfs

RUN --mount=type=cache,target=/var/cache,id=buildx-cache \
    --mount=type=cache,target=/tmp,id=build-tmp \
    \
    # fix yum gets stuck at Running Transaction
    rpm --rebuilddb \
    \
    # update packages
    && yum makecache fast \
    && yum update --exclude=centos-release* --skip-broken -y \
    && yum install -y fuse-libs

ENTRYPOINT [ "/usr/bin/lxcfs" ]

```

