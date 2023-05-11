## 使用

### 初始化项目

Sentry 通过在应用程序的运行时中使用 SDK 捕获数据

使用 Go Modules 时，无需安装任何软件即可开始将 Sentry 与 Go 程序一起使用

导入 SDK，然后当您下次构建程序时，`go` tool 会自动下载最新版本的 SDK

安装 SDK

```bash
go get github.com/getsentry/sentry-go
```

导入 SDK

```go
package main

import (
	"log"

	"github.com/getsentry/sentry-go"
)

func main() {
	err := sentry.Init(sentry.ClientOptions{
		Dsn: "https://d0cfbfd1a00a499a9f6c1ad4741d67a0@sentry.local.liaosirui.com/2",
		// Set TracesSampleRate to 1.0 to capture 100%
		// of transactions for performance monitoring.
		// We recommend adjusting this value in production,
		TracesSampleRate: 1.0,
	})
	if err != nil {
		log.Fatalf("sentry.Init: %s", err)
	}
}
```

简单验证

```go
package main

import (
	"log"
	"time"

	"github.com/getsentry/sentry-go"
)

func main() {
	err := sentry.Init(sentry.ClientOptions{
		Dsn: "https://d0cfbfd1a00a499a9f6c1ad4741d67a0@sentry.local.liaosirui.com/2",
		// Set TracesSampleRate to 1.0 to capture 100%
		// of transactions for performance monitoring.
		// We recommend adjusting this value in production,
		TracesSampleRate: 1.0,
	})
	if err != nil {
		log.Fatalf("sentry.Init: %s", err)
	}
	// Flush buffered events before the program terminates.
	defer sentry.Flush(2 * time.Second)

	sentry.CaptureMessage("It works!")
}
```



## 参考资料

- <https://cloud.tencent.com/developer/article/1829124>

- <https://sentry.local.liaosirui.com/settings/sentry/projects/go-demo/install/go/?referrer=onboarding_task>