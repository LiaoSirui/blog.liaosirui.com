## Cobra 简介

Cobra 是一个库，提供了一个简单的界面，可以创建类似于 git 和 go 工具的强大的现代 CLI 界面

Cobra 也是一个应用程序，它可以生成应用程序脚手架来快速开发基于 Cobra 的应用程序

安装 cli：

```bash
go install github.com/spf13/cobra-cli@latest
```

官方：

- GitHub：<https://github.com/spf13/cobra>
- 文档：<https://cobra.dev/>

在 Go 项目中引入库：

```bash
go get -u github.com/spf13/cobra/cobra
```

在 Go 代码中引入库：

```go
import "github.com/spf13/cobra"
```

## 项目结构

推荐项目结构：

```plain
  ▾ appName/
    ▾ cmd/
        add.go
        your.go
        commands.go
        here.go
      main.go
```

`root.go `编写 go 项目可执行程序的根命令（以`hugo`为例）

```bash
var rootCmd = &cobra.Command{
  Use:   "hugo",
  Short: "Hugo is a very fast static site generator",
  Long: `A Fast and Flexible Static Site Generator built with
                love by spf13 and friends in Go.
                Complete documentation is available at http://hugo.spf13.com`,
  Run: func(cmd *cobra.Command, args []string) {
    // Do Stuff Here
  },
}

func Execute() {
  if err := rootCmd.Execute(); err != nil {
    fmt.Fprintln(os.Stderr, err)
    os.Exit(1)
  }
}

```

`main.go` 一般只需要调用根目录的执行函数即可

```go
package main

import (
  "{pathToYourApp}/cmd"
)

func main() {
  cmd.Execute()
}

```

## 添加子命令

添加一个子命令 `add` 在 `add.go` 中：

```go
var add = &cobra.Command{
  Use:   "add [Person]",
  Short: "add one item",
  Long:  `add one item`,
  Args: cobra.ExactArgs(1),													// 指定该命令的参数输入个数 
  Run: func(cmd *cobra.Command, args []string) {		// RunE表示可以返回一个错误
    // todo
  },
}

```

一般在在项目的 `init.go` 中的 `init` 函数中初始化操作：在 root 命令下添加这个子命令

```go
func init() {
  cmd.rootCmd.AddCommand(add)
}

```

##  添加 Flag

Flag 有两种类型：

Persistent Flags：设置在根命令上，其本身以及所有子命令都会有这个全局 flag
```go
rootCmd.PersistentFlags().BoolVarP(&Verbose, "verbose", "v", false, "verbose output")
```

Local Flags: 这种 flag 只应用在特定的命令上

```go
localCmd.Flags().StringVarP(&Source, "source", "s", "", "Source directory to read from")
```

Flag 默认是可选的，但是有的命令我们希望其变为必选，可以这样操作：

```go
// Local Flags
rootCmd.Flags().StringVarP(&Region, "region", "r", "", "AWS region (required)")
rootCmd.MarkFlagRequired("region")

// Persistent Flags
rootCmd.PersistentFlags().StringVarP(&Region, "region", "r", "", "AWS region (required)")
rootCmd.MarkPersistentFlagRequired("region")

```

