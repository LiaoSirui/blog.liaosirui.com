## trace.Provider

使用 `app -> collector-contrib` 进行转发， 应用不直接对后端的存储，适配性更高

`collector-contrib` 最常见的两种协议 `grpc / http(s)`。传入 endpoint 地址进行初始化 Provider， 参考代码 grpcExporter 和 httpExporter

初始化项目

```bash
go mod init opentelemetry-gin-demo
```

添加 main 函数

```bash
mkdir -p cmd/webapp
touch cmd/webapp/main.go
```

### 使用 Otelgin 接入 TraceProvider

1. 第一步初始化好的 trace.Provider 需要通过 Option 的方式传入, 参考代码 otel middleware option

   ```go
   import (
   	"github.com/gin-gonic/gin"
   	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
   )
   
   func Register(appname string, endpoint string) gin.HandlerFunc {
   
   	opts := []otelgin.Option{
   		ProviderOption(appname, endpoint),
   		PropagationExtractOption(),
   	}
   
   	return otelgin.Middleware(appname, opts...)
   }
   ```

2. 在 gin 已经实现了一个官方的 Middleware 支持 OpenTelemetry.  参考代码：<https://github.com/open-telemetry/opentelemetry-go-contrib/blob/v1.20.0/instrumentation/github.com/gin-gonic/gin/otelgin/gintrace.go#L38-L105>

3. 使用 `c.Set(k,v)` 将 provider 放入了 gin 自己实现的 Context 中 <https://github.com/open-telemetry/opentelemetry-go-contrib/blob/v1.20.0/instrumentation/github.com/gin-gonic/gin/otelgin/gintrace.go#L65>

   ```go
   c.Set(tracerKey, tracer)
   ```

4. `tracer.Start` 启动了第一个 Span， 并将生成的 ctx 放入 Request 中向下传递。之后将从 Request 中取 tracer provider <https://github.com/open-telemetry/opentelemetry-go-contrib/blob/v1.20.0/instrumentation/github.com/gin-gonic/gin/otelgin/gintrace.go#L87>

   ```go
   ctx, span := tracer.Start(ctx, spanName, opts...)
   ```

5. 初始化状态。使用 `semconv.XXXXX` 方法进行 span 状态设置。semconv 是一个 OpenTelemetry 实现的 标准/模版 方法， 用于处理 http 请求中的各种情况 <https://github.com/open-telemetry/opentelemetry-go-contrib/blob/v1.20.0/instrumentation/github.com/gin-gonic/gin/otelgin/gintrace.go#L75-L103>

   ```go
   var spanName string
   if cfg.SpanNameFormatter == nil {
   	spanName = c.FullPath()
   } else {
   	spanName = cfg.SpanNameFormatter(c.Request)
   }
   if spanName == "" {
   	spanName = fmt.Sprintf("HTTP %s route not found", c.Request.Method)
   } else {
   	rAttr := semconv.HTTPRoute(spanName)
   	opts = append(opts, oteltrace.WithAttributes(rAttr))
   }
   ctx, span := tracer.Start(ctx, spanName, opts...)
   defer span.End()
   
   // pass the span through the request context
   c.Request = c.Request.WithContext(ctx)
   
   // serve the request to the next middleware
   c.Next()
   
   status := c.Writer.Status()
   span.SetStatus(semconvutil.HTTPServerStatus(status))
   if status > 0 {
   	span.SetAttributes(semconv.HTTPStatusCode(status))
   }
   if len(c.Errors) > 0 {
   	span.SetAttributes(attribute.String("gin.errors", c.Errors.String()))
   }
   ```

### 完成单服务的 Trace 树状结构

在使用的时候， 需要使用 Context 在不同的 函数/方法 之间传递 Provider。每个 函数/方法 创建自己的 Span， 以此实现调用的父子关系

