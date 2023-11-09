## wasip1

Go 1.21 通过添加新的 `wasip1` 值来支持针对 WASI 预览版 1 系统调用 API 的新端口。这个端口建立在 Go 1.11 中引入的现有 WebAssembly 端口之上

### 构建 wasip1

简单的 `main.go`

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello world!")
}

```

可以使用以下命令构建它为 `wasip1`:

```bash
GOOS=wasip1 GOARCH=wasm go build -o main.wasm main.go
```

这将生成一个文件 `main.wasm`，可以使用以下命令用 `wasmtime` 执行该文件:

```bash
> wasmtime main.wasm

Hello world!
```

### 使用 wasip1 运行 go 测试

Go 发行版中的标准库包含一个 `misc/wasm` 目录

```bash
export PATH=$PATH:$(go env GOROOT)/misc/wasm
```

测试

```bash
GOOS=wasip1 GOARCH=wasm go test ./...
```

这将使用 Wasmtime 来运行 `go test`

可以使用环境变量 `GOWASIRUNTIME` 来控制使用的 Wasm 主机。该变量目前支持的值为 `wazero`、`wasmedge`、`wasmtime` 和 `wasmer`
