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

- TREU 常量（不区分大小写）：`1`、`ON` 、`YES`、`TRUE`、`Y`、非零整值

- FALSE 常量（不区分大小写）：`0`、`OFF`、`NO`、`FALSE`、`N`、`IGNORE`、`NOTFOUND`、`*-NOTFOUND`、空字符串

```cmake
set(v "Hello")

# 按照变量判断
# 只要当它的值不是上述 FALSE 常量时为 true
# 未定义变量为 "" 所以是 FALZE
if(v)
    message("${v} is true")
else()
    message("${v} is false")
endif()
# Hello is true

# 按照字符串规则判断
# 不是 FALSE 常量时为 true
if($v)
    message("'${v}' is true")
else()
    message("'${v}' is false")
endif()
# 'Hello' is false
```

运算法

- 逻辑运算符：`AND`、`OR`、`NOT`

- 比较运算符：

  - 数值：`LESS`、`GREATER`、`EQUAL`、`LESS_EQUAL`、`GTREATER_EQUAL`

  - 字符串：`STRLESS`、`STRGREATER`、`STREQUAL`、`STRLESS_EQUAL`、`STRGTREATER_EQUAL`、`MATCHES`（正则匹配）

  - 版本号：`VERSION_LESS`、`VERSION_GREATER`、`VERSION_EQUAL`、`VERSION_RLESS_EQUAL`、`VERSION_GTREATER_EQUAl`

  - 路径：`PATH_EQUAL`
- 文件操作：`EXISTS`、`IS_READABLE`、`IS_WRITABLE`、`IS_EXECUTABLE`、`IS_NEWER_THAN`、`IS_DIRECTORY`、`IS_SYMLINK`、`IS_ABSOLUTE`
- 存在性测试：`COMMAND`、`POLICY`、`TARGET`、`TEST`、`DEFINED`、`IN_LIST`

正则匹配示例

```cmake
set(myVersion "v1.2.3")
if(myVersion MATCHES "v([0-9]+)\\.([0-9]+)")
    message("Major: ${CMAKE_MATCH_1}") # Output: Major: 1
    message("Minor: ${CMAKE_MATCH_2}") # Output: Minor: 2
endif()
```

路径示例

```cmake
# 按照路径判断
if("/path//to/myfile" PATH_EQUAL "/path/to/myfile")
    message("PATH_EQUAL is true")
else()
    message("PATH_EQUAL is false")
endif()
# PATH_EQUAL is true

# 按照字符串规则判断
if("/path//to/myfile" STREQUAL "/path/to/myfile")
    message("STREQUAL is true")
else()
    message("STREQUAL is false")
endif()
# STREQUAL is false
```

IN_LIST 示例

```cmake
set(list1 a b c d v)
set(list2 e f g)

set(v "f")

# unset(v)
# 如果 v 未定义, v 会被当成字符串
if(v IN_LIST list1)
    message("v is in list1")
elseif(v IN_LIST list2)
    message("v is in list2")
else()
    message("v is not in list1 or list2")
endif()
```

Cmake 预定义变量

```cmake
# 针对不同的系统添加不同的源文件或者库
if(UNIX)
    message("build with UNIX")
elseif(MSVC)
    message("build with MSVC")
elseif(MINGW)
    message("build with MINGW")
elseif(XCODE)
    message("build with XCODE")
else()
    message("build with other compiler")
endif()
```

使用 option 变量

```cmake
option(BUILD_MY_LIB "Build MyLib target")
if(BUILD_MY_LIB)
    add_library(MyLib my_lib.cpp)
else()
    message("Ignore MyLib target")
endif()
# cmake -D BUILD_MY_LIB=on
```

避免在源代码内构建和编译

```cmake
if(" ${CMAKE_SOURCE_DIR}" STREQUAL " ${CMAKE_BINARY_DIR}")
    message(FATAL_ERROR "In-source builds are forbidden")
endif()
```

### foreach  循环

语法

```cmake
foreach(<loop_var> <items>)
    <command>
endforeach()
```

示例

```cmake
foreach(v a b c)
    message("v: ${v}")
endforeach()

# IN LISTS
set(list1 1 3 5 7)
set(list2 2 4 6 8)
foreach(v IN LISTS list1 list2)
    message("v: ${v}")
endforeach()

# IN ITEMS
foreach(v IN ITEMS 1 2 3 4)
    message("v: ${v}")
endforeach()

# ZIP_LISTS
# 合并遍历两组列表
set(list1 1 3 5 7)
set(list2 2 4 6 8)
foreach(v IN ZIP_LISTS list1 list2)
    message("v: (${v_0},${v_1})")
endforeach()

# RANGE
# step 默认值是 1
set(start 1)
set(end 8)
set(step 2)
foreach(v RANGE ${start} ${end} ${step})
    message("v: ${v}")
endforeach()
```

### while 循环

语法

```cmake
while(<condition>)
    <command>
endwhile()
```

其他

```cmake
# 跳过下次循环
continue()

# 退出循环
break()
```

## 函数和宏

### 函数

语法

