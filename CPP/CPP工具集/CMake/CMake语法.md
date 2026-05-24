## 变量

### 变量类型

- 普通变量（Normal Variables，当前目录有效）

仅在当前 `CMakeLists.txt` 文件及其子目录中有效

```cmake
set(myVar "Value")            # 定义变量
message("myVar is ${myVar}") # 引用变量
```

- 缓存变量（Cache Variables，全局可见，支持从命令行修改）

保存在 `CMakeCache.txt` 中，全局可见，常用于配置项。可以在命令行中直接覆盖。

```cmake
# set(
#     varName
#     value
#     CACHE
#     type
#     "helpString"
#     [FORCE]
# )
set(MY_BUILD_TYPE "Release" CACHE STRING "Choose type of build")
```

类型：BOOL（ON/OFF）、FILEPATH、PATH、STRING、INTERNAL

FROCE 表示是否强制更新缓存（缓存已有的值在写入后不会更新，除非设置  FORCE）

对于 bool 类型的缓存变量可以使用 `option(optVar helpString [初始值])` 定义，初始值默认 OFF

- 环境变量（Environment Variables）

用于获取或设置系统级变量

```cmake
set(ENV{PATH} "/opt/my_toolchains:$ENV{PATH}") # 设置环境变量
message("PATH is $ENV{PATH}")       # 读取环境变量
```

### 变量定义

如果有多个值，相当于列表。以字符串存储，用 `;` 分隔

```bash
set(myVar "Hello" "World")
# myVar is Hello;World

set(myVar "Hello;World")  # 等价
set(myVar "Hello\;World") # 使用 ; 需要转义
```

空格使用双引号

```cmake
set(myVar "Hello World")
```

引用变量

```cmake
set(myVar "CAT")
set(PET "MY_${myVar}")
# myVar is MY_CAT
```

递归定义

```cmake
set(myVar "PET")
set(${myVar} "CAT")
message("${myVar} is ${${myVar}}") # 引用变量
# PET IS CAT

message("PET is ${PET}") # 等价
```

定义多行变量

```cmake
set(myMultiLine "PET:
  CAT
  DOG
")
```

方括号定义字符串，原始文本

```cmake
set(myMultiLine [[ PET:
  CAT
  DOG
  ${myVar}
]])

# ${myVar} 不是引用，是字符串的一部分
```

取消变量

```cmake
set(myVar "Hello")
unset(myVar)
```

### 变量命名

- 不要以 `CMAKE_` 开头定义自己的变量
- 缓存变量使用全大写加下划线，普通变量使用驼峰命名或小写加下划线

### 作用域规则

- 父目录中定义的普通变量会向下传递给子目录（通过 `add_subdirectory` 添加的模块）
- 子目录中对普通变量的修改不会反向影响父目录
- 若需在子目录修改父目录或全局变量，需使用 `CACHE` 或 `PARENT_SCOPE`

```cmake
set(myVar "cat")
block()
# block(SCOPE_FOR VARIABLES PROPAGATE myVar) # PROPAGATE 则不会创建引用，一直使用全局
    set(myVar "dog")
    # set(myVar "dog" PARENT_SCOPE) # 会影响全局的变量
    message("[block]myVar is ${myVar}") # dog
endblock()
message("[outer]myVar is ${myVar}") # cat
```

### 常见内置变量

CMake 预定义了大量变量，帮助开发者获取系统信息或控制构建行为：

- 路径变量
  - `PROJECT_SOURCE_DIR` / `CMAKE_SOURCE_DIR`：当前项目源码根目录
  - `PROJECT_BINARY_DIR` / `CMAKE_BINARY_DIR`：当前项目构建输出的根目录
- 构建控制变量
  - `CMAKE_BUILD_TYPE`：构建类型（如 `Debug`, `Release`, `RelWithDebInfo` 等）
  - `CMAKE_CXX_FLAGS`：全局 C++ 编译器标志
- 编译器变量
  - `CMAKE_CXX_COMPILER`：C++ 编译器路径（如 `g++`, `clang++`）

### 命令行参数

```bash
cmake -D "MY_VAR:STRING=hello world"
```

删除缓存中的变量

```bash
cmake -U "MY*" ./build
```

## 流程控制

### 条件判断

```cmake
if(expor)
  # ...
elseif(expr2)
  # ...
else()
  # ...
endif()
```

常量

- TREU 常量：`1`、`ON` 、`YES`、`TRUE`、`Y`、非零整值

- FALSE 常量：`0`、`OFF`、`NO`、`FALSE`、`N`、`IGNORE`、`NOTFOUND`、`*-NOTFOUND`、空字符串

运算法

- 逻辑运算符：`AND`、`OR`、`NOT`

- 比较运算符：

  - 数值：`LESS`、`GREATER`、`EQUAL`、`LESS_EQUAL`、`GTREATER_EQUAl`

  - 字符串：`STRLESS`、`STRGREATER`、`STREQUAL`、`STRLESS_EQUAL`、`STRGTREATER_EQUAl`、`MATCHES`（正则匹配）

  - 版本号：`VERSION_LESS`、`VERSION_GREATER`、`VERSION_EQUAL`、`VERSION_RLESS_EQUAL`、`VERSION_GTREATER_EQUAl`

  - 路径：`PATH_EQUAL`

正则匹配示例

```cmake
set(MY_VERSION "v1.2.3")
if(MY_VERSION MATCHES "v([0-9]+)\\.([0-9]+)")
    message("Major: ${CMAKE_MATCH_1}") # Output: Major: 1
    message("Minor: ${CMAKE_MATCH_2}") # Output: Minor: 2
endif()
```



## 函数和宏

## 生成器表达式

## 目标属性

目标属性 ( Target Properties ) 直接关联到最终生成的可执行文件、库文件等构建产物。

- `INCLUDE_DIRECTORIES`
- `COMPILE_DEFINITIONS`
- `COMPILE_OPTIONS`
- `LINK_LIBRARIES`
- `LINK_FLAGS`
- `STATIC_LIBRARY_OPTIONS`
- `STATIC_LIBRARY_FLAGS`

- `SOURCES`