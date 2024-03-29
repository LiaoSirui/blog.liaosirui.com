懒汉模式（Lazy Initialization）：懒汉模式是在第一次使用时创建实例。在 Golang 中，可以使用 `sync.Once` 确保初始化只执行一次

```go
package main

import (
    "fmt"
    "sync"
)

var once sync.Once

type single struct {
}

var singleInstance *single

func getInstance() *single {
    if singleInstance == nil {
        once.Do(
            func() {
                fmt.Println("Creating single instance now.")
                singleInstance = &single{}
            })
    } else {
        fmt.Println("Single instance already created.")
    }

    return singleInstance
}

```

饿汉模式（Eager Initialization）：饿汉模式是在程序启动时就创建实例

```go
package singleton

// Singleton 是一个单例模式的结构体
type Singleton struct {
	data int
}

var instance = &Singleton{}

// GetInstance 返回 Singleton 实例
func GetInstance() *Singleton {
	return instance
}

```