```cmake
function(function_name args...)
    # do something
endfunction()
```

传参方式

- 命名参数

```cmake
function(my_function a b)
    message("a:${a}, b:${b}")
endfunction()

my_function(hello world)
```

- 未命名参数

```cmake
function(my_function a b)
    message("a:${a}, b:${b}")
    # ARGC 参数数量
    # ARGV 参数列表
    #    ARGV0 ARGV1 ... ARGVn (n<ARGC)
    # ARGN 未命名参数列表
    message("argn:${ARGN}")
endfunction()

my_function(hello world 1 2 3
```

- 关键字参数

```cmake
function(my_function targetName)
    message("targetName:${targetName}")
    message("argv:${ARGV}")
    # argv:myTarget;USE_MY_LIB;MY_LIB_PATH;/usr/local/lib;SOURCES;main.cpp;INCLUDES;include;other_include
endfunction()

my_function(myTarget
    # option 关键字
    USE_MY_LIB
    # 单值关键字
    MY_LIB_PATH "/usr/local/lib"
    SOURCES "main.cpp"
    # 多值关键字
    INCLUDES "include" "other_include"
)
# 多出来的实参都是未命名参数
```

`cmake_parse_arguments` 为解析函数（function）或 宏（macros） 参数的命令；

```cmake
cmake_parse_arguments(<prefix> <options>
                      <one_value_keywords> <multi_value_keywords> <args>...)

cmake_parse_arguments(PARSE_ARGV <N> <prefix> <options>
                      <one_value_keywords> <multi_value_keywords>)
```

1. **`<prefix>`**前缀, 解析出的参数都会按照 `prefix_参数名` 的形式形成新的变量;
2. **`<options>`**: 可选值
   - 此处包含可选项的变量名称, 对应的值为 `TRUE` 或 `FALSE`;
   - 如果传递进来的参数包含此变量, 则为 `TRUE` 反之为 `FALSE`
3. **`<one_value_keywords>`**: 单值关键词列表
   - 每个关键词仅仅对应一个值
4. **`<multi_value_keywords>`**: 多值关键词列表
   - 每个关键词可对应多个值
5. **`<args>...`** 参数, 一般传入 `${ARGN}` 即可

示例

```cmake
function ( my_install )
    set ( options OPTIONAL FAST )
    set ( oneValueArgs DESTINATION RENAME )
    set ( multiValueArgs TARGETS CONFIGURATIONS )
    cmake_parse_arguments( MY_INSTALL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    message( STATUS "MY_INSTALL_OPTIONAL = ${MY_INSTALL_OPTIONAL}" )
    message( STATUS "MY_INSTALL_FAST = ${MY_INSTALL_FAST}" )
    message( STATUS "MY_INSTALL_DESTINATION = ${MY_INSTALL_DESTINATION}" )
    message( STATUS "MY_INSTALL_RENAME = ${MY_INSTALL_RENAME}" )
    message( STATUS "MY_INSTALL_TARGETS = ${MY_INSTALL_TARGETS}" )
    message( STATUS "MY_INSTALL_CONFIGURATIONS = ${MY_INSTALL_CONFIGURATIONS}" )
    message( STATUS "MY_INSTALL_UNPARSED_ARGUMENTS = ${MY_INSTALL_UNPARSED_ARGUMENTS}" )
    message( STATUS "MY_INSTALL_KEYWORDS_MISSING_VALUES = ${MY_INSTALL_KEYWORDS_MISSING_VALUES}" )
endfunction()

my_install(TARGETS foo bar DESTINATION bin OPTIONAL blub)
```

`<prefix>_UNPARSED_ARGUMENTS`: 表示未被使用的参数变量（ `${ARGN}` 里面）

`<prefix>_KEYWORDS_MISSING_VALUES`：定义了关键词，但是没有对应的值

### 返回值

通过传参的方式接受返回值

```cmake
function(my_function returnValue)
    set(${returnValue} "hello world" PARENT_SCOPE)
endfunction()

my_function(result)
message("result:${result}")
```

使用 return 命令

```cmake
function(my_function returnValue)
    set(${returnValue} "hello world")
    return(PROPAGATE ${returnValue})
endfunction()

my_function(result)
message("result:${result}")
```

### 宏

函数有自己的栈，而宏则相当于将代码直接插入，宏的参数会被替换成字符串

宏中尽量避免使用 return 造成混淆

```cmake
macro(myMacro args...)
    # command
endmacro()
```

示例

```cmake
function(my_function a)
    if(a)
        message("a is true")
    else()
        message("a is false")
    endif()
endfunction()

macro(my_macro a)
    if(a)
        message("a is true")
    else()
        message("a is false")
    endif()
endmacro()

# 函数中参数做为变量来判断
my_function(hello) # true

# 宏中参数做为字符串来判断
my_macro(hello)# false
```

## 其他

### List 命令

```cmake
list(操作关键字 <listVar> <其他参数> ...)
```

### 生成器表达式

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

## 其他参考资料

- <https://www.cnblogs.com/gaox97329498/p/10952732.html>