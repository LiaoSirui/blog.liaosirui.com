## TinyGo 简介

官方：

- GitHub 仓库：<https://github.com/tinygo-org/tinygo>

### 优缺点

- 使用 TinyGo 的好处

TinyGo 是 Go 的子集，可以使用 Go 语言编写 WebAssembly 程序

可以直接在 WasmEdge 上运行，无需 JavaScript 环境

wasm 文件足够小，几十 KB

- 使用 TinyGo 的缺点

TinyGo 有些库不能用，比如 net/http 等，具体可参考 https://tinygo.org/docs/reference/lang-support/stdlib/

TinyGo 不支持全部 Go 语言特性，比如 Cgo 等，具体可参考 https://tinygo.org/docs/reference/lang-support

## 安装 TinyGo

参考文档：<https://tinygo.org/getting-started/install/>

```bash
d# refer: https://github.com/tinygo-org/tinygo/releases
export INST_TINYGO_VERSION=v0.27.0

cd $(mktemp -d)
curl -sL \
    https://github.com/tinygo-org/tinygo/releases/download/${INST_TINYGO_VERSION}/tinygo${INST_TINYGO_VERSION/v/}.linux-amd64.tar.gz \
    -o tinygo.tgz
mkdir -p /usr/local/tinygo
tar zxf tinygo.tgz -C /usr/local/tinygo

export PATH=/usr/local/tinygo/tinygo/bin:$PATH
```

## 入门程序

新建 main.go 文件

```go
package main

func main() {
	println("Hello, World! by TinyGo")
}

```

编译代码

```bash
mkdir -p ./build

tinygo build -o ./build/main.wasm -target=wasm
```

- 使用 WasmEdge 运行

```bash
wasmedge ./build/main.wasm
```

- 使用容器运行

（1）新建 Dockerfile 文件

```bash
FROM scratch

ADD ./build/main.wasm /build/main.wasm

ENTRYPOINT ["/build/main.wasm"]
```

（2）编译容器镜像

```bash
docker buildx build --load -t wasm-hello-world:tinygo .
```

（3）运行容器镜像

```bash
docker run  --rm --runtime=io.containerd.wasmedge.v1 \
    wasm-hello-world:tinygo
```

