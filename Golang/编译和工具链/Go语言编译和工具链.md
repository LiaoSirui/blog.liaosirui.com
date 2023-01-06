Go 语言的工具链非常丰富，从获取源码、编译、文档、测试、性能分析，到源码格式化、源码提示、重构工具等应有尽有

Go 语言自带有一套完整的命令操作工具，可以通过在命令行中执行 `go` 来查看：

```bash
> go                                                               
Go is a tool for managing Go source code.

Usage:

        go <command> [arguments]

The commands are:

        bug         start a bug report
        build       compile packages and dependencies
        clean       remove object files and cached files
        doc         show documentation for package or symbol
        env         print Go environment information
        fix         update packages to use new APIs
        fmt         gofmt (reformat) package sources
        generate    generate Go files by processing source
        get         add dependencies to current module and install them
        install     compile and install packages and dependencies
        list        list packages or modules
        mod         module maintenance
        work        workspace maintenance
        run         compile and run Go program
        test        test packages
        tool        run specified go tool
        version     print Go version
        vet         report likely mistakes in packages

Use "go help <command>" for more information about a command.

Additional help topics:

        buildconstraint build constraints
        buildmode       build modes
        c               calling between Go and C
        cache           build and test caching
        environment     environment variables
        filetype        file types
        go.mod          the go.mod file
        gopath          GOPATH environment variable
        gopath-get      legacy GOPATH go get
        goproxy         module proxy protocol
        importpath      import path syntax
        modules         modules, module versions, and more
        module-get      module-aware go get
        module-auth     module authentication using go.sum
        packages        package lists and patterns
        private         configuration for downloading non-public code
        testflag        testing flags
        testfunc        testing functions
        vcs             controlling version control with GOVCS

Use "go help <topic>" for more information about that topic.

```

命令的功能如下：

| 命令     | 功能                                                | 介绍                                                         |
| -------- | --------------------------------------------------- | ------------------------------------------------------------ |
| bug      | start a bug report                                  |                                                              |
| build    | compile packages and dependencies                   | go 语言编译命令                                              |
| clean    | remove object files and cached files                | 清除编译文件                                                 |
| doc      | show documentation for package or symbol            |                                                              |
| env      | print Go environment information                    |                                                              |
| fix      | update packages to use new APIs                     |                                                              |
| fmt      | gofmt (reformat) package sources                    | 格式化代码文件                                               |
| generate | generate Go files by processing source              | 在编译前自动化生成某类代码                                   |
| get      | add dependencies to current module and install them | 一键获取代码、编译并安装                                     |
| install  | compile and install packages and dependencies       | 编译并安装                                                   |
| list     | list packages or modules                            |                                                              |
| mod      | module maintenance                                  |                                                              |
| work     | workspace maintenance                               |                                                              |
| run      | compile and run Go program                          | 编译并运行                                                   |
| test     | test packages                                       | Go语言测试命令<br />在 Go 语言中可以使用测试框架编写单元测试，使用统一的命令行即可测试及输出测试报告的工作；<br />基准测试提供可自定义的计时器和一套基准测试算法，能方便快速地分析一段代码可能存在的 CPU 耗用和内存分配问题 |
| tool     | run specified go tool                               |                                                              |
| version  | print Go version                                    |                                                              |
| vet      | report likely mistakes in packages                  |                                                              |

Tool 命令：

- pprof 命令（Go语言性能分析命令）性能分析工具可以将程序的 CPU 耗用、内存分配、竞态问题以图形化方式展现出来