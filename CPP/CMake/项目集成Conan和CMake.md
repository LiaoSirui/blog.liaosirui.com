## 基础结构

### 项目结构概述

建一个 C++ 项目时，通常会遇到以下几种常见的项目结构：

1. 简单项目：单个应用程序或库，无外部依赖或仅有少量依赖
2. 中等复杂度项目：包含多个子模块，每个模块可能是单独的库或应用，可能有较多的外部依赖
3. 复杂项目：包含多个子模块，并且这些模块之间有复杂的依赖关系，且可能需要在不同的平台上进行构建

在这些项目结构中，不同的子模块可能有不同的依赖管理需求

### CMake 与 Conan 的基本角色

CMake 的主要任务是负责项目的构建过程，它定义了如何从源代码生成可执行文件或库：

- 跨平台支持：CMake 能够生成适用于不同平台的构建文件，例如 Makefiles、Visual Studio 项目文件等。
- 编译选项管理：CMake 可以方便地管理编译器选项、链接选项等配置。
- 构建过程的组织：CMake 通过 `CMakeLists.txt` 文件描述项目结构，并且可以通过 `add_subdirectory()` 来组织多个模块的构建。

Conan 的主要任务是管理项目的外部依赖，它提供了一种方式来获取、构建和管理库的版本：

- 依赖管理：Conan 能够自动解析和下载项目所需的外部库，并管理库的版本
- 与 CMake 集成：Conan 可以生成 CMake 的构建选项，从而将外部依赖集成到 CMake 的构建过程中
- 包的创建与发布：通过 `conanfile.py`，可以定义如何创建和发布一个 Conan 包

### 结合使用 CMake 和 Conan

- 简单项目：对于简单项目，CMake 足以完成整个项目的搭建，所有的依赖管理都可以通过 `CMakeLists.txt` 来完成，而无需引入 Conan。
- 中等复杂度项目：当项目逐渐复杂化，特别是有多个子模块时，可以考虑在根目录使用 Conan 来管理全局依赖，而子模块仍然使用 `CMakeLists.txt`。此时，根目录的 `conanfile.py` 可以统一管理项目依赖，而每个子模块通过 `CMakeLists.txt` 定义各自的构建逻辑。
- 复杂项目：对于复杂项目，尤其是那些子模块之间有复杂依赖关系，且每个模块都可能有自己独特的依赖需求时，可以为每个子模块单独使用 `conanfile.py`。这时，每个子模块的 `conanfile.py` 负责该模块的依赖管理，而 `CMakeLists.txt` 负责构建逻辑。这样的设计使得每个模块可以独立管理和构建，增强了项目的可维护性。

### 项目实例

假设有一个复杂的项目，包含以下几个子模块：

- 核心库 (core)：一个底层库，无外部依赖
- 工具库 (tools)：依赖于 `core` 库，同时依赖第三方库 `Boost`
- 应用程序 (app)：依赖于 `core` 和 `tools` 库，同时依赖第三方库 `fmt`

可以采取以下策略：

1. 根目录：使用 `conanfile.py` 来管理全局的依赖，包括 `Boost` 和 `fmt`，并通过 CMake 将这些依赖注入到项目中。
2. 子模块：
   - `core`：只使用 `CMakeLists.txt`，因为它没有外部依赖
   - `tools`：使用 `CMakeLists.txt` 定义构建，同时使用 `conanfile.py` 来管理 `Boost` 的依赖
   - `app`：类似于 `tools`，使用 `CMakeLists.txt` 进行构建，`conanfile.py` 管理 `fmt` 的依赖

这种架构使得项目在整体上具有很好的灵活性和模块化，方便在未来扩展或调整各个模块的依赖和构建逻辑

## 实践

### 项目结构概览

假设项目名为 `MyProject`，其包含三个子模块：`core`、`tools` 和 `app`。项目结构如下：

```bash
MyProject/
├── CMakeLists.txt
├── conanfile.py
├── core/
│   ├── CMakeLists.txt
│   └── src/
│       └── core.cpp
├── tools/
│   ├── CMakeLists.txt
│   ├── conanfile.py
│   └── src/
│       └── tools.cpp
└── app/
    ├── CMakeLists.txt
    ├── conanfile.py
    └── src/
        └── app.cpp

```

在这个结构中：

- `core` 是一个不依赖任何外部库的基础模块
- `tools` 依赖 `core` 和第三方库 `Boost`
- `app` 依赖 `core` 和 `tools`，并且依赖第三方库 `fmt`

### 根目录的 CMake 和 Conan 配置

根目录的 `CMakeLists.txt` 文件负责全局配置，并将子模块添加到构建中：

```cmake
cmake_minimum_required(VERSION 3.15)
project(MyProject)

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 使用 Conan 的配置（假设 Conan 已经生成相关文件）
include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

# 添加子模块
add_subdirectory(core)
add_subdirectory(tools)
add_subdirectory(app)

```

根目录的 `conanfile.py` 文件管理整个项目的依赖。由于 `core` 没有外部依赖，因此这里只管理 `Boost` 和 `fmt` 的依赖：

```python
# pylint: disable=missing-module-docstring
# pylint: disable=missing-class-docstring
# pylint: disable=missing-function-docstring
from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout


class MyProjectConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    requires = (
        "boost/1.81.0",  # boost 库
        "fmt/10.1.1",  # fmt 库
    )
    generators = "cmake", "cmake_find_package"

    def layout(self):
        cmake_layout(self)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.libs = ["MyProject"]

```

在这个 `conanfile.py` 中，定义了项目的依赖库 `Boost` 和 `fmt`，并且使用 `cmake` 生成器来为 CMake 提供依赖信息

### 子模块的 CMake 和 Conan 配置

`core` 模块没有外部依赖，因此只需要简单的 `CMakeLists.txt` 文件

```cmake
```

