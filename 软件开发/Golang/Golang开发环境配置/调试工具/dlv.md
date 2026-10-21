## delve 简介

delve 的目标是为开发者提供愉快高效的 Go 调试体验

官方：

- GitHub 仓库：<https://github.com/go-delve/delve>
- 文档：<https://github.com/go-delve/delve/tree/master/Documentation>

安装：

```bash
go install github.com/go-delve/delve/cmd/dlv@latest
```

## trace

tracing 是一种允许开发人员在程序执行期间看到在做什么的技术，与典型的调试技术相比，这种方法不需要与用户进行直接交互。最著名的跟踪工具之一是 `strace`，它允许开发人员查看哪些系统在执行过程中调用了他们的程序

Delve 的跟踪实现有两种不同的后端，一种基于 `ptrace`，另一种使用 `eBPF`

### 命令帮助文档

安装完成后可以查看 `dlv trace` 子命令的帮助信息：

```bash
race program execution.

The trace sub command will set a tracepoint on every function matching the
provided regular expression and output information when tracepoint is hit.  This
is useful if you do not want to begin an entire debug session, but merely want
to know what functions your process is executing.

The output of the trace sub command is printed to stderr, so if you would like to
only see the output of the trace operations you can redirect stdout.

Usage:
  dlv trace [package] regexp [flags]

Flags:
      --ebpf            Trace using eBPF (experimental).
  -e, --exec string     Binary file to exec and trace.
  -h, --help            help for trace
      --output string   Output path for the binary. (default "debug")
  -p, --pid int         Pid to attach to.
  -s, --stack int       Show stack trace with given depth. (Ignored with --ebpf)
  -t, --test            Trace a test binary.

Global Flags:
      --accept-multiclient               Allows a headless server to accept multiple client connections via JSON-RPC or DAP.
      --allow-non-terminal-interactive   Allows interactive sessions of Delve that don't have a terminal as stdin, stdout and stderr
      --api-version int                  Selects JSON-RPC API version when headless. New clients should use v2. Can be reset via RPCServer.SetApiVersion. See Documentation/api/json-rpc/README.md. (default 1)
      --backend string                   Backend selection (see 'dlv help backend'). (default "default")
      --build-flags string               Build flags, to be passed to the compiler. For example: --build-flags="-tags=integration -mod=vendor -cover -v"
      --check-go-version                 Exits if the version of Go in use is not compatible (too old or too new) with the version of Delve. (default true)
      --disable-aslr                     Disables address space randomization
      --headless                         Run debug server only, in headless mode. Server will accept both JSON-RPC or DAP client connections.
      --init string                      Init file, executed by the terminal client.
  -l, --listen string                    Debugging server listen address. (default "127.0.0.1:0")
      --log                              Enable debugging server logging.
      --log-dest string                  Writes logs to the specified file or file descriptor (see 'dlv help log').
      --log-output string                Comma separated list of components that should produce debug output (see 'dlv help log')
      --only-same-user                   Only connections from the same user that started this instance of Delve are allowed to connect. (default true)
  -r, --redirect stringArray             Specifies redirect rules for target process (see 'dlv help redirect')
      --wd string                        Working directory for running the program.
```

### trace

Delve 允许通过调用 `dlv trace` 子命令来跟踪 Go 程序，该子命令接受一个正则表达式并执行的程序，在每个与正则表达式匹配的函数上设置跟踪点并实时显示结果

下面的程序是一个例子：

```go
// main.go
package main

import "fmt"

func foo(x, y int) (z int) {
	fmt.Printf("x = %d, y = %d, z = %d\n", x, y, z)
	z = x + y

	return
}

func main() {
	x := 99
	y := x * x
	z := foo(x, y)

	fmt.Printf("z = %d\n", z)
}

```

可以使用 `dlv trace` 命令来跟踪该程序，正常会输出如下所示内容：

```go
> dlv trace foo

x = 99, y = 9801, z = 0
> goroutine(1): main.foo(99, 9801)
z = 9900
>> goroutine(1): => (9900)
Process 730732 has exited with status 0
```

在 `dlv trace` 后面提供的正则表达式是 `foo`，它和 Go 程序中的同名函数 `func foo(x, y int) (z int)` 匹配

- 以 `>` 为前缀的输出表示被调用的函数并显示该函数的参数
- 以 `>>` 为前缀的输出表示函数的返回值以及与其关联的返回值

所有输入和输出行都以当时执行的 `goroutine` 为前缀

默认情况下，Delve 会使用 `ptrace` 系统调用来实现跟踪功能，`ptrace` 是一个系统调用，允许程序观察和操作同一台机器上的其他程序。实际上，在 Unix 系统上，Delve 使用这个 ptrace 功能来实现调试器提供的许多低级功能，例如读写内存、控制执行等。

虽然 ptrace 是一种有用且功能强大的机制，但它也存在固有的低效率问题。首先，ptrace 是一个系统调用，意味着必须跨越用户空间 / 内核空间边界，这增加了每次使用函数时的开销，调用 ptrace 的次数越多，开销就越大。

以示例应用为例，以下是使用 ptrace 实现跟踪的大致步骤：

