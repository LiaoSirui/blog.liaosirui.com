## 使用

安装

```bash
go get -u github.com/golang-jwt/jwt/v4
```

导入包

```go
import "github.com/golang-jwt/jwt/v4"
```

### 生成 jwt key

```go
package main

import (
	"fmt"
	"github.com/golang-jwt/jwt/v4"
)

func main() {
	// 创建秘钥
	key := []byte("aaa")

	// 创建 Token 结构体
	claims := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user": "zhangshan",
		"pass": "123123",
	})
	// 调用加密方法，发挥 Token 字符串
	signingString, err := claims.SignedString(key)
	if err != nil {
		return
	}
	fmt.Println(signingString)

}

```

输出结果

```bash
&{ 0xc0000c2690 map[alg:ES256 typ:JWT] map[user:zhangshan]  false}
```

加密后的字符串

```bash
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXNzIjoiMTIzMTIzIiwidXNlciI6InpoYW5nc2hhbiJ9.-2-xIJXMGKV-GyhM24OKbDVqWs4dsIANBsGhzXEfEFM
```

依次解码内容

```bash
> echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXNzIjoiMTIzMTIzIiwidXNlciI6InpoYW5nc2hhbiJ9.-2-xIJXMGKV-GyhM24OKbDVqWs4dsIANBsGhzXEfEFM" | cut -d '.' -f 1| base64 -d 

{"alg":"HS256","typ":"JWT"}

> echo "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXNzIjoiMTIzMTIzIiwidXNlciI6InpoYW5nc2hhbiJ9.-2-xIJXMGKV-GyhM24OKbDVqWs4dsIANBsGhzXEfEFM" | cut -d '.' -f 2| base64 -d 

{"pass":"123123","user":"zhangshan"}
```

查看第一步

```go
// 创建 Token 结构体
claims := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
	"user": "zhangshan",
	"pass": "123123",
})
```

newWithClaims 会返回一个 Token 结构体，而这个 token 结构体有以下属性

```go
// Token represents a JWT Token.  Different fields will be used depending on whether you're
// creating or parsing/verifying a token.
type Token struct {
	Raw       string                 // The raw token.  Populated when you Parse a token
	Method    SigningMethod          // The signing method used or to be used
	Header    map[string]interface{} // The first segment of the token
	Claims    Claims                 // The second segment of the token
	Signature string                 // The third segment of the token.  Populated when you Parse a token
	Valid     bool                   // Is the token valid?  Populated when you Parse/Verify a token
}
```

对应

```go
type Token struct {
	Raw       string                 // 原始令牌
	Method    SigningMethod          // 加密方法 比如 sha256 加密
	Header    map[string]interface{} // token 头信息
	Claims    Claims                 // 加密配置，比如超时时间等
	Signature string                 // 加密后的字符串
	Valid     bool                   // 是否校验
}

```

可以通过该结构体获取到加密后的字符串信息

### 解密

```go
package main

import (
	"fmt"
	"github.com/golang-jwt/jwt/v4"
)

func main() {

	// 创建秘钥
	key := []byte("aaa")

	// 创建 Token 结构体
	claims := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user": "zhangshan",
		"pass": "123123",
	})
	// 调用加密方法，发挥 Token 字符串
	signingString, err := claims.SignedString(key)
	if err != nil {
		return
	}
	fmt.Println(signingString)

	// 根据 Token 字符串解析成 Claims 结构体
	_, err = jwt.ParseWithClaims(signingString, jwt.MapClaims{}, func(token *jwt.Token) (interface{}, error) {
		fmt.Println(token.Header)
		return []byte("aa"), nil
	})
	if err != nil {
		fmt.Println(err)
		return
	}

}

```
