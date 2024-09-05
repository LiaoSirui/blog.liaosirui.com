## 编译 CoreDNS

官方给的编译文档：<https://github.com/coredns/coredns#compilation-from-source>

切换到稳定分支

```bash
git checkout v1.10.1
```

### 构建二进制

构建文件

````bash
docker run \
    --rm \
    -it \
    -v $PWD:/v \
    -w /v \
    -e GOPROXY="https://goproxy.cn,direct" \
    golang:1.18 make
````

编译完成之后我们就会在当前目录下得到一个二进制文件

```bash
> file coredns

coredns: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=bUHy1dSjbzn70qBTO6cG/j6bEgH1sk3ySU98xoW3R/0G6p5dQ3AEowbPv-D6q2/Q7IHDMcrUYyhWbgGWSdg, stripped
```

### 构建镜像

需要预先构建一些目录

```bash
[[ ! -d build/docker/amd64 ]] && mkdir -p build/docker/amd64
cp -rpf coredns build/docker/amd64/
cp -rpf Dockerfile build/docker/amd64/

make -f ./Makefile.docker \
    docker-build \
    DOCKER=harbor.local.liaosirui.com:5000/custom NAME=coredns-k8s_event LINUX_ARCH=amd64 VERSION=1.10.1.patch01
```

这里使用 buildx 因此构建命令改为

```bash
ifeq ($(DOCKER),)
	$(error "Please specify Docker registry to use. Use DOCKER=coredns for releases")
else
	docker version
	for arch in $(LINUX_ARCH); do \
-	    DOCKER_BUILDKIT=1 docker build --platform=$${arch} -t $(DOCKER_IMAGE_NAME):$${arch}-$(VERSION) build/docker/$${arch} ;\
+	    docker buildx build --platform=$${arch} -t $(DOCKER_IMAGE_NAME):$${arch}-$(VERSION) build/docker/$${arch} ;\
	done
endif
```

## 编译外部插件

### 什么是 External Plugins

coredns 官方对于插件的分类基本可以分为三种：

- Plugins
- External Plugins
- 其他

其中 Plugins 一般都会被默认编译到 coredns 的预编译版本中，而 External Plugins 则不会。官方的文档对外部插件的定义有着明确的解释，主要要求大概是有用、高效、符合标准、文档齐全、通过测试等

官方给出了一个详细的文档说明，编译插件基本可以分为修改源码和修改编译的配置文件这两种方式：<https://coredns.io/2017/07/25/compile-time-enabling-or-disabling-plugins/>

### 修改编译配置文件

下载的官方源码中，有一个 `plugin` 的目录，里面是各种插件的安装包，同时还有一个 `plugin.cfg` 的文件，里面列出了会编译到 CoreDNS 中的插件

修改插件列表 `plugin.cfg`

```ini
k8s_event:github.com/coredns/k8s_event
kubeapi:github.com/coredns/kubeapi
```

参考每个插件的 home 页面中的 `Enable With` 进行配置，例如：<https://coredns.io/explugins/k8s_event/>

接下来只要检验生成的 coredns 二进制文件中是否包含 `k8s_event` 插件即可确认是否顺利编译完成：

```bash
> ./coredns -plugins | grep k8s_event
  dns.k8s_event
```