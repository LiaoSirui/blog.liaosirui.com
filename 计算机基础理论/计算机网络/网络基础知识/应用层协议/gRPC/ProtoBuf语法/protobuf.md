
## 简介

protobuf 是一种数据交换格式, 由三部分组成:

- proto 文件: 使用的 proto 语法的文本文件，用来定义数据格式
- protoc: protobuf 编译器(compile)，将 proto 文件编译成不同语言的实现，这样不同语言中的数据就可以和 protobuf 格式的数据进行交互
- protobuf 运行时(runtime): protobuf 运行时所需要的库，和 protoc 编译生成的代码进行交互

## Proto 文件

proto语法现在有 proto2 和 proto3 两个版本, 推荐使用 proto3

```protobuf
syntax = "proto3";

service Greeter {
    rpc SayHello(HelloRequest) returns (HelloReply) {}
    rpc SayHelloAgain(HelloRequest) returns (HelloReply) {}
}

message HelloRequest {
    string name = 1;
}

message HelloReply {
    string message = 1;
}
```

使用 protobuf 的过程：编写 proto 文件 -> 使用 protoc 编译 -> 添加 protobuf 运行时 -> 项目中集成

更新 protobuf 的过程:修改 proto 文件 -> 使用 protoc 重新编译 -> 项目中修改集成的地方
