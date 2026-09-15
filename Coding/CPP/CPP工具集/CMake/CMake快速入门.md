## 最小项目

使用如下 cpp 文件

```cpp
// src/main.cpp
#include <iostream>

int main() {
    std::cout << "Hello, CMake!" << std::endl;
    return 0;
}

```

`CMakeLists.txt`

```cmake
# CMake 最小版本需求
cmake_minimum_required(VERSION 4.3)

# 项目信息
project(cpp-demos
    VERSION     0.1.0
    DESCRIPTION "CMake Demo"
    LANGUAGES   CXX
)

# 全局编译选项
set(CMAKE_CXX_STANDARD            23)
set(CMAKE_CXX_STANDARD_REQUIRED   ON)
set(CMAKE_CXX_EXTENSIONS          OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 主程序
add_executable(app ${CMAKE_SOURCE_DIR}/src/main.cpp)

# Message
message(STATUS "Project       : ${PROJECT_NAME} ${PROJECT_VERSION}")
message(STATUS "C++ standard  : ${CMAKE_CXX_STANDARD}")
message(STATUS "Source dir    : ${CMAKE_SOURCE_DIR}")
message(STATUS "Binary dir    : ${CMAKE_BINARY_DIR}")

```

生成

```bash
# 配置
cmake \
  -G "Ninja Multi-Config" \
  -B build

# 构建
cmake --build build --clean-first --config Debug
cmake --build build --clean-first --config Release

# 安装
cmake --install build --prefix /opt/myapp
```

## 完整项目示例

使用如下的源文件

- `include/utils/greeter.h`

```cpp
// include/utils/greeter.h
#pragma once

#include <string>

namespace utils {

std::string greet(const std::string& name);

}

```

- `src/utils/greeter.cpp`

```cpp
// src/utils/greeter.cpp
#include "utils/greeter.h"

namespace utils {

std::string greet(const std::string& name) {
    return "Hello, " + name + "!";
}

} // namespace utils

```

- `src/main.cpp`

```cpp
// src/main.cpp
#include <iostream>

#include "utils/greeter.h"

int main() {
    std::cout << utils::greet("CMake") << std::endl;
    return 0;
}

```

此时需要添加编译目标

```cmake
# 主程序
add_executable(app)
target_sources(app
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/main.cpp
        ${CMAKE_SOURCE_DIR}/src/utils/greeter.cpp
)

# 告诉编译器去 include/ 找头文件
target_include_directories(app PRIVATE ${CMAKE_SOURCE_DIR}/include)

```

通常会编译 `greeter` 并添加到一个库文件中，而对于 app 则需要在编译的时候链接这个库

使用 gcc 编译

```bash
# 生成 obj 文件
g++ -I include -c src/utils/greeter.cpp -o greeter.o

# 编译链接生成 app
g++ -I include src/main.cpp greeter.o -o app
```

还可以用 ar 程序将目标 obj 文件打包到一个归档文件

```bash
# 静态库文件
ar rcs libgreeter.a greeter.o
# .a -> archive

# 查看文件
ar -t libgreeter.a
```

编译链接

```bash
g++ -I include src/main.cpp -L. -lgreeter  -o app 
```

CMake 对应为

```cmake
# 主程序
add_executable(app)
target_sources(app
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/main.cpp
)

# 告诉编译器去 include/ 找头文件
target_include_directories(app PRIVATE ${CMAKE_SOURCE_DIR}/include)

# 添加库
add_library(greeter)
target_sources(greeter
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/utils/greeter.cpp
)

# 告诉编译器去 include/ 找头文件
target_include_directories(greeter PRIVATE ${CMAKE_SOURCE_DIR}/include)

# 链接库
target_link_libraries(app PRIVATE greeter)

```

