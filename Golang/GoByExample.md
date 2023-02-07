## 1. Hello World

### Docs

Our first program will print the classic “hello world” message. Here’s the full source code.

我们的第一个程序将打印传说中的“hello world”， 右边是完整的程序代码。

```go
package main

import "fmt"

func main() {
    fmt.Println("hello world")
}

```

To run the program, put the code in hello-world.go and use go run.

要运行这个程序，先将将代码放到名为 hello-world.go 的文件中，然后执行 go run。

```bash
$ go run hello-world.go
hello world

```

Sometimes we’ll want to build our programs into binaries. We can do this using go build.

如果我们想将程序编译成二进制文件， 可以通过 go build 来达到目的。

```bash
$ go build hello-world.go
$ ls
hello-world    hello-world.go

```

We can then execute the built binary directly.

然后我们可以直接运行这个二进制文件。

```bash
$ ./hello-world
hello world

```

Now that we can run and build basic Go programs, let’s learn more about the language.

现在我们可以运行和编译基础的 Go 程序了， 让我们开始学习更多关于这门语言的知识吧。

### Source

```go
// hello-world.go
package main

import (
	"fmt"
)

func main() {
	fmt.Println("hello world")
}

```

## 2. 值 (Values)

### Docs

Go has various value types including strings, integers, floats, booleans, etc. Here are a few basic examples.

Go 拥有多种值类型，包括字符串、整型、浮点型、布尔型等。 下面是一些基础的例子。

```go
package main

import "fmt"

func main() {

    fmt.Println("go" + "lang")

    fmt.Println("1+1 =", 1+1)
    fmt.Println("7.0/3.0 =", 7.0/3.0)

    fmt.Println(true && false)
    fmt.Println(true || false)
    fmt.Println(!true)
}

```

Strings, which can be added together with +.

字符串可以通过 + 连接。

Integers and floats.

整数和浮点数

Booleans, with boolean operators as you’d expect.

布尔型，以及常见的布尔操作。

```bash
$ go run values.go
golang
1+1 = 2
7.0/3.0 = 2.3333333333333335
false
true
false

```

### Source

```go
// values.go
package main

import "fmt"

func main() {

	fmt.Println("go" + "lang")

	fmt.Println("1+1 = ", 1+1)
	fmt.Println("7.0/3.0 = ", 7.0/3.0)

	fmt.Println(true && false)
	fmt.Println(true || false)
	fmt.Println(!true)
}

```

## 3. 变量 (Variables)

### Docs


In Go, variables are explicitly declared and used by the compiler to e.g. check type-correctness of function calls.

在 Go 中，变量 需要显式声明，并且在函数调用等情况下， 编译器会检查其类型的正确性。

```go
package main

import "fmt"

func main() {

    var a = "initial"
    fmt.Println(a)

    var b, c int = 1, 2
    fmt.Println(b, c)

    var d = true
    fmt.Println(d)

    var e int
    fmt.Println(e)

    f := "apple"
    fmt.Println(f)
}

```

var declares 1 or more variables.

var 声明 1 个或者多个变量。

You can declare multiple variables at once.

你可以一次性声明多个变量。

Go will infer the type of initialized variables.

Go 会自动推断已经有初始值的变量的类型。

Variables declared without a corresponding initialization are zero-valued. For example, the zero value for an int is 0.

声明后却没有给出对应的初始值时，变量将会初始化为 零值 。 例如，int 的零值是 0

The := syntax is shorthand for declaring and initializing a variable, e.g. for var f string = "apple" in this case.

:= 语法是声明并初始化变量的简写， 例如 var f string = "short" 可以简写为右边这样。

```bash
$ go run variables.go
initial
1 2
true
0
apple

```

### Source

```go
// variables.go
package main

import "fmt"

func main() {

	var a = "initial"
	fmt.Println(a)

	var b, c int = 1, 2
	fmt.Println(b, c)

	var d = true
	fmt.Println(d)

	var e int
	fmt.Println(e)

	f := "short"
	fmt.Println(f)

}

```

## 4. 常量 (Constants)

### Docs

Go supports constants of character, string, boolean, and numeric values.

Go 支持字符、字符串、布尔和数值 常量。

```go
package main

import (
    "fmt"
    "math"
)

const s string = "constant"

func main() {
    fmt.Println(s)

    const n = 500000000

    const d = 3e20 / n
    fmt.Println(d)

    fmt.Println(int64(d))

    fmt.Println(math.Sin(n))
}

```

const declares a constant value.

const 用于声明一个常量。

A const statement can appear anywhere a var statement can.

const 语句可以出现在任何 var 语句可以出现的地方

Constant expressions perform arithmetic with arbitrary precision.

常数表达式可以执行任意精度的运算

A numeric constant has no type until it’s given one, such as by an explicit conversion.

数值型常量没有确定的类型，直到被给定某个类型，比如显式类型转化。

A number can be given a type by using it in a context that requires one, such as a variable assignment or function call. For example, here math.Sin expects a float64.

一个数字可以根据上下文的需要（比如变量赋值、函数调用）自动确定类型。 举个例子，这里的 math.Sin 函数需要一个 float64 的参数，n 会自动确定类型。

```text
$ go run constant.go 
constant
6e+11
600000000000
-0.28470407323754404

```

### Source

```go
package main

import (
	"fmt"
	"math"
)

const s string = "constant"

func main() {
	fmt.Println(s)

	const n = 500000000

	const d = 3e20 / n
	fmt.Println(d)

	fmt.Println(int64(d))

	fmt.Println(math.Sin(n))
}

```

## 5.For 循环 (For)

### Docs

for is Go’s only looping construct. Here are some basic types of for loops.

for 是 Go 中唯一的循环结构。这里会展示 for 循环的一些基本使用方式。

```go
package main

import "fmt"

func main() {

    i := 1
    for i <= 3 {
        fmt.Println(i)
        i = i + 1
    }

    for j := 7; j <= 9; j++ {
        fmt.Println(j)
    }

    for {
        fmt.Println("loop")
        break
    }

    for n := 0; n <= 5; n++ {
        if n%2 == 0 {
            continue
        }
        fmt.Println(n)
    }
}

```

The most basic type, with a single condition.

最基础的方式，单个循环条件。

A classic initial/condition/after for loop.

经典的初始 / 条件 / 后续 for 循环。

for without a condition will loop repeatedly until you break out of the loop or return from the enclosing function.

不带条件的 for 循环将一直重复执行， 直到在循环体内使用了 break 或者 return 跳出循环。

You can also continue to the next iteration of the loop.

你也可以使用 continue 直接进入下一次循环。

```bash
$ go run for.go
1
2
3
7
8
9
loop
1
3
5

```

We’ll see some other for forms later when we look at range statements, channels, and other data structures.

我们在后续教程中学习 range 语句，channels 以及其他数据结构时， 还会看到一些 for 的其它用法


### Source

```go
package main

import "fmt"

func main() {

	i := 1
	for i <= 3 {
		fmt.Println(i)
		i = i + 1
	}

	for j := 7; j <= 9; j++ {
		fmt.Println(j)
	}

	for {
		fmt.Println("loop")
		break
	}

	for n := 0; n <= 5; n++ {
		if n%2 == 0 {
			continue
		}
		fmt.Println(n)
	}

}

```