1. 使用 `ptrace(PT_ATTACH)` 启动程序并附加调试器
2. 使用 `ptrace` 在匹配所提供的正则表达式的每个函数处设置断点，并在被跟踪的进程的可执行内存中插入断点指令
3. 另外，在该函数的每个返回指令处设置断点
4. 再次使用 `ptrace(PT_CONT)` 继续程序
5. 此步骤可能涉及多次 `ptrace` 调用，因为需要读取函数入口的 CPU 寄存器、堆栈上的内存以及如果必须取消指针引用的堆上的内存
6. 再次使用 `ptrace(PT_CONT)` 继续程序
7. 在函数返回时遇到断点，通过读取变量，可能涉及到更多的 `ptrace` 调用，以读取寄存器和内存
8. 再次使用 `ptrace(PT_CONT)` 继续程序
9. 直到程序结束。

显然，函数的参数和返回值越多，每次停止就越昂贵。所有调试器花费在进行 `ptrace` 系统调用的时间，跟踪的程序都处于暂停状态，没有执行任何指令。从用户的角度来看，这使得程序的运行速度比原本要慢得多。对于开发和调试来说，这也许不是什么大问题，但是时间是宝贵的，应该尽量快速地完成事情。程序在跟踪过程中的运行速度越快，就能越快找到问题的根本原因。

### eBPF trace

默认情况下，`dlv trace` 命令使用的是基于 `ptrace` 的后端，可以通过添加 `--ebpf` 标志来启用基于 eBPF（实验特性）的后端

```bash
> dlv trace --ebpf foo

x = 99, y = 9801, z = 0
z = 9900
> (1) main.foo(99, 9801)
=> "9900"
Process 731605 has exited with status 0
```

同样将收到类似 `ptrace` 的输出结果，但是，背后的实现原理却完全不同而且更加高效

一个最大的速度和效率改进是避免大量的系统调用开销，这是 eBPF 发挥作用的地方，因为可以在函数入口和出口设置 uprobes，并将小型的 eBPF 程序附加到它们上。Delve 使用 Cilium eBPF 的 Go 库加载与 eBPF 程序进行交互。

每次触发 probe 时，内核将调用 eBPF 程序，然后在它完成后继续主程序。编写的 eBPF 程序将处理函数入口和出口中列出的所有步骤，但不会有所有的系统调用上下文切换，因为程序直接在内核空间中执行。 eBPF 程序可以通过 eBPF 环形缓冲区和映射数据结构与用户空间中的调试器通信，使 Delve 能够收集所需的所有信息。

这种方法的优点是，正在跟踪的程序需要暂停的时间大大减少。在触发 probe 时运行 eBPF 程序比在函数入口和出口处调用多个系统调用要快得多。

使用 eBPF 跟踪调试的流程：

1. 启动程序并使用 `ptrace(PT_ATTACH)` 附加到进程上
2. 在内核中加载所有需要跟踪的函数的 `uprobes`
3. 使用 `ptrace(PT_CONT)` 继续执行程序
4. 在函数入口和出口触发 `uprobes`，每当 probe 被触发，内核部分将运行 eBPF 程序，该程序获取函数的参数或返回值，并将其发送回用户空间。在用户空间中，从 eBPF 环形缓冲区读取函数参数和返回值
5. 重复此过程直到程序结束

通过使用这种方法，Delve 可以比使用默认的 ptrace 实现更快地跟踪程序。现在，你可能会问，为什么不将这种方法默认使用？事实上，未来很有可能会成为默认方法。但目前仍在进行开发，以改进这种基于 eBPF 的后端并确保它与基于 ptrace 的后端平衡性。当然仍然可以在执行 `dlv trace` 时使用 `--ebpf` 标志来使用它。

## debug

debug 命令会先编译 go 源文件，同时执行 attach 命令进入调试模式，该命令会在当前目录下生成一个名为 debug 的可执行二进制文件 `__debug_bin`，退出调试模式会自动被删除

常用指令：

- `b`：break 打断点
- `c`：continue 继续运行，直到断点处停止
- `n`：next 单步运行
- `locals`：打印 local variables
- `p`：print 打印一个变量或者表达式
- `r`：restart 重启进程

例如：

```bash
# 启动调试
dlv debug ./main.go

# 打断点
b main.go:75 # main.go 的 75 行打断点

# 执行至断点
c

# 退出
q
```

## test

go语言里面 `_test.go` 结尾的文件会被认为是测试文件，go 语言作为现代化的语言，语言工具层面就支持单元测试

利用 `go test` 命令，会直接编译测试文件为二进制文件后，再运行

但是，有时候我们需要知道执行单元测试的细节，无论是验证也好，还是去寻找单元测试没有 PASS 的原因。那么调试测试代码就成了刚需

例如：

```bash
# 启动调试
dlv test ./main_test.go

# 打断点
b main_test.go:10

# 或者具体测试方法
b TestSum

# 执行至断点
c

# 退出
q
```

## 远程调试

远程服务器安装 dlv

```bash
go install github.com/go-delve/delve/cmd/dlv@latest
```

在本地服务器编译

```bash
go build -gcflags="all=-N -l" ./cmd/cmdb-node-detector
```

在服务器上启动 Delve

```bash
dlv --headless --listen=:2345 --log exec ./cmdb-node-detector
# --accept-multiclient
```

配置 Visual Studio Code

```json
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch file",
            "type": "go",
            "request": "launch",
            "mode": "debug",
            "program": "${file}"
        },
        {
            "name": "Connect to server",
            "type": "go",
            "request": "attach",
            "mode": "remote",
            // "remotePath": "${workspaceFolder}",
            "host": "192.168.248.102",
            "port": 2345,
        }
    ]
}

```

在 Visual Studio Code 中，打开刚才编辑的`launch.json`文件，选择 “Connect to server”，然后按下 F5 开始调试

## 参考资料

- 远程调试 <https://cloud.tencent.com/developer/article/2312806>
