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

### 配置和验证

```go
package main

import (
	"log"
	"time"

	"github.com/getsentry/sentry-go"
)

func main() {
	err := sentry.Init(sentry.ClientOptions{
    // 在此处设置您的 DSN 或设置 SENTRY_DSN 环境变量。
		Dsn: "https://examplePublicKey@o0.ingest.sentry.io/0",
    // 可以在这里设置 environment 和 release，
    // 也可以设置 SENTRY_ENVIRONMENT 和 SENTRY_RELEASE 环境变量。
		Environment: "",
		Release:     "",
    // 允许打印 SDK 调试消息。
    // 入门或尝试解决某事时很有用。
		Debug: true,
	})
	if err != nil {
		log.Fatalf("sentry.Init: %s", err)
	}
    // 在程序终止之前刷新缓冲事件。
    // 将超时设置为程序能够等待的最大持续时间。
	defer sentry.Flush(2 * time.Second)
}
```

此代码段包含一个故意的错误，因此您可以在设置后立即测试一切是否正常：

```go
package main

import (
	"log"
	"time"

	"github.com/getsentry/sentry-go"
)

func main() {
	err := sentry.Init(sentry.ClientOptions{
		Dsn: "https://examplePublicKey@o0.ingest.sentry.io/0",
	})
	if err != nil {
		log.Fatalf("sentry.Init: %s", err)
	}
	defer sentry.Flush(2 * time.Second)

	sentry.CaptureMessage("It works!")
}

```



## 参考资料

- <https://cloud.tencent.com/developer/article/1829124>

- <https://sentry.local.liaosirui.com/settings/sentry/projects/go-demo/install/go/?referrer=onboarding_task>