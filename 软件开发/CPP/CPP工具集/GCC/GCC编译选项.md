文档：

- <https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html>

x86 Options

- `-mtune=cpu-type` ：这个选项指定了编译器生成的代码的性能优化目标。它告诉编译器，要优化代码以在特定的 CPU 类型上运行得更好。"cpu-type" 可以是一个特定的处理器型号或处理器族的名称，如 "-mtune=i686" 或 "-mtune=core2"。

- `-march=cpu-type`：这个选项指定了编译器生成的代码的目标架构。它告诉编译器，生成适合某个 CPU 架构的代码。"cpu-type" 的取值与 "-mtune" 类似，但是 "-march" 选项通常比 "-mtune" 更加严格，并且包含了更多的 CPU 指令。 -mtune-ctrl=feature-list ：这个选项告诉编译器，应该启用哪些 CPU 特性来优化代码生成。"feature-list" 是一个以逗号分隔的列表，其中每个特性都表示一个特定的 CPU 指令集或功能。
