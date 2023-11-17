管理多 module 的工作区

最初这个 proposal 的名字就是 multi modules workspace，即多 module 的工作区管理。当你的本地有很多 module，且这些 module 存在相互依赖，那么我们可以在这些 module 的外面建立一个 Go 工作区，基于这个 Go 工作区开发与调试这些 module 就变得十分方便。

比如我们有三个 module：a、b 和 c，其中 a 与 b 都依赖 c。我们可以在 a、b、c 三个 module 路径的上一层创建一个 Go 工作区：

```bash
cd $WORK

go work init
go work use tools tools/gopls
```

会生成 `go.work` 文件，内容如下：

```go
go 1.20

use (
	tools
	tools/gopls
)

```

