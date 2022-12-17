
## Alpine

Alpine 是一个仅 5 MB 的最小 Linux 发行版，使用 apk 作为包管理工具。

## 遇到的问题

### 切换镜像源

```bash
sed -i.bak 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
```

如果不想备份原文件，可以直接 `sed -i`。

原文件内容：

```bash
http://dl-cdn.alpinelinux.org/alpine/v3.11/main
http://dl-cdn.alpinelinux.org/alpine/v3.11/community
```

修改后的文件内容：

```bash
http://mirrors.aliyun.com/alpine/v3.11/main
http://mirrors.aliyun.com/alpine/v3.11/community
```

### 设置时区

```bash
apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezon
```

### 找不到包

包的搜索地址：

<<https://pkgs.alpinelinux.org/packages> >

只需要加入对应的 branch 和 repository 到 `/etc/apk/repositories` 中。

### 避免安装缓存

apk 提供了两个参数非常实用：`--no-cache`、`--virtual`

使用 `--no-cache` 不会保存缓存的安装包，无需手动清理缓存。

使用 `--virtual` 不会添加软件包到全局软件包中，这种变化可以很容易回滚。

注意：同一个 `--virtual` 参数会覆盖之前的所有安装包。

比如同时执行了：

```bash
apk add --no-cache --virtual .ruby-builddeps \
    gcc \
    dpkg

apk add --no-cache --virtual .ruby-builddeps \
    gcc 
```

实际上只安装了 gcc 到 `.ruby-builddeps`

## 构建 ruby 基础环境

```dockerfile
# syntax=docker/dockerfile:experimental
FROM dockerhub.bigquant.ai:5000/vendor/alpine:3.11.3 as file_passer

COPY docker_build/ruby_base /tmp/ruby_base/

FROM dockerhub.bigquant.ai:5000/vendor/alpine:3.11.3

ENV \
    # ruby version
    RUBY_VERSION=2.5.1 \
    RUBY_MAJOR=2.5 \
    RUBYGEMS_VERSION=2.7.7 \
    BUNDLER_VERSION=1.16.6 \
    GEM_HOME=/usr/local/bundle \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG=/usr/local/bundle \
    PATH=/usr/local/bundle/bin:/usr/local/bundle/gems/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN --mount=type=bind,from=file_passer,source=/tmp/ruby_base,target=/tmp/ruby_base,rw \
    # change repo mirror
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    # set time zone
    && apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    # config gemrc
    && mkdir -p /usr/local/etc \
    && { echo 'install: --no-document'; echo 'update: --no-document'; } >> /usr/local/etc/gemrc \
    \
    && apk add --no-cache --virtual .ruby-builddeps \
        autoconf \
        bison \
        bzip2 \
        bzip2-dev \
        ca-certificates \
        coreutils \
        dpkg-dev \
        dpkg \
        gcc \
        gdbm-dev \
        glib-dev \
        libc-dev \
        libffi-dev \
        libressl \
        libressl-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers \
        make \
        ncurses-dev \
        procps \
        readline-dev \
        ruby \
        tar \
        xz \
        yaml-dev \
        zlib-dev \
        openssl \
        openssl-dev \
    \
    # # download ruby
    # && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
    # && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
    # && mkdir -p /usr/src/ruby \
    # && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
    # && rm ruby.tar.xz \
    && cd /tmp/ruby_base \
    && mkdir -p /usr/src/ruby \
    && tar -xJf ruby-2.5.1.tar.xz -C /usr/src/ruby --strip-components=1 \
    \
    # # add patch
    # && cd /usr/src/ruby \
    # && wget -O 'thread-stack-fix.patch' 'https://bugs.ruby-lang.org/attachments/download/7081/0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch' \
    # && echo '3ab628a51d92fdf0d2b5835e93564857aea73e0c1de00313864a94a6255cb645 *thread-stack-fix.patch' | sha256sum -c - \
    # && patch -p1 -i thread-stack-fix.patch \
    # && rm thread-stack-fix.patch \
    && export PATCH_NAME=0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch \
    && cp -r /tmp/ruby_base/${PATCH_NAME} /usr/src/ruby/ \
    && cd /usr/src/ruby \
    && patch -p1 -i ${PATCH_NAME} \
    \
    && { echo '#define ENABLE_PATH_CHECK 0'; echo; cat file.c; } > file.c.new \
    && mv file.c.new file.c \
    && autoconf \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && export ac_cv_func_isnan=yes ac_cv_func_isinf=yes \
    && ./configure --build="$gnuArch" --disable-install-doc --enable-shared \
    && export CFLAGS="-Wno-self-assign -Wno-constant-logical-operand -Wno-parentheses-equality" \
    && make -j "$(nproc)" \
    && make install \
    \
    && runDeps="$(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' )" \
    && apk add --no-network --virtual .ruby-rundeps $runDeps \
        bzip2 \
        ca-certificates \
        libffi-dev \
        procps \
        yaml-dev \
        zlib-dev \
    \
    # remove all unuse packages
    && apk del --no-network .ruby-builddeps \
    \
    # clean compile
    && cd / \
    && rm -r /usr/src/ruby \
    && gem update --system "$RUBYGEMS_VERSION"  \
    && gem install bundler --version "$BUNDLER_VERSION" --force \
    && rm -r /root/.gem/ \
    && mkdir -p "$GEM_HOME" \
    && chmod 777 "$GEM_HOME"

```