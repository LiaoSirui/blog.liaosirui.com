## graphql-go 简介

官方：

- GitHub 仓库：<https://github.com/graphql-go/graphql>

- 代码参考：<https://graphql.cn/code/#go>

**为什么要用 GraphQL？** 为了让 api 具有更强的适应性，采用 GraphQL 来编写查询接口是个不错的选择。现在的 API 需要适应的场景太多了，而且迭代节奏也很快，RESTful 的查询接口在一些复杂的场景下显得特别的繁杂，如多重嵌套的资源

## 示例

从 schema 定义开始

- `schema/schema.go`

```go
// internal/app/demo/schema/schema.go
package schema

import (
	"github.com/graphql-go/graphql"
)

// 定义根查询节点
var rootQuery = graphql.NewObject(graphql.ObjectConfig{
	Name:        "RootQuery",
	Description: "Root Query",
	Fields: graphql.Fields{
		"hello": &queryHello, // queryHello 参考 schema/hello.go
	},
})

// 定义 Schema 用于 http handler 处理
var Schema, _ = graphql.NewSchema(graphql.SchemaConfig{
	Query:    rootQuery,
	Mutation: nil, // 需要通过 GraphQL 更新数据，可以定义 Mutation
})

```

- `schema/hello.go`

```go
// internal/app/demo/schema/hello.go
package schema

import (
	"github.com/LiaoSirui/demo/internal/app/demo/model"

	"github.com/graphql-go/graphql"
)

// 定义查询对象的字段，支持嵌套
var helloType = graphql.NewObject(graphql.ObjectConfig{
	Name:        "Hello",
	Description: "Hello Model",
	Fields: graphql.Fields{
		"id": &graphql.Field{
			Type: graphql.Int,
		},
		"name": &graphql.Field{
			Type: graphql.String,
		},
	},
})

// 处理查询请求
var queryHello = graphql.Field{
	Name:        "QueryHello",
	Description: "Query Hello",
	Type:        graphql.NewList(helloType),
	// Args 是定义在 GraphQL 查询中支持的查询字段
	// 可自行随意定义，如加上 limit,start 这类
	Args: graphql.FieldConfigArgument{
		"id": &graphql.ArgumentConfig{
			Type: graphql.Int,
		},
		"name": &graphql.ArgumentConfig{
			Type: graphql.String,
		},
	},
	// Resolve 是一个处理请求的函数，具体处理逻辑可在此进行
	Resolve: func(p graphql.ResolveParams) (result interface{}, err error) {
		// Args 里面定义的字段在 p.Args 里面，对应的取出来
		// 因为是 interface{} 的值，需要类型转换，可参考类型断言 type assertion
		id, _ := p.Args["id"].(int)
		name, _ := p.Args["name"].(string)

		// 调用 Hello 这个 model 里面的 Query 方法查询数据
		return (&model.Hello{}).Query(id, name)
	},
}

```

- `model/hello.go`

```go
// internal/app/demo/model/hello.go
package model

type Hello struct {
	Id   int    `json:"id"`
	Name string `json:"name"`
}

func (hello *Hello) Query(id int, name string) (hellos []Hello, err error) {
	allHello := []Hello{
		{0, "vinli"},
		{1, "daisy"},
	}
	for _, v := range allHello {
		if id >= 0 && len(name) <= 0 {
			if v.Id == id {
				hellos = append(hellos, v)
			}
		}

		if id < 0 && len(name) > 0 {
			if v.Name == name {
				hellos = append(hellos, v)
			}
		}

		if id >= 0 && len(name) > 0 {
			if v.Name == name && v.Id == id {
				hellos = append(hellos, v)
			}
		}

		if id < 0 && len(name) <= 0 {
			hellos = append(hellos, v)
		}
	}
	return
}

```

准备好了 GraphQL 在 Go 里面需要的东西之后，尝试与 Gin 结合

- `controller/graphql/graphql.go`

```go
// internal/app/demo/controller/graphql/graphql.go
package graphql

import (
	"github.com/LiaoSirui/demo/internal/app/demo/schema"

	"github.com/gin-gonic/gin"
	"github.com/graphql-go/handler"
)

func GraphqlHandler() gin.HandlerFunc {
	h := handler.New(&handler.Config{
		Schema:   &schema.Schema,
		Pretty:   true,
		GraphiQL: true,
	})

	// 只需要通过 Gin 简单封装即可
	return func(c *gin.Context) {
		h.ServeHTTP(c.Writer, c.Request)
	}
}

```

注册 router 并启动 server

- `router/router.go`

```go
// internal/app/demo/router/router.go
package router

import (
	"github.com/LiaoSirui/demo/internal/app/demo/controller/graphql"

	"github.com/gin-gonic/gin"
)

func SetRouter(router *gin.Engine) error {

	// GET 方法用于支持 GraphQL 的 web 界面操作
	// 如果不需要 web 界面，可根据自己需求用 GET / POST 或者其他都可以
	router.POST("/graphql", graphql.GraphqlHandler())
	router.GET("/graphql", graphql.GraphqlHandler())
	return nil
}

```

- `server.go`

```go
// internal/app/demo/server.go
package app_demo

import (
	"github.com/LiaoSirui/demo/internal/app/demo/router"
	"github.com/gin-gonic/gin"
)

func StartServer() error {
	engine := gin.Default()
	engine.GET("/", func(ctx *gin.Context) {
		ctx.JSON(200, gin.H{
			"msg": "请求成功",
		})
	})
	router.SetRouter(engine)
	_ = engine.Run(":9090")
	return nil
}

```

- Main 函数

```go
// cmd/demo/main.go
package main

import (
	app_demo "github.com/LiaoSirui/demo/internal/app/demo"
)

func main() {
	// app entry
	app_demo.StartServer()
}

```

运行之后的 web 界面，执行查询

```graphql
{
  hello {
    id
    name
  }
}

```

得到返回结果

```json
{
  "data": {
    "hello": [
      {
        "id": 0,
        "name": "vinli"
      }
    ]
  }
}
```