1. 封装了一个函数 `Span(xxxx)` 提出 context 中的 provider 并启动 `tracer.Start(xxx)`

   对 ctx 进行了判断， 如果 ctx 是 `gin.Context` 的话， 就需要从 Request 中携带的 context

   额外的进行了一些 公共属性 的设置， 例如运行的主机名

   ```go
   func Span(ctx context.Context, spanName string, opts ...trace.SpanStartOption) (spanctx context.Context, span trace.Span) {
   	value := ctx.Value(global.TracerKey)
   	tracer, ok := value.(trace.Tracer)
   	if !ok {
   		return ctx, nil
   	}
   
   	// gin 特殊
   	if c, ok := ctx.(*gin.Context); ok {
   		spanctx, span = tracer.Start(c.Request.Context(), spanName, opts...)
   
   		/*
   			在这里每次注入新的 Attr
   			1. host
   		*/
   		// 1. 从 context 中获取 "public attr"
   		// attr:=ctx.Value("")
   		// 2. 注入 public attr
   		// span.SetAttributes(attr)
   
   		spanctx = context.WithValue(spanctx, global.TracerKey, tracer)
   		// return spanctx, span
   	} else {
   		spanctx, span = tracer.Start(ctx, spanName, opts...)
   	}
   
   	// 设置 Attr
   	attrkv, ok := ctx.Value("attrkv").(map[string]string)
   	if ok {
   		SpanSetStringAttr(span, attrkv)
   	}
   
   	SpanSetStringAttr(span, map[string]string{
   		"server.host": os.Getenv("HOSTNAME"),
   	})
   
   	return spanctx, span
   }
   ```

1. 通过 context 在不同 函数/方法 之间传递 tracer provider， 每个地方都调用了 Span(xxx) 跟踪当前情况

   ```go
   package user
   
   import (
   	"context"
   	"errors"
   	"fmt"
   	"net/http"
   	"os"
   
   	"github.com/gin-gonic/gin"
   	"go.opentelemetry.io/otel/codes"
   	semconv "go.opentelemetry.io/otel/semconv/v1.12.0"
   	"go.opentelemetry.io/otel/trace"
   	"github.com/tangx/opentelemetry-gin-demo/pkg/httpclient"
   	"github.com/tangx/opentelemetry-gin-demo/pkg/utils"
   )
   
   var (
   	USER_INFO_HOST = os.Getenv("USER_INFO_HOST")
   )
   
   // Info 获取用户信息
   // https://zhuanlan.zhihu.com/p/608282493
   func Info(c *gin.Context) {
   
   	username := c.GetHeader("UserName")
   	if username == "" {
   		username = "jane"
   	}
   
   	name := fmt.Sprintf("RequestURI: %s", c.Request.RequestURI)
   	spanctx, span := utils.Span(c, name)
   	defer span.End()
   
   	data, err := info(spanctx, username)
   	if err != nil {
   		c.JSON(http.StatusInternalServerError, fmt.Sprintf("Error: %v", err))
   
   		return
   	}
   
   	c.JSON(http.StatusOK, data)
   }
   
   func info(ctx context.Context, name string) (*UserInfo, error) {
   
   	// 注入 attr 属性
   	ctx = utils.SpanContextWithAttr(ctx, map[string]string{"user.name": name})
   
   	// 设置为 consumer kind
   	opt := trace.WithSpanKind(trace.SpanKindConsumer)
   
   	spanctx, span := utils.Span(ctx, "user info integration", opt)
   	if span != nil {
   		defer span.End()
   	}
   
   	userinfo := &UserInfo{
   		Name: name,
   	}
   
   	b, err := balance(spanctx, name)
   	if err != nil {
   		return nil, err
   	}
   	userinfo.Balance = b
   
   	c, err := cellphone(spanctx, name)
   	if err != nil {
   		return nil, err
   	}
   	userinfo.Cellphone = c
   
   	return userinfo, nil
   }
   
   // balance get user balance
   func balance(ctx context.Context, name string) (int, error) {
   	ctx = utils.SpanContextWithAttr(ctx, map[string]string{"user.kind": "func.balance"})
   
   	_, span := utils.Span(ctx, "user balance")
   	if span != nil {
   		defer span.End()
   	}
   
   	switch name {
   	case "guanyu":
   		return 100, nil
   
   	case "zhangfei":
   		return 200, nil
   	}
   
   	return 0, errors.New("unknown user")
   }
   
   func cellphone(ctx context.Context, name string) (string, error) {
   	ctx = utils.SpanContextWithAttr(ctx, map[string]string{"user.kind": "func.cellphone"})
   
   	ctx, span := utils.Span(ctx, "user cellphone")
   	if span != nil {
   		defer span.End()
   	}
   
   	switch name {
   	case "guanyu":
   		return "131-1111-2222", nil
   		// case "zhangfei":
   		// 	return "132-2222-3333", nil
   	}
   
   	err := errors.New("unknown user or cellphone not found")
   
   	// 提交错误日志
   	span.RecordError(err)
   
   	// 设置状态
   	span.SetStatus(codes.Error, "unsupport user")
   
   	attrs := semconv.HTTPAttributesFromHTTPStatusCode(500)
   	span.SetAttributes(attrs...)
   
   	// 设置属性
   	// span.SetAttributes(attribute.KeyValue{
   	// 	Key:   "user.kind",
   	// 	Value: attribute.StringValue("user.cellphone"),
   	// })
   
   	if os.Getenv("PORT") != "9099" {
   		httpclient.GET(ctx, "http://127.0.0.1:9099/api/v1/user/info")
   	}
   
   	return "", err
   }
   
   type UserInfo struct {
   	Name      string
   	Balance   int
   	Cellphone string
   }
   
   ```

