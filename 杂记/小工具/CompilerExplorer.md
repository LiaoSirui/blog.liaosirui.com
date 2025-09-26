`Compiler Explorer` 是一个交互式编译器探索网站。支持 `C`、`C++`、`C#`、`F#`、`Rust`、`Go`、`D`、`Haskell`、`Swift`、`Pascal`、`ispc`、`Python`、`Java` 或任何其他 `30` 多种语言编辑代码，允许我们以交互方式编写、编译和反汇编源代码，所有这些都可以在浏览器中轻松完成。可以根据需要指定编译标志。

每种语言都支持多个编译器，有许多不同的工具和可视化可用，并且 UI 布局是可配置的。

运行容器

```yaml
services:
  compiler-explorer:
    image: madduci/docker-compiler-explorer:latest
    container_name: compiler-explorer
    ports:
      - 10240:10240
    restart: on-failure
    stop_grace_period: 1m30s

```

