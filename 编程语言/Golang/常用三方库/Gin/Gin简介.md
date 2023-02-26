## Gin 简介

Gin 是一个用 Go 编写的开源 web 框架

它是一个类似于 `martini` 但拥有更好性能的 `API` 框架，路由解析由于使用的是`httprouter`，速度提高了近 40 倍

官方：

- 文档：<https://gin-gonic.com/docs/>
- GitHub 仓库：<https://github.com/gin-gonic/gin>

## 入门程序

创建一个项目

```bash
mkdir gin-demo && cd gin-demo

# 初始化 golang 项目
go mod init code.liaosirui.com/demo/gin-demo
```

添加一个 `main.go` 作为程序的入口

```go
package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	// 创建一个默认的路由引擎
	engine := gin.Default()
	// 注册路由并设置一个匿名的 handlers，返回 JSON 格式数据
	engine.GET("/", func(ctx *gin.Context) {
		ctx.JSON(200, gin.H{
			"msg": "请求成功",
		})
	})
	// 启动服务，并监听端口 9090
	// 不填默认监听 0.0.0.0:8080
	_ = engine.Run(":9090")
}

```

下载依赖

```bash
> go mod tidy

go: finding module for package github.com/gin-gonic/gin
go: downloading github.com/gin-gonic/gin v1.9.0
...
```

运行

```bash
go run main.go
```

请求接口进行测试

```bash
> curl 127.0.0.1:9090
{"msg":"请求成功"}
```

