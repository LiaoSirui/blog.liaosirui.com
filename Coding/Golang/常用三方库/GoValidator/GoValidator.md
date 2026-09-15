`Go Validator` 是一个开源的包，为 Go 结构体提供强大且易于使用的数据验证功能。该库允许开发者为其数据结构定义自定义验证规则，并确保传入的数据满足指定的条件。`Go Validator`支持内置验证器、自定义验证器，甚至允许您链式多个验证规则以满足更复杂的数据验证需求

- 内置验证器

Go Validator 内置了多个验证器，例如 email、URL、IPv4、IPv6 等。这些验证器可以直接用于常见的验证场景

- 自定义验证器

如果内置验证器无法满足您的需求，可以通过定义自己的验证函数来创建自定义验证器。这个功能允许实现特定于应用程序需求的验证逻辑

- 验证链

Go Validator 支持将多个验证器链接在一起，用于处理更复杂的验证场景。可以创建一个验证器链，按顺序执行验证器，并在验证失败时停止，确保数据满足所有指定的条件

- 错误处理

Go Validator 提供详细的错误信息，帮助轻松地找到验证失败的原因。可以自定义这些错误信息，使其更适合您的特定用例

示例：

```go
package main

import (
	"fmt"

	"github.com/go-playground/validator/v10"
)

type User struct {
	Name  string `validate:"required"`
	Email string `validate:"required,email"`
	Age   int    `validate:"gte=18"`
}

func main() {
	u := &User{
		Name:  "tim",
		Email: "abcdefg@gmail",
		Age:   17,
	}
	validate := validator.New()
	err := validate.Struct(u)
	if err != nil {
		fmt.Println("Validation failed:")
		for _, e := range err.(validator.ValidationErrors) {
			fmt.Printf("Field: %s, Error: %s \n", e.Field(), e.Tag())
		}
	} else {
		fmt.Println("Validation succeeded")
	}
}

```

定义了一个 User 结构体，包含三个字段：`Name`、`Email` 和 `Age`。使用 `validate` 结构标签为每个字段指定验证规则。然后，创建一个新的验证器实例，并调用 `Struct` 方法验证 `User`实例。如果验证失败，将打印出错误信息，帮助找到失败的原因