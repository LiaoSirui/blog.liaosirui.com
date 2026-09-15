这个命令主要用于编译代码。在包的编译过程中，若有必要，会同时编译与之相关联的包。

-  如果是普通包，就像我们在1.2节中编写的`mymath`包那样，当你执行`go build`之后，它不会产生任何文件。如果你需要在`$GOPATH/pkg`下生成相应的文件，那就得执行`go install`。 
-  如果是`main`包，当你执行`go build`之后，它就会在当前目录下生成一个可执行文件。如果你需要在`$GOPATH/bin`下生成相应的文件，需要执行`go install`，或者使用`go build -o 路径/a.exe`。 
-  如果某个项目文件夹下有多个文件，而你只想编译某个文件，就可在`go build`之后加上文件名，例如`go build a.go`；`go build`命令默认会编译当前目录下的所有go文件。 
-  你也可以指定编译输出的文件名。例如1.2节中的`mathapp`应用，我们可以指定`go build -o astaxie.exe`，默认情况是你的package名(非main包)，或者是第一个源文件的文件名(main包)。 

（注：实际上，package名在[Go语言规范](https://golang.org/ref/spec)中指代码中“package”后使用的名称，此名称可以与文件夹名不同。默认生成的可执行文件名是文件夹名。）

-  go build会忽略目录下以“_”或“.”开头的go文件。 
-  如果你的源代码针对不同的操作系统需要不同的处理，那么你可以根据不同的操作系统后缀来命名文件。例如有一个读取数组的程序，它对于不同的操作系统可能有如下几个源文件： array_linux.go array_darwin.go array_windows.go array_freebsd.go 

`go build`的时候会选择性地编译以系统名结尾的文件（Linux、Darwin、Windows、Freebsd）。例如Linux系统下面编译只会选择array_linux.go文件，其它系统命名后缀文件全部忽略。

参数的介绍

- `-o` 指定输出的文件名，可以带上路径，例如 `go build -o a/b/c`
- `-i` 安装相应的包，编译+`go install`
- `-a` 更新全部已经是最新的包的，但是对标准包不适用
- `-n` 把需要执行的编译命令打印出来，但是不执行，这样就可以很容易的知道底层是如何运行的
- `-p n` 指定可以并行可运行的编译数目，默认是CPU数目
- `-race` 开启编译的时候自动检测数据竞争的情况，目前只支持64位的机器
- `-v` 打印出来我们正在编译的包名
- `-work` 打印出来编译时候的临时文件夹名称，并且如果已经存在的话就不要删除
- `-x` 打印出来执行的命令，其实就是和`-n`的结果类似，只是这个会执行
- `-ccflags 'arg list'` 传递参数给5c, 6c, 8c 调用
- `-compiler name` 指定相应的编译器，gccgo还是gc
- `-gccgoflags 'arg list'` 传递参数给gccgo编译连接调用
- `-gcflags 'arg list'` 传递参数给5g, 6g, 8g 调用
- `-installsuffix suffix` 为了和默认的安装包区别开来，采用这个前缀来重新安装那些依赖的包，`-race`的时候默认已经是`-installsuffix race`,大家可以通过`-n`命令来验证
- `-ldflags 'flag list'` 传递参数给5l, 6l, 8l 调用
- `-tags 'tag list'` 设置在编译的时候可以适配的那些 tag，详细的 tag 限制参考里面的 [Build Constraints](http://golang.org/pkg/go/build/)