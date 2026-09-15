## C++ 版本

- Traditional C++
  - C++98、C++03
- Modern C++
  - [C++11](https://cppreference.cn/w/cpp/11)、[C++14](https://cppreference.cn/w/cpp/14)、[C++17](https://cppreference.cn/w/cpp/17)
  - [C++20](https://cppreference.cn/w/cpp/20)、[C++23](https://cppreference.cn/w/cpp/23)
  - [C++26](https://cppreference.cn/w/cpp/26)

编译器支持：<https://cppreference.cn/w/cpp/compiler_support>

## 环境构建

RockyLinux

- GCC 编译工具链

```bash
# latest: gcc-toolset-16
dnf install -y gcc-toolset-15
source /opt/rh/gcc-toolset-15/enable
# scl enable gcc-toolset-15 zsh

gcc -v
g++ -v
```

- LLVM 编译器

```bash
dnf install -y llvm-toolset clang-devel
# old: llvm19-toolset
```

- CMake

CMake: <https://cmake.org/download/>

```bash
wget https://github.com/Kitware/CMake/releases/download/v4.3.2/cmake-4.3.2-linux-x86_64.tar.gz
tar zxvf cmake-4.3.2-linux-x86_64.tar.gz -C /usr/local/
export PATH=/usr/local/cmake-4.3.2-linux-x86_64/bin${PATH:+:${PATH}}
cmake --version
```

- Conan

```bash
# conan2
pipx install conan
pipx ensurepath
```

- Ninja

```bash
dnf install -y ninja-build
```

## 项目结构

现代 C++ 工程通常采用以下层级结构，方便源码管理与编译：

```bash
MyProject/
├── bin/              # 存放编译生成的可执行文件
├── build/            # 存放 CMake 编译产生的中间文件
├── cmake/            # 自定义的 CMake 脚本或 Find 模块
├── docs/             # 项目文档、API 说明等
├── extern/           # 第三方依赖库（也可使用 vcpkg 或 conan）
├── include/          # 公共头文件 (.h / .hpp)
├── src/              # 源代码文件 (.cpp)
├── tests/            # 单元测试代码
├── CMakeLists.txt    # 顶层 CMake 构建脚本
├── LICENSE           # 开源许可证
└── README.md         # 项目说明文档
```