### 应答客户端时， 在 Header 中默认添加 TraceID

当有需求的时候（例如出现访问错误）， 需要把 TraceID 返回给用户。 这样用户在报错的时候提供 TraceID 可以快速 debug。

![img](.assets/Golang示例应用/propagation.jpg)

创建了一个 Gin Middleware， 将 TraceID 从 Context 中提取出来， 并放到 Response Header 中

其中用到了 `propagation` 标准库

```go
package otel

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/propagation"
	"github.com/tangx/opentelemetry-gin-demo/pkg/utils"
)

func ReponseTraceID() gin.HandlerFunc {
	return func(c *gin.Context) {
		spanctx, span := utils.Span(c, "Response Propagation")
		if span == nil {
			c.Next()
			return
		}
		defer span.End()

		// 4. 应答客户端时， 在 Header 中默认添加 TraceID
		traceid := span.SpanContext().TraceID().String()
		c.Header("TraceID", traceid)

		// 6. 向后传递 Header: traceparent
		pp := propagation.NewCompositeTextMapPropagator(
			propagation.TraceContext{},
		)

		carrier := propagation.MapCarrier{}
		pp.Inject(spanctx, carrier)

		for k, v := range carrier {
			c.Header(k, v)
		}
	}
}

```

### 获取前方传递的 traceparent 信息

在上图 App2 中， 能够拿到 App 传递的 Traceparent header， 这样就保证了接收侧的 TraceID 连贯性。

在 `otelgin` 中， 提供了一个 Option 注入

```go
otelgin.WithPropagators(pptc)
```

在 gin 中注册 provider 的时候， 使用 Option 即可

```go
func Register(appname string, endpoint string) gin.HandlerFunc {

	opts := []otelgin.Option{
		ProviderOption(appname, endpoint),
		PropagationExtractOption(),
	}

	return otelgin.Middleware(appname, opts...)
}

// PropagationExtractOption 从上游获取 traceparent, tracestate
func PropagationExtractOption() otelgin.Option {
	tc := propagation.TraceContext{}
	return otelgin.WithPropagators(tc)
}

```

### 向后传递 Header: traceparent

