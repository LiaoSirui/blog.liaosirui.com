## XMake 简介

XMake 是一个基于 Lua 的轻量级跨平台构建工具。 它非常的轻量，没有任何依赖，因为它内置了Lua 运行时。 它使用 xmake.lua 维护项目构建，相比makefile/CMakeLists.txt，配置语法更加简洁直观

官方：

- GitHub：<https://github.com/xmake-io/xmake/>
- 文档：<https://xmake.io/#/>

安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tboox/xmake/master/scripts/get.sh)
```

或者下载 Release 中的 Bundle <https://github.com/xmake-io/xmake/releases>

## XMake 快速入门

新建一个项目

```bash
xmake create -l c++ -t console
```

编辑项目根目录下的 xmake.lua 文件，添加 Conan 依赖：

```lua
add_requires("conan::zlib 1.2.11", {
    alias = "zlib", 
    debug = true,
    configs = {settings = "compiler.cppstd=14"}
})
 
add_requires("conan::openssl 1.1.1t", {
    alias = "openssl",
    configs = {options = "shared=True"}
})
 
target("test")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("openssl", "zlib")
```

Xmake 会自动调用 Conan 安装所需依赖，并完成项目构建

```bash
xmake
```

使用灵活的版本范围

```bash
add_requires("conan::zlib ~1.2", {alias = "zlib"}) -- 匹配 1.2.x 系列
```

强制更新

```bash
xmake require --update zlib
```

## Xrepo

它基于 xmake 提供的运行时，但却是一个完整独立的包管理程序，相比 vcpkg/homebrew 此类包管理器，xrepo 能够同时提供更多平台和架构的 C/C++ 包

## 参考资料

- <https://blog.csdn.net/gitblog_01416/article/details/150482883>
