

## 获取源码

Go 语言作为开源项目，可以很轻松地获取它的源代码，Golang 源码存放于：

- 官方 <https://go.googlesource.com/go>
- GitHub Mirror：<https://github.com/golang/go>

首先拉取源码：

```bash
git clone --recurse-submodules https://github.com/golang/go.git -b go1.20.1
```

查看并确定下当前的分支：

```bash
> git status

HEAD detached at go1.20.1
nothing to commit, working tree clean
```

它有着非常复杂的项目结构和庞大的代码库，今天的 Go 语言中差不多有 200 万行源代码，其中包含将近 160 万行的 Go 语言代码，可以使用如下所示的命令查看项目中代码的行数：

```bash
gocloc ./src
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Go                            5566         174322         320365        1627656
Assembly                       539          16010          21282         122193
Plain Text                    1059          11238              0          52910
HTML                             9            357             11          10489
C                               80            846            620           5072
JSON                            19              0              0           3102
BASH                            24            323           1060           2017
Markdown                        13            467              0           1631
JavaScript                       5            154            170            952
Perl                            10            173            582            698
C Header                        15            107            254            454
Python                           1            133            104            374
CSS                              3              4             13            337
Batch                            5             56              0            254
Plan9 Shell                      4             22             50             93
Bourne Shell                     4             26             20             64
C++                              1              8              9             17
Objective-C                      2              3              3             15
Awk                              1              1              6              7
Makefile                         4              3              7              7
-------------------------------------------------------------------------------
TOTAL                         7364         204253         344556        1828342
-------------------------------------------------------------------------------
```

## 调试源码

### 编译源码

修改改 Go 语言中常用方法 [`fmt.Println`](https://draveness.me/golang/tree/fmt.Println) 的实现，实现：在打印字符串之前先打印任意其它字符串

可以将该方法的实现修改成如下所示的代码片段，其中 `println` 是 Go 语言运行时提供的内置方法，它不需要依赖任何包就可以向标准输出打印字符串：

```go
// Println formats using the default formats for its operands and writes to standard output.
// Spaces are always added between operands and a newline is appended.
// It returns the number of bytes written and any write error encountered.
func Println(a ...any) (n int, err error) {
	println("cyril")
	return Fprintln(os.Stdout, a...)
}

```

对应的源码位置：<https://github.com/golang/go/blob/go1.20.1/src/fmt/print.go#L310-L315>

当修改了 Go 语言的源代码项目，可以使用仓库中提供的脚本来编译生成 Go 语言的二进制以及相关的工具链：

```bash
> cd src && ./make.bash

Building Go cmd/dist using /root/.g/versions/1.20.1. (go1.20.1 linux/amd64)
Building Go toolchain1 using /root/.g/versions/1.20.1.
Building Go bootstrap cmd/go (go_bootstrap) using Go toolchain1.
Building Go toolchain2 using go_bootstrap and Go toolchain1.
Building Go toolchain3 using go_bootstrap and Go toolchain2.
Building packages and commands for linux/amd64.
---
Installed Go for linux/amd64 in /code/go.googlesource.com/go
Installed commands in /code/go.googlesource.com/go/bin
```

`make.bash` 脚本会编译 Go 语言的二进制、工具链以及标准库和命令并将源代码和编译好的二进制文件移动到对应的位置上

如上述代码所示，编译好的二进制会存储在 `/code/go.googlesource.com/go/bin` 目录中

准备一个基础的、只包含  `main.go` 的 Go 项目：

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello World")
}

```

这里需要使用绝对路径来访问并使用刚刚编译好的 Go：

```bash
> GOROOT=/code/go.googlesource.com/go /code/go.googlesource.com/go/bin/go run main.go

cyril
Hello World
```

上述命令成功地调用了修改后的 [`fmt.Println`](https://draveness.me/golang/tree/fmt.Println) 函数

### 中间代码

Go 语言的应用程序在运行之前需要先编译成二进制，在编译的过程中会经过中间代码生成阶段，Go 语言编译器的中间代码具有静态单赋值（Static Single Assignment、SSA）的特性

可以使用下面的命令将 Go 语言的源代码编译成汇编语言，然后通过汇编语言分析程序具体的执行过程：

```bash
> go build -gcflags -S main.go

# command-line-arguments
main.main STEXT size=103 args=0x0 locals=0x40 funcid=0x0 align=0x0
        0x0000 00000 (/code/code.liaosirui.com/z-demo/go-demo/main.go:5)        TEXT    main.main(SB), ABIInternal, $64-0
        0x0000 00000 (/code/code.liaosirui.com/z-demo/go-demo/main.go:5)        CMPQ    SP, 16(R14)
        0x0004 00004 (/code/code.liaosirui.com/z-demo/go-demo/main.go:5)        PCDATA  $0, $-2
        0x0004 00004 (/code/code.liaosirui.com/z-demo/go-demo/main.go:5)        JLS     92
        0x0006 00006 (/code/code.liaosirui.com/z-demo/go-demo/main.go:5)        PCDATA  $0, $-1
        0x0006 00006 (/code/code.liaosirui.com/z-demo/go-demo/main.go:5)        SUBQ    $64, SP
        ...
        0x0000 01 00 00 00 00 00 00 00 f0 ff ff ff 10 00 00 00  ................
        0x0010 10 00 00 00 00 00 00 00                          ........
        rel 20+4 t=5 runtime.gcbits.0200000000000000+0
```

然而上述的汇编代码只是 Go 语言编译的结果，作为使用 Go 语言的开发者，已经能够通过上述结果分析程序的性能瓶颈，但是如果想要了解 Go 语言更详细的编译过程，可以通过下面的命令获取汇编指令的优化过程：

```go
> GOSSAFUNC=main go build main.go
# runtime
dumped SSA to /code/code.liaosirui.com/z-demo/go-demo/ssa.html
# command-line-arguments
dumped SSA to ./ssa.html
```

上述命令会在当前文件夹下生成一个 `ssa.html` 文件，打开这个文件后就能看到汇编代码优化的每一个步骤

![image-20230226130912004](.assets/image-20230226130912004.png)

上述 HTML 文件是可以交互的，当点击网页上的汇编指令时，页面会使用相同的颜色在 SSA 中间代码生成的不同阶段标识出相关的代码行，更方便开发者分析编译优化的过程

## 参考资料

- <https://draveness.me/golang/docs/part1-prerequisite/ch01-prepare/golang-debug/>
- <https://qcrao91.gitbook.io/go/goroutine-tiao-du-qi>
- <https://xiaomi-info.github.io/2019/11/13/golang-compiler-principle/>
- <https://alanhou.org/xargin-golang-02/>
- <https://golang.design/go-questions/>

- <https://liuqh.icu/2023/01/28/go/bottom/2-string/>