为了保证 TraceID 的连贯性， 除了接收侧（App2）。 在 发送侧 App1 也需要做对应的操作。

从 Context 中读取 TraceParent 并注入到 HTTP Request Header 中。

 通过 `propagation` 标准库将 Header 字段找出来。

```go
package utils

import (
	"context"

	"go.opentelemetry.io/otel/propagation"
)

func MapCarrier(ctx context.Context) map[string]string {
	// 6. 向后传递 Header: traceparent
	pp := propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
	)

	carrier := propagation.MapCarrier{}
	pp.Inject(ctx, carrier)

	return carrier
}

```

将找到的 Header 字段全部放到新创建的 Request Header 中。

```go
func ReponseTraceID() gin.HandlerFunc {
	return func(c *gin.Context) {
		spanctx, span := utils.Span(c, "Response Propagation")
		if span == nil {
			c.Next()
			return
		}
		defer span.End()

		// 4. 应答客户端时， 在 Header 中默认添加 TraceID
		traceid := span.SpanContext().TraceID().String()
		c.Header("TraceID", traceid)

		// 6. 向后传递 Header: traceparent
		pp := propagation.NewCompositeTextMapPropagator(
			propagation.TraceContext{},
		)

		carrier := propagation.MapCarrier{}
		pp.Inject(spanctx, carrier)

		for k, v := range carrier {
			c.Header(k, v)
		}
	}
}
```

### 在 Trace 中添加 Error Log, Status, Attr

标准 API 用法。

1. `span.RecordError` 提交错误日志
2. `span.SetStatus` 设置 trace span 状态。 分位 error 和 ok
3. `span.SetAttributes` 设置属性，可以通过属性搜索。 (所有属性被索引)。

### 修改 Trace 中的 Kind 类型。 已知 Otelngin 提供的值为 Sever， 默认的值为 internal

在 Tracer 启动的时候传入。 启动之后 Span 不能设置。 可以通过 **Kind** 类型， 表明当前步骤类型， 以后在 **检索/查询** 的时候更直观。

1. (*) Kind 是标准字段， 是枚举类型。 其中包含 `internal, server, client, producer, consumer` 可以在代码中看到
2. 可以通过 `trace.WithSpanKind`， 在 `trace.Start` 时作为 opt 传入。 之后不能通过 span 设置

### 添加自定义属性字段

1. (*) 自定义字段(Attribute)（类似 host）.

2. 每个 span 都是独立的。 因此 public attributes 需要在公共函数中注入

   ```go
   func Span(ctx context.Context, spanName string, opts ...trace.SpanStartOption) (spanctx context.Context, span trace.Span) {
   	value := ctx.Value(global.TracerKey)
   	tracer, ok := value.(trace.Tracer)
   	if !ok {
   		return ctx, nil
   	}
   
   	// gin 特殊
   	if c, ok := ctx.(*gin.Context); ok {
   		spanctx, span = tracer.Start(c.Request.Context(), spanName, opts...)
   
   		/*
   			在这里每次注入新的 Attr
   			1. host
   		*/
   		// 1. 从 context 中获取 "public attr"
   		// attr:=ctx.Value("")
   		// 2. 注入 public attr
   		// span.SetAttributes(attr)
   
   		spanctx = context.WithValue(spanctx, global.TracerKey, tracer)
   		// return spanctx, span
   	} else {
   		spanctx, span = tracer.Start(ctx, spanName, opts...)
   	}
   
   	// 设置 Attr
   	attrkv, ok := ctx.Value("attrkv").(map[string]string)
   	if ok {
   		SpanSetStringAttr(span, attrkv)
   	}
   
   	SpanSetStringAttr(span, map[string]string{
   		"server.host": os.Getenv("HOSTNAME"),
   	})
   
   	return spanctx, span
   }
   ```

3. 因此使用 Context 进行传递， 在不同的 方法/函数 内进行公共 attr 共享。