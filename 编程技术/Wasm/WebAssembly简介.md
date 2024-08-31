## WebAssembly 简介

WebAssembly 或称 wasm 是一个低级编程语言；WebAssembly 是便携式的抽象语法树，被设计来提供比 JavaScript 更快速的编译及执行

WebAssembly 是一种定义二进制指令格式的开放标准，它支持从不同的源语言创建可移植的二进制可执行文件。 这些二进制文件可以在各种环境中运行。 它起源于 Web，并得到各大主流浏览器的支持

![img](.assets/WebAssembly%E7%AE%80%E4%BB%8B/up-a42ce7b508a880ef695b84301724ab415ee.jpg)

官方：

- 文档 GitHub 仓库：<https://github.com/bytecodealliance/wasmtime> 

### 优点

下面这些特性让 Wasm 在浏览器大放异彩，也使得它用在服务端开发颇具优势：

🌐 开放 —— 它是业界广泛采用的标准。 与过去的浏览器争夺战相反，各大公司正积极合作，实现 WASI 和 WebAssembly 应用程序的标准化

🚀 快速 —— 它可以通过大多数运行时的 JIT/AOT 能力提供类似原生的速度。 与启动 VM 或启动容器不同的是，它没有冷启动

🔒 安全 —— 默认情况下，Wasm 运行时是沙箱化的，允许安全访问内存。 基于能力的模型确保 Wasm 应用程序只能访问得到明确允许的内容。软件供应链更加安全

💼 可移植 —— 几个主要的 Wasm 运行时支持大多数 CPU（x86、ARM、RISC-V）和大多数操作系统，包括 Linux、Windows、macOS、Android、ESXi，甚至非 Posix 操作系统

🔋 高效 —— 最小的内存占用和最低的 CPU 门槛就能运行 Wasm 应用程序

🗣️ 支持多语言 ——40 多种编程语言可以编译成 Wasm，有现代的、不断改进的工具链

## 工作原理

### Wasm 如何在浏览器中工作

浏览器引擎集成了一个 Wasm 虚拟机，通常称为 Wasm 运行时，可以运行 Wasm 二进制指令。 编译器工具链（如 Emscripten）可以将源代码编译为 Wasm 目标。 这允许将现有的应用程序移植到浏览器，并直接与在客户端 Web 应用程序中运行的 JS 代码通信

![img](.assets/WebAssembly%E7%AE%80%E4%BB%8B/up-f9c8e22775a8e22e5d38adde03701d669a5.jpg)

这些技术能让传统的桌面应用程序在浏览器中运行

### Wasm 如何在服务器上运行

除了浏览器，也有可以在浏览器之外运行的 Wasm 运行时，包括 Linux、Windows 和 macOS 等传统操作系统

因为无法依赖可用的 JavaScript 引擎，所以他们使用不同的接口与外界通信，例如 WASI（[WebAssembly 系统接口](https://wasi.dev/)）；这些运行时允许 Wasm 应用程序以与 POSIX 类似（但不完全相同）的方式与其 host 系统交互。

WASI SDK 和 wasi-libc 等项目帮助人们将现有的兼容 POSIX 的应用程序编译为 WebAssembly

![img](.assets/WebAssembly%E7%AE%80%E4%BB%8B/up-da6391c1c93515e16fa7a080270480d0eab.jpg)

只需将应用程序编译成 Wasm 模块一次，然后这个同样的二进制文件就可以在任何地方运行

### 解释型语言

对于 Python、Ruby 和 PHP 等解释型语言，方法有所不同：它们的解释器是用 C 语言编写的，可以编译为 WebAssembly。 然后这个解释器编译成的 Wasm 可以用来执行源代码文件，通常以 .py、.rb、.php 等结尾。 一旦编译为 Wasm，任何带有 Wasm 运行时的平台都将能够运行这些解释型语言，即使实际的解释器从未为该平台原生编译过

![img](.assets/WebAssembly%E7%AE%80%E4%BB%8B/up-9decafaaeb1490191ad5317dfd907525940.jpg)

## WebAssembly 运行时

WebAssembly 运行时是 WebAssembly 代码的运行环境，它负责加载 WebAssembly 模块、创建 WebAssembly 实例、执行 WebAssembly 代码

- C/C++ 语言实现的 - WasmEdge、wasm3
- Rust 语言实现的 - wasmer、wasmtime
- Go 语言实现的 - WaZero

目前的主流浏览器、高版本的 Nodejs 都是支持 wasm 的

由于 Docker 新版本支持 WasmEdge，在本地也选择使用 WasmEdge 作为 WebAssembly 运行时，以便于容器内保持一致

### Wasm 如何结合 Docker 运行

Docker Desktop 现在加入了对 WebAssembly 的支持。 它是通过 containerd shim 实现的，该 shim 可以使用名为 WasmEdge 的 Wasm 运行时来运行 Wasm 应用程序。 这意味着，现在可以在 WasmEdge 运行时（模拟容器）中运行 Wasm 应用程序，而不是用典型的 Windows 或 Linux 容器运行容器镜像中二进制文件的单独进程

因此，容器镜像不需要包含正在运行的应用程序的操作系统或运行时上下文 —— 单个 Wasm 二进制文件就足够了
